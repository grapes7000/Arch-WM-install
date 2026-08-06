from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Sequence

from . import runtime

THEME_UPSTREAM_COMMIT = "c609410fbd88ddc2a15c51ab142743c49ae861e0"
THEME_COMMANDS = (
    "theme",
    "theme-legacy",
    "theme-studio",
    "theme-catalog-sync",
    "theme-install",
    "theme-new",
    "theme-menu",
    "wallgen",
)

# Theme Studio is composed of the entrypoint plus sibling Python modules. Keep
# these installed beside the command so its imports work from ~/.local/bin.
THEME_STUDIO_MODULES = (
    "theme_runtime.py",
    "theme_editor.py",
    "theme_effects.py",
    "theme_starship.py",
    "theme_homepage.py",
    "theme_schema.py",
    "theme_components.py",
    "theme_preview.py",
    "theme_tui.py",
    "theme_tui_widgets.py",
)


def repositories_apply(ctx: runtime.Context) -> None:
    if not ctx.options.dry_run:
        assert ctx.state is not None
        ctx.state.note(
            "Built-in modules are the runtime source. Run scripts/sync-upstreams.sh "
            "in a development checkout to refresh imported upstream snapshots."
        )
    ctx.emit("  built-in modules selected; upstream sync is a maintainer operation")


def own_for_write(ctx: runtime.Context, path: Path) -> None:
    assert ctx.state is not None
    if path.exists() or path.is_symlink():
        ctx.emit(f"  backup {path}")
        ctx.state.backup_target(path, dry_run=ctx.options.dry_run)
    elif not ctx.options.dry_run:
        ctx.state.record_created_path(path)


def atomic_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    except Exception:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def payload_version_matches(source: Path, installed: Path) -> bool:
    try:
        return source.read_text(encoding="utf-8").strip() == installed.read_text(encoding="utf-8").strip()
    except OSError:
        return False


def theme_catalog_valid(ctx: runtime.Context) -> bool:
    theme_dir = ctx.config / "theme-engine/themes"
    lock_path = ctx.config / "theme-engine/upstream-lock.json"
    if len(list(theme_dir.glob("*.json"))) < 40 or not lock_path.is_file():
        return False
    try:
        lock = runtime.json_file(lock_path)
    except (OSError, json.JSONDecodeError):
        return False
    return lock.get("commit") == THEME_UPSTREAM_COMMIT and int(lock.get("theme_count", 0)) >= 40


def theme_check(ctx: runtime.Context) -> bool:
    required_paths = (
        *(ctx.home / ".local/bin" / name for name in THEME_COMMANDS),
        *(ctx.home / ".local/bin" / name for name in THEME_STUDIO_MODULES),
        ctx.home / ".local/bin/term",
        ctx.home / ".zshrc",
        ctx.config / "zsh/aliases.zsh",
        ctx.config / "kitty/kitty.conf",
        ctx.config / "atuin/config.toml",
        ctx.config / "theme-engine/generated/theme.json",
    )
    if not theme_catalog_valid(ctx) or not all(path.is_file() for path in required_paths):
        return False

    # File presence alone is not enough: older installs contain a legacy
    # `theme` dispatcher that opens theme-menu instead of Theme Studio. Compare
    # the installed entrypoints/modules with the current source payload so a
    # rerun upgrades an existing installation instead of incorrectly no-oping.
    source_root = ctx.root / "modules/theme-engine/bin"
    installed_root = ctx.home / ".local/bin"
    payloads = {
        "theme": "theme-studio",
        "theme-legacy": "theme",
        **{name: name for name in THEME_STUDIO_MODULES},
    }
    return all(
        payload_version_matches(source_root / source_name, installed_root / target_name)
        for target_name, source_name in payloads.items()
    )


def theme_apply(ctx: runtime.Context) -> None:
    assert ctx.state is not None
    theme = ctx.root / "modules/theme-engine"
    terminal = ctx.root / "modules/terminal"
    # Keep the stable Arch-WM generator behind Theme Studio. Theme Studio
    # delegates named-theme application and legacy commands to this binary.
    ctx.install(theme / "bin/theme", ctx.home / ".local/bin/theme-legacy", executable=True)
    ctx.install(theme / "bin/theme-studio", ctx.home / ".local/bin/theme", executable=True)
    for name in THEME_COMMANDS:
        if name in {"theme", "theme-legacy", "theme-studio"}:
            continue
        ctx.install(theme / "bin" / name, ctx.home / ".local/bin" / name, executable=True)
    for name in THEME_STUDIO_MODULES:
        ctx.install(theme / "bin" / name, ctx.home / ".local/bin" / name)
    ctx.install(terminal / "bin/term", ctx.home / ".local/bin/term", executable=True)

    theme_target = ctx.config / "theme-engine/themes"
    if theme_target.exists():
        # Back up the whole current catalog but do not replace it with the seed
        # directory; theme-catalog-sync merges the pinned set and preserves custom files.
        own_for_write(ctx, theme_target)
    else:
        ctx.install(theme / "themes", theme_target)
    ctx.install(theme / "schema", ctx.config / "theme-engine/schema")
    ctx.install(terminal / "kitty/kitty.conf", ctx.config / "kitty/kitty.conf")
    ctx.install(terminal / "zsh/.zshrc", ctx.home / ".zshrc")
    ctx.install(terminal / "zsh/aliases.zsh", ctx.config / "zsh/aliases.zsh")
    ctx.install(terminal / "atuin/config.toml", ctx.config / "atuin/config.toml")

    for path in (
        ctx.config / "theme-engine/upstream-lock.json",
        ctx.config / "theme-engine/targets.conf",
        ctx.config / "theme-engine/generated/theme.json",
        ctx.config / "theme-engine/generated/.active",
        ctx.config / "theme-engine/generated/starship.toml",
        ctx.config / "kitty/generated/theme.conf",
        ctx.config / "nvim/lua/generated_theme.lua",
    ):
        own_for_write(ctx, path)

    ctx.run([str(ctx.home / ".local/bin/theme-install"), "--noninteractive"])

    # On a fresh install, stage 50 must own ~/.config/hypr before generated
    # Hyprland and wallpaper files are written. Temporarily suppress only those
    # targets; the exact original targets file is restored even when apply fails.
    skip_hypr = not (ctx.config / "hypr/.arch-wm-managed").is_file()
    targets_path = ctx.config / "theme-engine/targets.conf"
    original_targets: str | None = None
    if skip_hypr and not ctx.options.dry_run and targets_path.is_file():
        original_targets = targets_path.read_text(encoding="utf-8")
        filtered: list[str] = []
        for raw in original_targets.splitlines():
            value = raw.split("#", 1)[0].strip().split("=", 1)[0].strip()
            if value in {"hypr", "wallpaper", "hyprlock"}:
                continue
            filtered.append(raw)
        atomic_text(targets_path, "\n".join(filtered) + "\n")
    try:
        ctx.run([str(ctx.home / ".local/bin/theme"), ctx.options.theme])
    finally:
        if original_targets is not None:
            atomic_text(targets_path, original_targets)


def theme_verify(ctx: runtime.Context) -> bool:
    if ctx.options.dry_run:
        return True
    try:
        current = runtime.json_file(ctx.config / "theme-engine/generated/theme.json")
    except (OSError, json.JSONDecodeError):
        return False
    return (
        current.get("name") == ctx.options.theme
        and theme_catalog_valid(ctx)
        and all(
            path.is_file()
            for path in (
                ctx.config / "kitty/generated/theme.conf",
                ctx.config / "theme-engine/generated/starship.toml",
            )
        )
    )


def hypr_check(ctx: runtime.Context) -> bool:
    source_version = ctx.root / "modules/hyprland/config/.arch-wm-version"
    installed_version = ctx.config / "hypr/.arch-wm-version"
    return (
        (ctx.config / "hypr/.arch-wm-managed").is_file()
        and (ctx.config / "hypr/hyprland.lua").is_file()
        and payload_version_matches(source_version, installed_version)
    )


def hypr_verify(ctx: runtime.Context) -> bool:
    if ctx.options.dry_run:
        return True
    return all(
        path.is_file()
        for path in (
            ctx.config / "hypr/hyprland.lua",
            ctx.config / "hypr/conf/autostart.lua",
            ctx.config / "hypr/generated/theme.lua",
            ctx.config / "hypr/.arch-wm-managed",
            ctx.config / "hypr/.arch-wm-version",
        )
    ) and payload_version_matches(
        ctx.root / "modules/hyprland/config/.arch-wm-version",
        ctx.config / "hypr/.arch-wm-version",
    )


def shell_check(ctx: runtime.Context) -> bool:
    source_version = ctx.root / "modules/shell/.arch-wm-version"
    installed_version = ctx.config / "quickshell/arch-wm/.arch-wm-version"
    return (
        (ctx.config / "quickshell/arch-wm/.arch-wm-managed").is_file()
        and (ctx.config / "quickshell/arch-wm/shell.qml").is_file()
        and payload_version_matches(source_version, installed_version)
    )


def shell_verify(ctx: runtime.Context) -> bool:
    if ctx.options.dry_run:
        return True
    return all(
        path.is_file()
        for path in (
            ctx.config / "quickshell/arch-wm/shell.qml",
            ctx.config / "quickshell/arch-wm/core/Theme.qml",
            ctx.config / "quickshell/arch-wm/surfaces/bar/BarSurface.qml",
            ctx.config / "quickshell/arch-wm/.arch-wm-managed",
            ctx.config / "quickshell/arch-wm/.arch-wm-version",
        )
    ) and payload_version_matches(
        ctx.root / "modules/shell/.arch-wm-version",
        ctx.config / "quickshell/arch-wm/.arch-wm-version",
    )


def validate_apply(ctx: runtime.Context) -> None:
    ctx.run([sys.executable, str(ctx.root / "scripts/validate-layouts.py")])
    ctx.run(
        [sys.executable, "-m", "unittest", "discover", "-s", str(ctx.root / "tests")]
    )
    ctx.run(["bash", str(ctx.root / "scripts/check-legacy-widget-free.sh")])
    if ctx.has("hyprctl") and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        result = ctx.run(["hyprctl", "configerrors"], capture=True)
        if result.stdout.strip():
            raise runtime.InstallError("Hyprland config errors:\n" + result.stdout.strip())


def doctor_command(ctx: runtime.Context) -> int:
    theme_count = len(list((ctx.config / "theme-engine/themes").glob("*.json")))
    checks = {
        "Arch Linux": Path("/etc/arch-release").exists(),
        "Hyprland": ctx.has("Hyprland"),
        "Quickshell": ctx.has("qs"),
        "theme": (ctx.home / ".local/bin/theme").is_file(),
        "full theme catalog": theme_count >= 40 and theme_catalog_valid(ctx),
        "terminal profile": (ctx.config / "kitty/kitty.conf").is_file(),
        "Hyprland payload current": hypr_check(ctx),
        "Hyprland theme": (ctx.config / "hypr/generated/theme.lua").is_file(),
        "shell payload current": shell_check(ctx),
        "theme contract": (ctx.config / "theme-engine/generated/theme.json").is_file(),
    }
    width = max(map(len, checks))
    for label, passed in checks.items():
        suffix = f" ({theme_count} themes)" if label == "full theme catalog" else ""
        ctx.emit(f"{label:<{width}}  {'OK' if passed else 'MISSING'}{suffix}")
    return 0 if all(checks.values()) else 1


def patch_runtime() -> None:
    patched = []
    for stage in runtime.STAGES:
        if stage.name == "10-repositories":
            patched.append(
                runtime.Stage(
                    stage.name,
                    stage.check,
                    repositories_apply,
                    runtime.repositories_verify,
                )
            )
        elif stage.name == "40-theme-engine":
            patched.append(runtime.Stage(stage.name, theme_check, theme_apply, theme_verify))
        elif stage.name == "50-hyprland":
            patched.append(runtime.Stage(stage.name, hypr_check, runtime.hypr_apply, hypr_verify))
        elif stage.name == "60-quickshell":
            patched.append(runtime.Stage(stage.name, shell_check, runtime.shell_apply, shell_verify))
        elif stage.name == "90-validate":
            patched.append(runtime.Stage(stage.name, stage.check, validate_apply, stage.verify))
        else:
            patched.append(stage)
    runtime.STAGES = tuple(patched)
    runtime.doctor_command = doctor_command


def main(argv: Sequence[str] | None = None) -> int:
    patch_runtime()
    return runtime.main(argv)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
