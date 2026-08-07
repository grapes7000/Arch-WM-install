from __future__ import annotations

import argparse
import json
import os
import platform
import shlex
import shutil
import socket
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable, Sequence

from .state import StateStore, remove_path


STAGE_ORDER = (
    "00-preflight",
    "10-repositories",
    "20-packages",
    "30-user-directories",
    "40-theme-engine",
    "50-hyprland",
    "60-quickshell",
    "70-services",
    "80-session",
    "90-validate",
)


class InstallError(RuntimeError):
    pass


def now_id() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def json_file(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def manifest(path: Path) -> list[str]:
    values: list[str] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        value = raw.split("#", 1)[0].strip()
        if value and value not in values:
            values.append(value)
    return values


@dataclass(frozen=True)
class Options:
    command: str
    profile: str = "desktop"
    theme: str = "y2k"
    dry_run: bool = False
    noninteractive: bool = False
    no_aur: bool = False
    resume: bool = False
    from_stage: str | None = None
    only_stage: str | None = None
    verbose: bool = False
    remove_packages: bool = False


class Context:
    def __init__(self, root: Path, options: Options) -> None:
        self.root = root
        self.options = options
        self.home = Path.home()
        self.config = Path(os.environ.get("XDG_CONFIG_HOME", self.home / ".config"))
        self.data = Path(os.environ.get("XDG_DATA_HOME", self.home / ".local/share"))
        self.state_home = Path(os.environ.get("XDG_STATE_HOME", self.home / ".local/state"))
        self.state_root = self.state_home / "arch-wm-install"
        self.backup_root = self.data / "arch-wm-install/backups"
        self.run_id = self._run_id()
        self.profile = json_file(root / "installer/profiles" / f"{options.profile}.json")
        self.state: StateStore | None = None
        if options.command == "install":
            self.state = StateStore(self.state_root, self.backup_root, self.run_id)
            if options.dry_run:
                self.state.data["profile"] = options.profile
                self.state.data["theme"] = options.theme
            else:
                self.state.set_metadata(profile=options.profile, theme=options.theme)
        self.log = self.state_root / "logs" / f"{self.run_id}.log"

    def _run_id(self) -> str:
        if self.options.command == "install" and self.options.resume:
            active = self.state_root / "active.json"
            if not active.exists():
                raise InstallError("--resume requested but no active installer state exists")
            return str(json_file(active)["run_id"])
        return now_id()

    def emit(self, text: str = "") -> None:
        print(text)
        if self.options.dry_run:
            return
        self.log.parent.mkdir(parents=True, exist_ok=True)
        with self.log.open("a", encoding="utf-8") as handle:
            handle.write(text + "\n")

    def run(
        self,
        command: Sequence[str],
        *,
        sudo: bool = False,
        check: bool = True,
        capture: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        argv = [str(value) for value in command]
        if sudo:
            argv.insert(0, "sudo")
        self.emit("  $ " + " ".join(shlex.quote(value) for value in argv))
        if self.options.dry_run:
            return subprocess.CompletedProcess(argv, 0, "", "")
        result = subprocess.run(argv, text=True, capture_output=capture, check=False)
        if capture and self.options.verbose:
            if result.stdout:
                self.emit(result.stdout.rstrip())
            if result.stderr:
                self.emit(result.stderr.rstrip())
        if check and result.returncode:
            detail = result.stderr.strip() if result.stderr else ""
            raise InstallError(
                f"command failed ({result.returncode}): {' '.join(argv)}"
                + (f"\n{detail}" if detail else "")
            )
        return result

    def has(self, command: str) -> bool:
        return shutil.which(command) is not None

    def package_installed(self, package: str) -> bool:
        if not self.has("pacman"):
            return False
        return subprocess.run(
            ["pacman", "-Q", package],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        ).returncode == 0

    def service_enabled(self, service: str) -> bool:
        return subprocess.run(
            ["systemctl", "is-enabled", "--quiet", service],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        ).returncode == 0

    def _own(self, target: Path) -> None:
        assert self.state is not None
        if target.exists() or target.is_symlink():
            self.emit(f"  backup {target}")
            self.state.backup_target(target, dry_run=self.options.dry_run)
        elif not self.options.dry_run:
            self.state.record_created_path(target)

    def install(self, source: Path, target: Path, *, executable: bool = False) -> None:
        source = source.resolve()
        if not source.exists():
            raise InstallError(f"installation source is missing: {source}")
        if source.is_file() and target.is_file():
            try:
                if source.read_bytes() == target.read_bytes():
                    self.emit(f"  unchanged {target}")
                    if executable and not self.options.dry_run:
                        target.chmod(0o755)
                    return
            except OSError:
                pass
        self._own(target)
        self.emit(f"  install {source} -> {target}")
        if self.options.dry_run:
            return
        remove_path(target)
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.is_dir():
            shutil.copytree(source, target, symlinks=True)
        else:
            shutil.copy2(source, target)
            if executable:
                target.chmod(0o755)

    def write(self, target: Path, text: str, mode: int = 0o644) -> None:
        if target.is_file() and target.read_text(encoding="utf-8") == text:
            self.emit(f"  unchanged {target}")
            return
        self._own(target)
        self.emit(f"  write {target}")
        if self.options.dry_run:
            return
        target.parent.mkdir(parents=True, exist_ok=True)
        fd, temporary = tempfile.mkstemp(prefix=f".{target.name}.", dir=target.parent)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                handle.write(text)
                handle.flush()
                os.fsync(handle.fileno())
            os.chmod(temporary, mode)
            os.replace(temporary, target)
        except Exception:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass
            raise


def packages(ctx: Context) -> list[str]:
    result: list[str] = []
    root = ctx.root / "manifests"
    for filename in ctx.profile["manifests"]:
        for package in manifest(root / filename):
            if package not in result:
                result.append(package)
    return result


def preflight_check(_: Context) -> bool:
    return False


def preflight_apply(ctx: Context) -> None:
    if os.geteuid() == 0:
        raise InstallError("run as a normal user; sudo is used only when required")
    if platform.system() != "Linux" or not Path("/etc/arch-release").exists():
        raise InstallError("this installer currently targets Arch Linux")
    for command in ("sudo", "pacman", "python", "systemctl"):
        if not ctx.has(command):
            raise InstallError(f"missing required command: {command}")
    try:
        socket.getaddrinfo("archlinux.org", 443)
    except OSError as error:
        raise InstallError(f"network or DNS check failed: {error}") from error
    if not ctx.options.dry_run and not ctx.options.noninteractive:
        ctx.run(["sudo", "-v"])
    ctx.emit(f"  system: {platform.platform()}")


def preflight_verify(ctx: Context) -> bool:
    return Path("/etc/arch-release").exists() and ctx.has("pacman")


def repositories_check(ctx: Context) -> bool:
    return (ctx.root / "vendor/UPSTREAM_LOCK.json").is_file()


def repositories_apply(ctx: Context) -> None:
    assert ctx.state is not None
    ctx.state.note(
        "Built-in modules are the runtime source. Run scripts/sync-upstreams.sh "
        "in a development checkout to refresh imported upstream snapshots."
    )
    ctx.emit("  built-in modules selected; upstream sync is a maintainer operation")


def repositories_verify(ctx: Context) -> bool:
    return (ctx.root / "modules").is_dir()


def package_check(ctx: Context) -> bool:
    return all(ctx.package_installed(name) for name in packages(ctx))


def package_apply(ctx: Context) -> None:
    missing = [name for name in packages(ctx) if not ctx.package_installed(name)]
    if not missing:
        ctx.emit("  all packages already installed")
        return
    ctx.emit("  install: " + " ".join(missing))
    ctx.run(["pacman", "-S", "--needed", "--noconfirm", *missing], sudo=True)
    if not ctx.options.dry_run:
        assert ctx.state is not None
        ctx.state.record_installed_packages(
            [name for name in missing if ctx.package_installed(name)]
        )


def package_verify(ctx: Context) -> bool:
    if ctx.options.dry_run:
        return True
    missing = [name for name in packages(ctx) if not ctx.package_installed(name)]
    if missing:
        ctx.emit("  still missing: " + " ".join(missing))
    return not missing


def directories_check(ctx: Context) -> bool:
    return all(
        path.is_dir()
        for path in (
            ctx.config,
            ctx.data,
            ctx.state_home,
            ctx.home / ".local/bin",
            ctx.home / "Pictures/Screenshots",
        )
    )


def directories_apply(ctx: Context) -> None:
    for path in (
        ctx.config,
        ctx.data,
        ctx.state_home,
        ctx.home / ".local/bin",
        ctx.home / "Pictures/Screenshots",
        ctx.home / "Downloads",
    ):
        ctx.emit(f"  mkdir {path}")
        if not ctx.options.dry_run:
            path.mkdir(parents=True, exist_ok=True)
    if ctx.has("xdg-user-dirs-update"):
        ctx.run(["xdg-user-dirs-update"])


def directories_verify(ctx: Context) -> bool:
    return ctx.options.dry_run or (ctx.config.is_dir() and (ctx.home / ".local/bin").is_dir())


def theme_check(ctx: Context) -> bool:
    return all(
        path.is_file()
        for path in (
            ctx.home / ".local/bin/theme",
            ctx.home / ".local/bin/term",
            ctx.home / ".zshrc",
            ctx.config / "zsh/aliases.zsh",
            ctx.config / "kitty/kitty.conf",
            ctx.config / "atuin/config.toml",
            ctx.config / "theme-engine/generated/theme.json",
        )
    )


def theme_apply(ctx: Context) -> None:
    theme = ctx.root / "modules/theme-engine"
    terminal = ctx.root / "modules/terminal"
    ctx.install(theme / "bin/theme", ctx.home / ".local/bin/theme", executable=True)
    ctx.install(terminal / "bin/term", ctx.home / ".local/bin/term", executable=True)
    ctx.install(theme / "themes", ctx.config / "theme-engine/themes")
    ctx.install(theme / "schema", ctx.config / "theme-engine/schema")
    ctx.install(terminal / "kitty/kitty.conf", ctx.config / "kitty/kitty.conf")
    ctx.install(terminal / "zsh/.zshrc", ctx.home / ".zshrc")
    ctx.install(terminal / "zsh/aliases.zsh", ctx.config / "zsh/aliases.zsh")
    ctx.install(terminal / "atuin/config.toml", ctx.config / "atuin/config.toml")
    ctx.run([str(ctx.home / ".local/bin/theme"), ctx.options.theme])


def theme_verify(ctx: Context) -> bool:
    if ctx.options.dry_run:
        return True
    try:
        current = json_file(ctx.config / "theme-engine/generated/theme.json")
    except (OSError, json.JSONDecodeError):
        return False
    return current.get("name") == ctx.options.theme


def hypr_check(ctx: Context) -> bool:
    return (ctx.config / "hypr/.arch-wm-managed").is_file()


def hypr_apply(ctx: Context) -> None:
    ctx.install(ctx.root / "modules/hyprland/config", ctx.config / "hypr")
    ctx.run([str(ctx.home / ".local/bin/theme"), ctx.options.theme])


def hypr_verify(ctx: Context) -> bool:
    return ctx.options.dry_run or all(
        path.is_file()
        for path in (
            ctx.config / "hypr/hyprland.conf",
            ctx.config / "hypr/conf/autostart.conf",
            ctx.config / "hypr/generated/theme.conf",
            ctx.config / "hypr/.arch-wm-managed",
        )
    )


def shell_check(ctx: Context) -> bool:
    return (ctx.config / "quickshell/arch-wm/.arch-wm-managed").is_file()


def shell_apply(ctx: Context) -> None:
    ctx.install(ctx.root / "modules/shell", ctx.config / "quickshell/arch-wm")


def shell_verify(ctx: Context) -> bool:
    return ctx.options.dry_run or all(
        path.is_file()
        for path in (
            ctx.config / "quickshell/arch-wm/shell.qml",
            ctx.config / "quickshell/arch-wm/core/Theme.qml",
            ctx.config / "quickshell/arch-wm/surfaces/bar/BarSurface.qml",
            ctx.config / "quickshell/arch-wm/.arch-wm-managed",
        )
    )


def services_check(ctx: Context) -> bool:
    return all(ctx.service_enabled(name) for name in ctx.profile.get("services", []))


def services_apply(ctx: Context) -> None:
    for name in ctx.profile.get("services", []):
        if ctx.service_enabled(name):
            ctx.emit(f"  already enabled: {name}")
            continue
        ctx.run(["systemctl", "enable", "--now", name], sudo=True)
        if not ctx.options.dry_run and ctx.service_enabled(name):
            assert ctx.state is not None
            ctx.state.record_enabled_service(name)


def services_verify(ctx: Context) -> bool:
    return ctx.options.dry_run or all(
        ctx.service_enabled(name) for name in ctx.profile.get("services", [])
    )


def session_check(ctx: Context) -> bool:
    return (ctx.config / "environment.d/90-arch-wm.conf").is_file()


def session_apply(ctx: Context) -> None:
    ctx.write(
        ctx.config / "environment.d/90-arch-wm.conf",
        "XDG_CURRENT_DESKTOP=Hyprland\n"
        "XDG_SESSION_DESKTOP=Hyprland\n"
        "QT_QPA_PLATFORM=wayland;xcb\n"
        "MOZ_ENABLE_WAYLAND=1\n",
    )
    ctx.write(
        ctx.config / "arch-wm/session-example.zprofile",
        "# Optional TTY1 autostart; the installer never edits ~/.zprofile.\n"
        '# if [ -z "$DISPLAY" ] && [ "${XDG_VTNR:-0}" = 1 ]; then exec Hyprland; fi\n',
    )


def session_verify(ctx: Context) -> bool:
    return ctx.options.dry_run or (ctx.config / "environment.d/90-arch-wm.conf").is_file()


def validate_check(_: Context) -> bool:
    return False


def validate_apply(ctx: Context) -> None:
    ctx.run([sys.executable, str(ctx.root / "scripts/validate-layouts.py")])
    ctx.run([sys.executable, "-m", "unittest", "discover", "-s", str(ctx.root / "tests")])
    ctx.run([str(ctx.root / "scripts/check-legacy-widget-free.sh")])
    if ctx.has("hyprctl") and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        result = ctx.run(["hyprctl", "configerrors"], capture=True)
        if result.stdout.strip():
            raise InstallError("Hyprland config errors:\n" + result.stdout.strip())


def validate_verify(_: Context) -> bool:
    return True


def no_rollback(_: Context) -> None:
    return


@dataclass(frozen=True)
class Stage:
    name: str
    check: Callable[[Context], bool]
    apply: Callable[[Context], None]
    verify: Callable[[Context], bool]
    rollback: Callable[[Context], None] = no_rollback


STAGES = (
    Stage("00-preflight", preflight_check, preflight_apply, preflight_verify),
    Stage("10-repositories", repositories_check, repositories_apply, repositories_verify),
    Stage("20-packages", package_check, package_apply, package_verify),
    Stage("30-user-directories", directories_check, directories_apply, directories_verify),
    Stage("40-theme-engine", theme_check, theme_apply, theme_verify),
    Stage("50-hyprland", hypr_check, hypr_apply, hypr_verify),
    Stage("60-quickshell", shell_check, shell_apply, shell_verify),
    Stage("70-services", services_check, services_apply, services_verify),
    Stage("80-session", session_check, session_apply, session_verify),
    Stage("90-validate", validate_check, validate_apply, validate_verify),
)


def stage_selection(options: Options) -> list[Stage]:
    selected = list(STAGES)
    if options.only_stage:
        return [stage for stage in selected if stage.name == options.only_stage]
    if options.from_stage:
        selected = selected[STAGE_ORDER.index(options.from_stage):]
    return selected


def install_command(ctx: Context) -> int:
    assert ctx.state is not None
    ctx.emit("Arch WM Install")
    ctx.emit(f"profile={ctx.options.profile} theme={ctx.options.theme} run={ctx.run_id}")
    if ctx.options.dry_run:
        ctx.emit("DRY RUN: no packages, files, services or state will be changed")
    try:
        for stage in stage_selection(ctx.options):
            ctx.emit(f"\n== {stage.name} ==")
            if ctx.options.resume and ctx.state.stage_complete(stage.name):
                ctx.emit("  completed previously; skipping")
                continue
            if stage.check(ctx):
                ctx.emit("  already satisfied")
            else:
                stage.apply(ctx)
            if not stage.verify(ctx):
                raise InstallError(f"verification failed: {stage.name}")
            if not ctx.options.dry_run:
                ctx.state.mark_stage_complete(stage.name)
        if not ctx.options.dry_run:
            ctx.state.mark_status("installed")
        ctx.emit("\nInstall stages passed. Reboot or launch Hyprland from a TTY.")
        return 0
    except Exception:
        if not ctx.options.dry_run:
            ctx.state.mark_status("failed")
        raise


def uninstall_command(ctx: Context) -> int:
    active = StateStore.load_active(ctx.state_root, ctx.backup_root)
    ctx.emit(f"Restoring installation run {active.run_id}")
    for service in reversed(active.data.get("enabled_services", [])):
        ctx.run(["systemctl", "disable", "--now", service], sudo=True, check=False)
    for action in active.restore(dry_run=ctx.options.dry_run):
        ctx.emit("  " + action)
    owned_packages = list(reversed(active.data.get("installed_packages", [])))
    if ctx.options.remove_packages and owned_packages:
        ctx.run(["pacman", "-Rns", "--noconfirm", *owned_packages], sudo=True, check=False)
    elif owned_packages:
        ctx.emit("  packages retained; use --remove-packages to remove installer-owned packages")
    ctx.emit("Rollback finished.")
    return 0


def help_command(ctx: Context) -> int:
    # Replaced by installer/entry.py with the full reference renderer.
    ctx.emit("Arch WM Install help is rendered by the installer package.")
    return 0


def doctor_command(ctx: Context) -> int:
    checks = {
        "Arch Linux": Path("/etc/arch-release").exists(),
        "Hyprland": ctx.has("Hyprland"),
        "Quickshell": ctx.has("qs"),
        "theme": (ctx.home / ".local/bin/theme").is_file(),
        "terminal profile": (ctx.config / "kitty/kitty.conf").is_file(),
        "Hyprland config": (ctx.config / "hypr/hyprland.conf").is_file(),
        "shell config": (ctx.config / "quickshell/arch-wm/shell.qml").is_file(),
        "theme contract": (ctx.config / "theme-engine/generated/theme.json").is_file(),
    }
    width = max(map(len, checks))
    for label, passed in checks.items():
        ctx.emit(f"{label:<{width}}  {'OK' if passed else 'MISSING'}")
    return 0 if all(checks.values()) else 1


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(prog="arch-wm-install")
    commands = result.add_subparsers(dest="command", required=True)

    def common(target: argparse.ArgumentParser) -> None:
        target.add_argument("--profile", choices=("minimal", "desktop", "workstation"), default="desktop")
        target.add_argument("--theme", default="y2k")
        target.add_argument("--dry-run", action="store_true")
        target.add_argument("--noninteractive", action="store_true")
        target.add_argument("--no-aur", action="store_true")
        target.add_argument("--verbose", action="store_true")

    install = commands.add_parser("install")
    common(install)
    install.add_argument("--resume", action="store_true")
    install.add_argument("--from-stage", choices=STAGE_ORDER)
    install.add_argument("--only-stage", choices=STAGE_ORDER)

    uninstall = commands.add_parser("uninstall")
    common(uninstall)
    uninstall.add_argument("--remove-packages", action="store_true")

    doctor = commands.add_parser("doctor")
    common(doctor)

    commands.add_parser("help", help="print keybinds and important file locations")
    return result


def make_options(args: argparse.Namespace) -> Options:
    # The `help` subcommand exposes none of the common options; every field
    # therefore falls back to its Options default when absent.
    return Options(
        command=args.command,
        profile=getattr(args, "profile", "desktop"),
        theme=getattr(args, "theme", "y2k"),
        dry_run=getattr(args, "dry_run", False),
        noninteractive=getattr(args, "noninteractive", False),
        no_aur=getattr(args, "no_aur", False),
        resume=getattr(args, "resume", False),
        from_stage=getattr(args, "from_stage", None),
        only_stage=getattr(args, "only_stage", None),
        verbose=getattr(args, "verbose", False),
        remove_packages=getattr(args, "remove_packages", False),
    )


def main(argv: Sequence[str] | None = None) -> int:
    args = parser().parse_args(argv)
    options = make_options(args)
    try:
        ctx = Context(Path(__file__).resolve().parents[1], options)
        if options.command == "install":
            return install_command(ctx)
        if options.command == "uninstall":
            return uninstall_command(ctx)
        if options.command == "help":
            return help_command(ctx)
        return doctor_command(ctx)
    except (InstallError, FileNotFoundError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
