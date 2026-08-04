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


STAGE_NAMES = (
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


def timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def read_manifest(path: Path) -> list[str]:
    packages: list[str] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        value = raw.split("#", 1)[0].strip()
        if value and value not in packages:
            packages.append(value)
    return packages


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


@dataclass(frozen=True)
class Options:
    command: str
    profile: str
    theme: str
    dry_run: bool
    no_aur: bool
    noninteractive: bool
    resume: bool
    from_stage: str | None
    only_stage: str | None
    verbose: bool
    remove_packages: bool


class InstallerError(RuntimeError):
    pass


class Context:
    def __init__(self, root: Path, options: Options) -> None:
        self.root = root
        self.options = options
        self.home = Path.home()
        self.config_home = Path(os.environ.get("XDG_CONFIG_HOME", self.home / ".config"))
        self.data_home = Path(os.environ.get("XDG_DATA_HOME", self.home / ".local/share"))
        self.state_home = Path(os.environ.get("XDG_STATE_HOME", self.home / ".local/state"))
        self.state_root = self.state_home / "arch-wm-install"
        self.backup_root = self.data_home / "arch-wm-install/backups"
        self.log_dir = self.state_root / "logs"
        self.run_id = self._resolve_run_id()
        self.state = StateStore(self.state_root, self.backup_root, self.run_id)
        self.state.set_metadata(profile=options.profile, theme=options.theme)
        self.profile = self._load_profile()
        self.log_path = self.log_dir / f"{self.run_id}.log"
        if not self.options.dry_run:
            self.log_dir.mkdir(parents=True, exist_ok=True)

    def _resolve_run_id(self) -> str:
        if self.options.resume:
            active = self.state_root / "active.json"
            if not active.exists():
                raise InstallerError("--resume requested but no active state exists")
            payload = load_json(active)
            return str(payload["run_id"])
        return timestamp()

    def _load_profile(self) -> dict:
        path = self.root / "installer/profiles" / f"{self.options.profile}.json"
        if not path.is_file():
            raise InstallerError(f"unknown profile: {self.options.profile}")
        payload = load_json(path)
        if payload.get("name") != self.options.profile:
            raise InstallerError(f"profile name mismatch in {path}")
        return payload

    def emit(self, message: str = "") -> None:
        print(message)
        if self.options.dry_run:
            return
        self.log_dir.mkdir(parents=True, exist_ok=True)
        with self.log_path.open("a", encoding="utf-8") as handle:
            handle.write(message + "\n")

    def format_command(self, command: Sequence[str]) -> str:
        return " ".join(shlex.quote(part) for part in command)

    def run(
        self,
        command: Sequence[str],
        *,
        sudo: bool = False,
        check: bool = True,
        capture: bool = False,
        env: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        argv = [str(part) for part in command]
        if sudo:
            argv = ["sudo", *argv]
        self.emit(f"  $ {self.format_command(argv)}")
        if self.options.dry_run:
            return subprocess.CompletedProcess(argv, 0, "", "")
        result = subprocess.run(
            argv,
            check=False,
            text=True,
            capture_output=capture,
            env=env,
        )
        if capture and self.options.verbose:
            if result.stdout:
                self.emit(result.stdout.rstrip())
            if result.stderr:
                self.emit(result.stderr.rstrip())
        if check and result.returncode != 0:
            detail = result.stderr.strip() if result.stderr else ""
            raise InstallerError(
                f"command failed ({result.returncode}): {self.format_command(argv)}"
                + (f"\n{detail}" if detail else "")
            )
        return result

    def command_exists(self, name: str) -> bool:
        return shutil.which(name) is not None

    def package_installed(self, package: str) -> bool:
        if not self.command_exists("pacman"):
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

    def install_path(self, source: Path, target: Path) -> None:
        source = source.resolve()
        existed = target.exists() or target.is_symlink()
        if existed:
            self.emit(f"  backup {target}")
            self.state.backup_target(target, dry_run=self.options.dry_run)
        else:
            self.state.record_created_path(target)

        self.emit(f"  install {source} -> {target}")
        if self.options.dry_run:
            return
        remove_path(target)
        if source.is_dir():
            shutil.copytree(source, target, symlinks=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)

    def install_text(self, text: str, target: Path, mode: int = 0o644) -> None:
        existed = target.exists() or target.is_symlink()
        if existed:
            current = target.read_text(encoding="utf-8") if target.is_file() else None
            if current == text:
                self.emit(f"  unchanged {target}")
                return
            self.emit(f"  backup {target}")
            self.state.backup_target(target, dry_run=self.options.dry_run)
        else:
            self.state.record_created_path(target)

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


def stage_preflight_check(ctx: Context) -> bool:
    return platform.system() == "Linux" and Path("/etc/arch-release").exists()


def stage_preflight_apply(ctx: Context) -> None:
    if os.geteuid() == 0:
        raise InstallerError("run the installer as a normal user, not root")
    if not Path("/etc/arch-release").exists():
        raise InstallerError("this installer currently supports Arch Linux only")
    for command in ("sudo", "pacman", "systemctl", "python"):
        if not ctx.command_exists(command):
            raise InstallerError(f"missing required command: {command}")
    if not os.environ.get("HOME"):
        raise InstallerError("HOME is not set")
    try:
        socket.getaddrinfo("archlinux.org", 443)
    except OSError as error:
        raise InstallerError(f"network/DNS check failed: {error}") from error
    if not ctx.options.noninteractive and not ctx.options.dry_run:
        ctx.run(["sudo", "-v"])
    ctx.emit(f"  detected {platform.platform()}")
    product_path = Path("/sys/class/dmi/id/product_name")
    if product_path.exists():
        product = product_path.read_text(errors="ignore").strip()
        if product:
            ctx.emit(f"  machine: {product}")


def stage_preflight_verify(ctx: Context) -> bool:
    return Path("/etc/arch-release").exists() and ctx.command_exists("pacman")


def stage_repositories_check(ctx: Context) -> bool:
    lock = ctx.root / "vendor/UPSTREAM_LOCK.json"
    return lock.exists() and any((ctx.root / "vendor/themes").iterdir()) and any(
        (ctx.root / "vendor/hyprland").iterdir()
    )


def stage_repositories_apply(ctx: Context) -> None:
    lock = ctx.root / "vendor/UPSTREAM_LOCK.json"
    if lock.exists():
        ctx.emit("  upstream snapshots already locked")
        return
    script = ctx.root / "scripts/sync-upstreams.sh"
    if script.exists() and ctx.command_exists("git") and ctx.command_exists("rsync"):
        ctx.run([str(script)])
    else:
        ctx.state.note(
            "Upstream snapshots were not populated during installation; built-in modules were used."
        )
        ctx.emit("  upstream snapshots missing; continuing with built-in modules")


def stage_repositories_verify(ctx: Context) -> bool:
    return (ctx.root / "modules").is_dir()


def resolve_packages(ctx: Context) -> list[str]:
    packages: list[str] = []
    manifest_root = ctx.root / "manifests"
    for name in ctx.profile["manifests"]:
        for package in read_manifest(manifest_root / name):
            if package not in packages:
                packages.append(package)
    return packages


def stage_packages_check(ctx: Context) -> bool:
    return all(ctx.package_installed(package) for package in resolve_packages(ctx))


def stage_packages_apply(ctx: Context) -> None:
    packages = resolve_packages(ctx)
    missing = [package for package in packages if not ctx.package_installed(package)]
    if not missing:
        ctx.emit("  all profile packages are already installed")
        return
    ctx.emit(f"  missing packages: {' '.join(missing)}")
    ctx.run(["pacman", "-S", "--needed", "--noconfirm", *missing], sudo=True)
    if not ctx.options.dry_run:
        installed_now = [package for package in missing if ctx.package_installed(package)]
        ctx.state.record_installed_packages(installed_now)


def stage_packages_verify(ctx: Context) -> bool:
    if ctx.options.dry_run:
        return True
    missing = [package for package in resolve_packages(ctx) if not ctx.package_installed(package)]
    if missing:
        ctx.emit(f"  packages still missing: {' '.join(missing)}")
    return not missing


def stage_user_directories_check(ctx: Context) -> bool:
    required = (
        ctx.config_home,
        ctx.data_home,
        ctx.state_home,
        ctx.home / "Pictures/Screenshots",
        ctx.home / "Downloads",
    )
    return all(path.is_dir() for path in required)


def stage_user_directories_apply(ctx: Context) -> None:
    for path in (
        ctx.config_home,
        ctx.data_home,
        ctx.state_home,
        ctx.home / "Pictures/Screenshots",
        ctx.home / "Downloads",
        ctx.home / ".local/bin",
    ):
        ctx.emit(f"  mkdir {path}")
        if not ctx.options.dry_run:
            path.mkdir(parents=True, exist_ok=True)
    if ctx.command_exists("xdg-user-dirs-update"):
        ctx.run(["xdg-user-dirs-update"])


def stage_user_directories_verify(ctx: Context) -> bool:
    return ctx.options.dry_run or (ctx.config_home.is_dir() and ctx.data_home.is_dir())


def stage_theme_engine_check(ctx: Context) -> bool:
    return (ctx.home / ".local/bin/theme").is_file() and (
        ctx.config_home / "theme-engine/generated/theme.json"
    ).is_file()


def stage_theme_engine_apply(ctx: Context) -> None:
    module = ctx.root / "modules/theme-engine"
    ctx.install_path(module / "bin/theme", ctx.home / ".local/bin/theme")
    ctx.install_path(module / "themes", ctx.config_home / "theme-engine/themes")
    ctx.install_path(module / "schema", ctx.config_home / "theme-engine/schema")
    if not ctx.options.dry_run:
        os.chmod(ctx.home / ".local/bin/theme", 0o755)
    ctx.run([str(ctx.home / ".local/bin/theme"), ctx.options.theme])


def stage_theme_engine_verify(ctx: Context) -> bool:
    if ctx.options.dry_run:
        return True
    path = ctx.config_home / "theme-engine/generated/theme.json"
    try:
        payload = load_json(path)
    except (OSError, json.JSONDecodeError):
        return False
    return payload.get("name") == ctx.options.theme and "roles" in payload and "style" in payload


def stage_hyprland_check(ctx: Context) -> bool:
    return (ctx.config_home / "hypr/hyprland.conf").is_file()


def stage_hyprland_apply(ctx: Context) -> None:
    ctx.install_path(ctx.root / "modules/hyprland/config", ctx.config_home / "hypr")
    ctx.run([str(ctx.home / ".local/bin/theme"), ctx.options.theme])


def stage_hyprland_verify(ctx: Context) -> bool:
    required = (
        ctx.config_home / "hypr/hyprland.conf",
        ctx.config_home / "hypr/conf/autostart.conf",
        ctx.config_home / "hypr/generated/theme.conf",
    )
    return ctx.options.dry_run or all(path.is_file() for path in required)


def stage_quickshell_check(ctx: Context) -> bool:
    return (ctx.config_home / "quickshell/arch-wm/shell.qml").is_file()


def stage_quickshell_apply(ctx: Context) -> None:
    ctx.install_path(ctx.root / "modules/shell", ctx.config_home / "quickshell/arch-wm")


def stage_quickshell_verify(ctx: Context) -> bool:
    required = (
        ctx.config_home / "quickshell/arch-wm/shell.qml",
        ctx.config_home / "quickshell/arch-wm/core/Theme.qml",
        ctx.config_home / "quickshell/arch-wm/surfaces/bar/BarSurface.qml",
    )
    return ctx.options.dry_run or all(path.is_file() for path in required)


def stage_services_check(ctx: Context) -> bool:
    return all(ctx.service_enabled(service) for service in ctx.profile.get("services", []))


def stage_services_apply(ctx: Context) -> None:
    for service in ctx.profile.get("services", []):
        if ctx.service_enabled(service):
            ctx.emit(f"  service already enabled: {service}")
            continue
        ctx.run(["systemctl", "enable", "--now", service], sudo=True)
        if not ctx.options.dry_run and ctx.service_enabled(service):
            ctx.state.record_enabled_service(service)


def stage_services_verify(ctx: Context) -> bool:
    return ctx.options.dry_run or all(
        ctx.service_enabled(service) for service in ctx.profile.get("services", [])
    )


def stage_session_check(ctx: Context) -> bool:
    return (ctx.config_home / "environment.d/90-arch-wm.conf").is_file()


def stage_session_apply(ctx: Context) -> None:
    ctx.install_text(
        "XDG_CURRENT_DESKTOP=Hyprland\n"
        "XDG_SESSION_DESKTOP=Hyprland\n"
        "QT_QPA_PLATFORM=wayland;xcb\n"
        "MOZ_ENABLE_WAYLAND=1\n",
        ctx.config_home / "environment.d/90-arch-wm.conf",
    )
    start_line = (
        'if [ -z "$DISPLAY" ] && [ "${XDG_VTNR:-0}" = 1 ] && '
        'command -v Hyprland >/dev/null 2>&1; then exec Hyprland; fi'
    )
    ctx.install_text(
        "# Optional TTY1 auto-start. Copy the next line to ~/.zprofile if desired.\n"
        f"# {start_line}\n",
        ctx.config_home / "arch-wm/session-example.zprofile",
    )
    if (ctx.home / ".zprofile").exists():
        ctx.emit("  existing ~/.zprofile left untouched")


def stage_session_verify(ctx: Context) -> bool:
    return ctx.options.dry_run or (
        ctx.config_home / "environment.d/90-arch-wm.conf"
    ).is_file()


def stage_validate_check(ctx: Context) -> bool:
    return False


def stage_validate_apply(ctx: Context) -> None:
    ctx.run([sys.executable, str(ctx.root / "scripts/validate-layouts.py")])
    ctx.run(
        [sys.executable, "-m", "unittest", "discover", "-s", str(ctx.root / "tests")]
    )
    ctx.run([str(ctx.root / "scripts/check-legacy-widget-free.sh")])
    if ctx.command_exists("hyprctl") and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        result = ctx.run(["hyprctl", "configerrors"], capture=True)
        if result.stdout.strip():
            raise InstallerError(f"Hyprland config errors:\n{result.stdout.strip()}")


def stage_validate_verify(ctx: Context) -> bool:
    return True


@dataclass(frozen=True)
class Stage:
    name: str
    check: Callable[[Context], bool]
    apply: Callable[[Context], None]
    verify: Callable[[Context], bool]


STAGES = (
    Stage("00-preflight", stage_preflight_check, stage_preflight_apply, stage_preflight_verify),
    Stage("10-repositories", stage_repositories_check, stage_repositories_apply, stage_repositories_verify),
    Stage("20-packages", stage_packages_check, stage_packages_apply, stage_packages_verify),
    Stage("30-user-directories", stage_user_directories_check, stage_user_directories_apply, stage_user_directories_verify),
    Stage("40-theme-engine", stage_theme_engine_check, stage_theme_engine_apply, stage_theme_engine_verify),
    Stage("50-hyprland", stage_hyprland_check, stage_hyprland_apply, stage_hyprland_verify),
    Stage("60-quickshell", stage_quickshell_check, stage_quickshell_apply, stage_quickshell_verify),
    Stage("70-services", stage_services_check, stage_services_apply, stage_services_verify),
    Stage("80-session", stage_session_check, stage_session_apply, stage_session_verify),
    Stage("90-validate", stage_validate_check, stage_validate_apply, stage_validate_verify),
)


def selected_stages(options: Options) -> list[Stage]:
    stages = list(STAGES)
    if options.only_stage:
        return [stage for stage in stages if stage.name == options.only_stage]
    if options.from_stage:
        stages = stages[STAGE_NAMES.index(options.from_stage):]
    return stages


def install(ctx: Context) -> int:
    ctx.emit("Arch WM Install")
    ctx.emit(f"profile={ctx.options.profile} theme={ctx.options.theme} run={ctx.run_id}")
    if ctx.options.dry_run:
        ctx.emit("DRY RUN: no files, packages or services will be changed")
    try:
        for stage in selected_stages(ctx.options):
            ctx.emit(f"\n== {stage.name} ==")
            if ctx.options.resume and ctx.state.stage_complete(stage.name):
                ctx.emit("  already completed; skipping")
                continue
            if stage.check(ctx):
                ctx.emit("  already satisfied")
            else:
                stage.apply(ctx)
            if not stage.verify(ctx):
                raise InstallerError(f"verification failed for {stage.name}")
            if not ctx.options.dry_run:
                ctx.state.mark_stage_complete(stage.name)
        if not ctx.options.dry_run:
            ctx.state.mark_status("installed")
        ctx.emit("\nInstallation stages completed successfully.")
        ctx.emit("Log out and select Hyprland, or start Hyprland from a TTY.")
        return 0
    except Exception:
        if not ctx.options.dry_run:
            ctx.state.mark_status("failed")
        raise


def uninstall(ctx: Context) -> int:
    active = StateStore.load_active(ctx.state_root, ctx.backup_root)
    ctx.emit(f"Rolling back installation run {active.run_id}")
    for action in active.restore(dry_run=ctx.options.dry_run):
        ctx.emit(f"  {action}")
    for service in reversed(active.data.get("enabled_services", [])):
        ctx.run(["systemctl", "disable", "--now", service], sudo=True, check=False)
    packages = list(reversed(active.data.get("installed_packages", [])))
    if ctx.options.remove_packages and packages:
        ctx.run(["pacman", "-Rns", "--noconfirm", *packages], sudo=True, check=False)
    elif packages:
        ctx.emit("  packages retained; pass --remove-packages to remove installer-owned packages")
    ctx.emit("Rollback complete.")
    return 0


def doctor(ctx: Context) -> int:
    checks = {
        "Arch Linux": Path("/etc/arch-release").exists(),
        "pacman": ctx.command_exists("pacman"),
        "Hyprland": ctx.command_exists("Hyprland"),
        "Quickshell": ctx.command_exists("qs"),
        "theme command": (ctx.home / ".local/bin/theme").is_file(),
        "Hyprland config": (ctx.config_home / "hypr/hyprland.conf").is_file(),
        "Quickshell config": (ctx.config_home / "quickshell/arch-wm/shell.qml").is_file(),
        "theme contract": (ctx.config_home / "theme-engine/generated/theme.json").is_file(),
    }
    width = max(len(name) for name in checks)
    for name, ok in checks.items():
        ctx.emit(f"{name:<{width}}  {'OK' if ok else 'MISSING'}")
    return 0 if all(checks.values()) else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="arch-wm-install",
        description="Install and manage the Arch WM desktop.",
    )
    subparsers = parser.add_subparsers(dest="command", required=False)
    install_parser = subparsers.add_parser("install", help="install or update the desktop")
    uninstall_parser = subparsers.add_parser("uninstall", help="restore tracked backups")
    doctor_parser = subparsers.add_parser("doctor", help="check installation health")

    def common(target: argparse.ArgumentParser) -> None:
        target.add_argument("--profile", choices=("minimal", "desktop", "workstation"), default="desktop")
        target.add_argument("--theme", default="y2k")
        target.add_argument("--dry-run", action="store_true")
        target.add_argument("--no-aur", action="store_true")
        target.add_argument("--noninteractive", action="store_true")
        target.add_argument("--verbose", action="store_true")

    common(install_parser)
    common(uninstall_parser)
    common(doctor_parser)
    install_parser.add_argument("--resume", action="store_true")
    install_parser.add_argument("--from-stage", choices=STAGE_NAMES)
    install_parser.add_argument("--only-stage", choices=STAGE_NAMES)
    uninstall_parser.add_argument("--remove-packages", action="store_true")
    return parser


def options_from_args(namespace: argparse.Namespace) -> Options:
    return Options(
        command=namespace.command or "install",
        profile=namespace.profile,
        theme=namespace.theme,
        dry_run=namespace.dry_run,
        no_aur=namespace.no_aur,
        noninteractive=namespace.noninteractive,
        resume=getattr(namespace, "resume", False),
        from_stage=getattr(namespace, "from_stage", None),
        only_stage=getattr(namespace, "only_stage", None),
        verbose=namespace.verbose,
        remove_packages=getattr(namespace, "remove_packages", False),
    )


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    raw = list(sys.argv[1:] if argv is None else argv)
    if not raw or raw[0].startswith("-"):
        raw.insert(0, "install")
    namespace = parser.parse_args(raw)
    options = options_from_args(namespace)
    root = Path(__file__).resolve().parents[1]
    try:
        ctx = Context(root, options)
        if options.command == "install":
            return install(ctx)
        if options.command == "uninstall":
            return uninstall(ctx)
        if options.command == "doctor":
            return doctor(ctx)
        parser.error(f"unknown command: {options.command}")
    except (InstallerError, FileNotFoundError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0
