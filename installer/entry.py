from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Sequence

from . import runtime


def repositories_apply(ctx: runtime.Context) -> None:
    if not ctx.options.dry_run:
        assert ctx.state is not None
        ctx.state.note(
            "Built-in modules are the runtime source. Run scripts/sync-upstreams.sh "
            "in a development checkout to refresh imported upstream snapshots."
        )
    ctx.emit("  built-in modules selected; upstream sync is a maintainer operation")


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


def theme_verify(ctx: runtime.Context) -> bool:
    if ctx.options.dry_run:
        return True
    try:
        current = runtime.json_file(ctx.config / "theme-engine/generated/theme.json")
    except (OSError, json.JSONDecodeError):
        return False
    return current.get("name") == ctx.options.theme and all(
        path.is_file()
        for path in (
            ctx.config / "hypr/generated/theme.lua",
            ctx.config / "kitty/generated/theme.conf",
            ctx.config / "theme-engine/generated/starship.toml",
        )
    )


def doctor_command(ctx: runtime.Context) -> int:
    checks = {
        "Arch Linux": Path("/etc/arch-release").exists(),
        "Hyprland": ctx.has("Hyprland"),
        "Quickshell": ctx.has("qs"),
        "theme": (ctx.home / ".local/bin/theme").is_file(),
        "terminal profile": (ctx.config / "kitty/kitty.conf").is_file(),
        "Hyprland Lua config": (ctx.config / "hypr/hyprland.lua").is_file(),
        "Hyprland theme": (ctx.config / "hypr/generated/theme.lua").is_file(),
        "shell config": (ctx.config / "quickshell/arch-wm/shell.qml").is_file(),
        "theme contract": (ctx.config / "theme-engine/generated/theme.json").is_file(),
    }
    width = max(map(len, checks))
    for label, passed in checks.items():
        ctx.emit(f"{label:<{width}}  {'OK' if passed else 'MISSING'}")
    return 0 if all(checks.values()) else 1


def patch_runtime() -> None:
    replacements = {
        "10-repositories": (repositories_apply, runtime.repositories_verify),
        "40-theme-engine": (runtime.theme_apply, theme_verify),
        "50-hyprland": (runtime.hypr_apply, hypr_verify),
    }
    patched = []
    for stage in runtime.STAGES:
        if stage.name == "10-repositories":
            patched.append(runtime.Stage(stage.name, stage.check, repositories_apply, runtime.repositories_verify))
        elif stage.name == "40-theme-engine":
            patched.append(runtime.Stage(stage.name, stage.check, runtime.theme_apply, theme_verify))
        elif stage.name == "50-hyprland":
            patched.append(runtime.Stage(stage.name, hypr_check, runtime.hypr_apply, hypr_verify))
        else:
            patched.append(stage)
    runtime.STAGES = tuple(patched)
    runtime.doctor_command = doctor_command


def main(argv: Sequence[str] | None = None) -> int:
    patch_runtime()
    return runtime.main(argv)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
