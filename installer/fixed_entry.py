from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path
from typing import Sequence

from . import entry, runtime

THEMES_REPO = "https://github.com/grapes7000/themes.git"


def theme_dir(ctx: runtime.Context) -> Path:
    return ctx.config / "hypr/themes"


def active_theme_file(ctx: runtime.Context) -> Path:
    return ctx.config / "hypr/generated/.active"


def theme_installed(ctx: runtime.Context) -> bool:
    return (ctx.home / ".local/bin/theme").is_file()


def theme_available(ctx: runtime.Context) -> bool:
    return (theme_dir(ctx) / f"{ctx.options.theme}.json").is_file()


def active_theme(ctx: runtime.Context) -> str | None:
    try:
        return active_theme_file(ctx).read_text(encoding="utf-8").strip() or None
    except OSError:
        return None


def theme_check(ctx: runtime.Context) -> bool:
    return theme_installed(ctx) and theme_available(ctx) and active_theme(ctx) == ctx.options.theme


def install_or_refresh_themes(ctx: runtime.Context) -> None:
    if not ctx.has("git"):
        raise runtime.InstallError("git is required to install the standalone themes repository")

    ctx.emit("  installing/updating standalone themes from grapes7000/themes main")
    if ctx.options.dry_run:
        ctx.emit("  $ git clone --depth 1 https://github.com/grapes7000/themes.git <temporary>/themes")
        ctx.emit("  $ bash <temporary>/themes/install.sh --targets full")
        return

    with tempfile.TemporaryDirectory(prefix="arch-wm-themes-") as temporary:
        checkout = Path(temporary) / "themes"
        ctx.run(["git", "clone", "--depth", "1", THEMES_REPO, str(checkout)])
        ctx.run(["bash", str(checkout / "install.sh"), "--targets", "full"])


def theme_apply(ctx: runtime.Context) -> None:
    theme_cmd = ctx.home / ".local/bin/theme"

    # Arch-WM is the user-facing desktop installer. Keep the themes repository
    # separate internally, but fetch/install it automatically when needed.
    if not theme_installed(ctx) or not theme_available(ctx):
        install_or_refresh_themes(ctx)

    if not ctx.options.dry_run and not theme_cmd.is_file():
        raise runtime.InstallError("standalone theme installer completed but ~/.local/bin/theme is missing")
    if not ctx.options.dry_run and not theme_available(ctx):
        raise runtime.InstallError(
            f"standalone theme installer completed but theme {ctx.options.theme!r} is missing from ~/.config/hypr/themes"
        )

    ctx.emit(f"  applying standalone theme: {ctx.options.theme}")
    ctx.run([str(theme_cmd), ctx.options.theme])


def theme_verify(ctx: runtime.Context) -> bool:
    if ctx.options.dry_run:
        return True
    ok = theme_installed(ctx) and theme_available(ctx) and active_theme(ctx) == ctx.options.theme
    if not ok:
        ctx.emit(
            "  theme verification failed: expected standalone themes paths "
            "(~/.config/hypr/themes and ~/.config/hypr/generated/.active)"
        )
    return ok


def doctor_command(ctx: runtime.Context) -> int:
    count = len(list(theme_dir(ctx).glob("*.json")))
    checks: dict[str, bool] = {
        "Arch Linux": Path("/etc/arch-release").exists(),
        "Hyprland": ctx.has("Hyprland"),
        "Quickshell": ctx.has("qs"),
        "standalone theme engine": theme_installed(ctx),
        "theme catalog": count > 0,
        "active theme": active_theme(ctx) is not None,
        "arch-wm help payload": (
            (ctx.config / "arch-wm/help.txt").is_file()
            and (ctx.home / ".local/bin/arch-wm-help").is_file()
        ),
        "Hyprland payload current": entry.hypr_check(ctx),
        "Hyprland theme": (
            (ctx.config / "hypr/generated/theme.lua").is_file()
            or (ctx.config / "hypr/generated/theme.conf").is_file()
        ),
        "shell payload current": entry.shell_check(ctx),
        "ReGreet login": runtime.login_check(ctx),
    }
    if ctx.profile.get("dotfiles"):
        checks["Chezmoi source"] = ctx.has("chezmoi") and (ctx.data / "chezmoi").is_dir()

    width = max(map(len, checks))
    for label, passed in checks.items():
        suffix = f" ({count} themes)" if label == "theme catalog" else ""
        ctx.emit(f"{label:<{width}}  {'OK' if passed else 'MISSING'}{suffix}")
    return 0 if all(checks.values()) else 1


def patch_theme_stage() -> None:
    patched: list[runtime.Stage] = []
    for stage in runtime.STAGES:
        if stage.name == "40-theme-engine":
            patched.append(runtime.Stage(stage.name, theme_check, theme_apply, theme_verify))
        else:
            patched.append(stage)
    runtime.STAGES = tuple(patched)
    runtime.theme_check = theme_check
    runtime.theme_apply = theme_apply
    runtime.theme_verify = theme_verify
    runtime.doctor_command = doctor_command


def main(argv: Sequence[str] | None = None) -> int:
    entry.patch_runtime()
    patch_theme_stage()
    return runtime.main(argv)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
