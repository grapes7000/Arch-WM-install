from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Sequence

from . import runtime
from .help import HELP_LAUNCHER, help_command, render_reference


def payload_version_matches(source: Path, installed: Path) -> bool:
    try:
        return source.read_text(encoding="utf-8").strip() == installed.read_text(
            encoding="utf-8"
        ).strip()
    except OSError:
        return False


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


def shell_payload_matches(ctx: runtime.Context) -> bool:
    """Return whether the installed Quickshell payload matches this checkout."""
    source = ctx.root / "modules/shell"
    target = ctx.config / "quickshell/arch-wm"
    if not target.is_dir():
        return False

    source_relatives: set[Path] = set()
    for src_file in source.rglob("*"):
        if src_file.is_dir():
            continue
        relative = src_file.relative_to(source)
        source_relatives.add(relative)
        dst_file = target / relative
        try:
            if src_file.read_bytes() != dst_file.read_bytes():
                return False
        except OSError:
            return False

    for dst_file in target.rglob("*"):
        if dst_file.is_dir():
            continue
        if dst_file.relative_to(target) not in source_relatives:
            return False
    return True


def shell_check(ctx: runtime.Context) -> bool:
    return (
        (ctx.config / "quickshell/arch-wm/.arch-wm-managed").is_file()
        and (ctx.config / "quickshell/arch-wm/shell.qml").is_file()
        and shell_payload_matches(ctx)
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
    ) and shell_payload_matches(ctx)


def session_check(ctx: runtime.Context) -> bool:
    return runtime.session_check(ctx) and all(
        path.is_file()
        for path in (
            ctx.config / "arch-wm/help.txt",
            ctx.home / ".local/bin/arch-wm-help",
        )
    )


def session_apply(ctx: runtime.Context) -> None:
    """Install session integration plus Arch-WM-specific help payloads."""
    runtime.session_apply(ctx)
    ctx.write(ctx.config / "arch-wm/help.txt", render_reference(ctx))
    ctx.write(ctx.home / ".local/bin/arch-wm-help", HELP_LAUNCHER, mode=0o755)


def session_verify(ctx: runtime.Context) -> bool:
    if ctx.options.dry_run:
        return True
    return runtime.session_verify(ctx) and all(
        path.is_file()
        for path in (
            ctx.config / "arch-wm/help.txt",
            ctx.home / ".local/bin/arch-wm-help",
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
    checks: dict[str, bool] = {
        "Arch Linux": Path("/etc/arch-release").exists(),
        "Hyprland": ctx.has("Hyprland"),
        "Quickshell": ctx.has("qs"),
        "standalone theme engine": (ctx.home / ".local/bin/theme").is_file(),
        "full theme catalog": theme_count >= 40,
        "arch-wm help payload": (
            (ctx.config / "arch-wm/help.txt").is_file()
            and (ctx.home / ".local/bin/arch-wm-help").is_file()
        ),
        "Hyprland payload current": hypr_check(ctx),
        "Hyprland theme": (ctx.config / "hypr/generated/theme.lua").is_file(),
        "shell payload current": shell_check(ctx),
        "theme contract": (ctx.config / "theme-engine/generated/theme.json").is_file(),
    }
    if ctx.profile.get("dotfiles"):
        checks["Chezmoi source"] = ctx.has("chezmoi") and (ctx.data / "chezmoi").is_dir()

    width = max(map(len, checks))
    for label, passed in checks.items():
        suffix = f" ({theme_count} themes)" if label == "full theme catalog" else ""
        ctx.emit(f"{label:<{width}}  {'OK' if passed else 'MISSING'}{suffix}")
    return 0 if all(checks.values()) else 1


def patch_runtime() -> None:
    """Keep only Arch-WM-specific runtime enhancements.

    Theme and portable terminal ownership intentionally stay in runtime.py so
    the standalone themes repo and Chezmoi remain the canonical shared layers.
    """
    patched = []
    for stage in runtime.STAGES:
        if stage.name == "50-hyprland":
            patched.append(runtime.Stage(stage.name, hypr_check, runtime.hypr_apply, hypr_verify))
        elif stage.name == "60-quickshell":
            patched.append(runtime.Stage(stage.name, shell_check, runtime.shell_apply, shell_verify))
        elif stage.name == "80-session":
            patched.append(runtime.Stage(stage.name, session_check, session_apply, session_verify))
        elif stage.name == "90-validate":
            patched.append(runtime.Stage(stage.name, stage.check, validate_apply, stage.verify))
        else:
            patched.append(stage)
    runtime.STAGES = tuple(patched)
    runtime.doctor_command = doctor_command
    runtime.help_command = help_command


def main(argv: Sequence[str] | None = None) -> int:
    patch_runtime()
    return runtime.main(argv)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
