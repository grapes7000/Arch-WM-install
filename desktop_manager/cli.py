from __future__ import annotations

import argparse
import json
import sys

from . import __version__
from .manager import DesktopManager
from .models import ProfileError


def _print(data: object, as_json: bool) -> None:
    if as_json:
        print(json.dumps(data, indent=2, sort_keys=True))
        return
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(value, (dict, list, tuple)):
                print(f"{key}: {json.dumps(value, indent=2)}")
            else:
                print(f"{key}: {value}")
    else:
        print(data)


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="desktopctl",
        description="Safe, optional Hyprland desktop-profile manager for Arch-WM-install.",
    )
    p.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    p.add_argument("--json", action="store_true", help="machine-readable output for future GUI clients")
    sub = p.add_subparsers(dest="command", required=True)

    sub.add_parser("catalog", help="list curated profiles")
    sub.add_parser("status", help="show active/pending/prepared profiles")

    fetch = sub.add_parser("fetch", help="clone a curated profile without executing it")
    fetch.add_argument("profile")
    fetch.add_argument("--refresh", action="store_true")

    for name in ("audit", "plan"):
        cmd = sub.add_parser(name)
        cmd.add_argument("profile")
        cmd.add_argument("--codex", action="store_true", help="run optional read-only Codex second pass")

    prepare = sub.add_parser("prepare", help="extract only curated desktop config into managed storage")
    prepare.add_argument("profile")
    prepare.add_argument("--codex", action="store_true")
    prepare.add_argument(
        "--accept-review",
        action="store_true",
        help="accept non-blocking static warnings after reviewing the plan",
    )

    deps = sub.add_parser("packages", help="show/install official repo dependencies")
    deps.add_argument("profile")
    deps.add_argument("--apply", action="store_true")
    deps.add_argument(
        "--allow-aur",
        action="store_true",
        help="reserved for a future reviewed AUR flow; v0.1 never executes foreign PKGBUILDs",
    )

    select = sub.add_parser("select", help="select a prepared profile for the next Hyprland launch")
    select.add_argument("profile")

    activate = sub.add_parser("activate-pending", help="apply pending config links outside Hyprland")
    activate.add_argument("--apply", action="store_true")

    launch = sub.add_parser("launch", help="activate pending profile and exec Hyprland; run from a TTY")
    launch.add_argument("--apply", action="store_true")

    restore = sub.add_parser("restore", help="select the captured Arch-WM profile")
    restore.add_argument("--apply", action="store_true")

    remove = sub.add_parser("remove", help="remove a non-active prepared profile")
    remove.add_argument("profile")
    remove.add_argument("--apply", action="store_true")
    remove.add_argument("--remove-packages", action="store_true")
    return p


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    manager = DesktopManager()
    try:
        if args.command == "catalog":
            data = {
                key: {
                    "name": spec.name,
                    "kind": spec.kind,
                    "repository": spec.repository,
                    "runtime": spec.runtime,
                    "risk_policy": spec.risk_policy,
                }
                for key, spec in manager.specs().items()
            }
        elif args.command == "status":
            data = manager.status()
        elif args.command == "fetch":
            data = manager.fetch(args.profile, refresh=args.refresh)
        elif args.command == "audit":
            data = manager.audit(args.profile, use_codex=args.codex)
        elif args.command == "plan":
            data = manager.plan(args.profile, use_codex=args.codex)
        elif args.command == "prepare":
            data = manager.prepare(
                args.profile, use_codex=args.codex, force_review=args.accept_review
            )
        elif args.command == "packages":
            data = manager.install_packages(args.profile, apply=args.apply)
            if data["missing_aur"]:
                data["aur_note"] = (
                    "AUR packages are reported but not auto-installed in v0.1; "
                    "foreign PKGBUILDs are never executed by the generic importer."
                )
        elif args.command == "select":
            data = manager.select(args.profile)
        elif args.command == "activate-pending":
            data = manager.activate_pending(apply=args.apply)
        elif args.command == "launch":
            return manager.launch(apply=args.apply)
        elif args.command == "restore":
            data = manager.select("arch-wm")
            if args.apply:
                data["activation"] = manager.activate_pending(apply=True)
        elif args.command == "remove":
            data = manager.remove(
                args.profile,
                apply=args.apply,
                remove_packages=args.remove_packages,
            )
        else:
            raise ProfileError(f"unknown command: {args.command}")
        _print(data, args.json)
        return 0
    except (ProfileError, OSError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
