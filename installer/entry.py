from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Sequence

from . import runtime

THEME_UPSTREAM_COMMIT = "3c6edb333406efce1920d762b7ed67b4168d4024"
THEME_COMMANDS = (
    "theme",
    "theme-catalog-sync",
    "theme-install",
    "theme-new",
    "theme-menu",
    "wallgen",
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


def theme_catalog_valid(ctx: runtime.Context) -> bool:
    theme_dir = ctx.config / "theme-engine/themes"
    lock_path = ctx.config / "theme-engine/upstream-lock.json"
    if len(list(theme_dir.glob("*.json"))) < 36 or not lock_path.is_file():
        return False
    try:
        lock = runtime.json_file(lock_path)
    except (OSError, json.JSONDecodeError):
        return False
    return lock.get("commit") == THEME_UPSTREAM_COMMIT and int(lock.get("theme_count", 0)) >= 36


def theme_check(ctx: runtime.Context) -> bool:
    return theme_catalog_valid(ctx) and all(
        path.is_file()
        for path in (
            *(ctx.home / ".local/bin" / name for name in THEME_COMMANDS),
            ctx.home / ".local/bin/term",
            ctx.home / ".zshrc",
            ctx.config / "zsh/aliases.zsh",
            ctx.config / "kitty/kitty.conf",
            ctx.config / "atuin/config.toml",
            ctx.config / "theme-engine/generated/theme.json",
        )
    )


def theme_apply(ctx: runtime.Context) -> None:
    assert ctx.state is not None
    theme = ctx.root / "modules/theme-engine"
    terminal = ctx.root / "modules/terminal"
    for name in THEME_COMMANDS:
        ctx.install(theme / "bin" / name, ctx.home / ".local/bin" / name, executable=True)
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
    # Hyprland and wallpaper files are written. Existing managed installs can
    # safely receive the full live theme during a stage-40 refresh.
    skip_hypr = not (ctx.config / "hypr/.arch-wm-managed").is_file()
    previous = os.environ.get("ARCH_WM_THEME_SKIP_HYPR")
    try:
        if skip_hypr:
            os.environ["ARCH_WM_THEME_SKIP_HYPR"] = "1"
        ctx.run([str(ctx.home / ".local/bin/theme"), ctx.options.theme])
    finally:
        if previous is None:
            os.environ.pop("ARCH_WM_THEME_SKIP_HYPR", None)
        else:
            os.environ["ARCH_WM_THEME_SKIP_HYPR"] = previous


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
    return (ctx.config / "hypr/.arch-wm-managed").is_file() and (
        ctx.config / "hypr/hyprland.lua"
    ).is_file()


def hypr_verify(ctx: runtime.Context) -> bool:
    return ctx.options.dry_run or all(
        path.is_file()
        for path in (
            ctx.config / "hypr/hyprland.lua",
            ctx.config / "hypr/conf/autostart.lua",
            ctx.config / "hypr/generated/theme.lua",
            ctx.config / "hypr/.arch-wm-managed",
        )
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
        "full theme catalog": theme_count >= 36 and theme_catalog_valid(ctx),
        "terminal profile": (ctx.config / "kitty/kitty.conf").is_file(),
        "Hyprland Lua config": (ctx.config / "hypr/hyprland.lua").is_file(),
        "Hyprland theme": (ctx.config / "hypr/generated/theme.lua").is_file(),
        "shell config": (ctx.config / "quickshell/arch-wm/shell.qml").is_file(),
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
