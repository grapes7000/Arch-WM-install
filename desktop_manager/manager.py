from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .codex_review import review as codex_review
from .models import ProfileError, ProfileSpec, load_profile
from .scanner import scan_tree

MANAGED = ("hypr", "quickshell", "waybar")
PROTECTED = ("kitty", "nvim", "starship.toml", "zsh", "atuin", "theme-engine")
PROVIDERS = {"quickshell", "quickshell-git", "noctalia-qs"}


def _now() -> str:
    # Microseconds avoid backup/journal collisions during fast rollback tests and
    # back-to-back profile switches.
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")


def _read(path: Path, default: dict | None = None) -> dict:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return {} if default is None else default


def _write(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(data, f, indent=2, sort_keys=True)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except FileNotFoundError:
            pass
        raise


def _manifest(path: Path) -> list[str]:
    out: list[str] = []
    for raw in path.read_text().splitlines():
        value = raw.split("#", 1)[0].strip()
        if value and value not in out:
            out.append(value)
    return out


@dataclass(frozen=True)
class Paths:
    home: Path
    config: Path
    data_root: Path
    state_root: Path
    profile_defs: Path

    @classmethod
    def current(cls, defs: Path) -> "Paths":
        h = Path.home()
        cfg = Path(os.environ.get("XDG_CONFIG_HOME", h / ".config"))
        dat = Path(os.environ.get("XDG_DATA_HOME", h / ".local/share"))
        st = Path(os.environ.get("XDG_STATE_HOME", h / ".local/state"))
        return cls(
            h,
            cfg,
            dat / "arch-wm-install/desktop-profiles",
            st / "arch-wm-install/desktop-profiles",
            defs,
        )


class DesktopManager:
    def __init__(self, paths: Paths | None = None) -> None:
        self.paths = paths or Paths.current(Path(__file__).resolve().parent / "profiles")
        self.paths.data_root.mkdir(parents=True, exist_ok=True)
        self.paths.state_root.mkdir(parents=True, exist_ok=True)

    @property
    def registry_path(self):
        return self.paths.state_root / "registry.json"

    @property
    def package_ledger_path(self):
        return self.paths.state_root / "packages.json"

    def source_dir(self, p):
        return self.paths.data_root / "sources" / p

    def payload_dir(self, p):
        return self.paths.data_root / "profiles" / p / "payload"

    def registry(self):
        return _read(
            self.registry_path,
            {"active": None, "pending": None, "previous": None, "profiles": {}},
        )

    def save_registry(self, d):
        _write(self.registry_path, d)

    def specs(self) -> dict[str, ProfileSpec]:
        return {
            s.id: s
            for s in (
                load_profile(p) for p in sorted(self.paths.profile_defs.glob("*.json"))
            )
        }

    def spec(self, p) -> ProfileSpec:
        try:
            return self.specs()[p]
        except KeyError as e:
            raise ProfileError(f"unknown curated profile: {p}") from e

    @staticmethod
    def _git(cwd: Path, *args: str) -> str:
        r = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)
        if r.returncode:
            raise ProfileError(f"git {' '.join(args)} failed: {r.stderr.strip()}")
        return r.stdout

    def fetch(self, p, refresh=False):
        s = self.spec(p)
        d = self.source_dir(p)
        if d.exists() and not refresh:
            return {
                "profile": p,
                "source": str(d),
                "commit": self._git(d, "rev-parse", "HEAD").strip(),
                "reused": True,
            }
        if d.exists():
            shutil.rmtree(d)
        d.parent.mkdir(parents=True, exist_ok=True)
        r = subprocess.run(
            ["git", "clone", "--depth", "1", "--branch", s.ref, "--", s.repository, str(d)],
            text=True,
            capture_output=True,
        )
        if r.returncode:
            raise ProfileError(f"git clone failed: {(r.stderr or r.stdout).strip()}")
        return {
            "profile": p,
            "source": str(d),
            "commit": self._git(d, "rev-parse", "HEAD").strip(),
            "reused": False,
        }

    def audit(self, p, use_codex=False):
        s = self.spec(p)
        root = self.source_dir(p)
        if not root.is_dir():
            raise ProfileError(f"{p} has not been fetched; run desktopctl fetch {p}")
        full = scan_tree(root)
        prefixes = tuple(m.source.rstrip("/") for m in s.config)
        inc = []
        exc = []
        for finding in full["findings"]:
            path = str(finding.get("path", ""))
            target = inc if any(
                path == prefix or path.startswith(prefix + "/") for prefix in prefixes
            ) else exc
            target.append(finding)
        eff = dict(full)
        eff["findings"] = inc
        eff["blockers"] = sum(x["severity"] == "block" for x in inc)
        eff["warnings"] = sum(x["severity"] == "warn" for x in inc)
        eff["risk_score"] = min(100, eff["blockers"] * 35 + eff["warnings"] * 3)
        eff["verdict"] = (
            "blocked" if eff["blockers"] else ("review" if eff["warnings"] else "pass")
        )
        out = {
            "profile": p,
            "static": eff,
            "source_scan": {
                k: full[k] for k in ("verdict", "risk_score", "blockers", "warnings")
            },
            "excluded_findings": exc,
        }
        if use_codex:
            out["codex"] = codex_review(s, eff)
        return out

    def _packages(self, s: ProfileSpec, root: Path):
        official = list(s.official_packages)
        aur = list(s.aur_packages)
        for rel in s.package_files:
            f = root / rel
            if not f.is_file():
                raise ProfileError(f"declared package manifest missing: {rel}")
            for x in _manifest(f):
                if x not in official:
                    official.append(x)
        for rel in s.aur_package_files:
            f = root / rel
            if not f.is_file():
                raise ProfileError(f"declared AUR manifest missing: {rel}")
            for x in _manifest(f):
                if x not in aur:
                    aur.append(x)
        return official, aur

    @staticmethod
    def _installed(pkg):
        if not shutil.which("pacman"):
            return False
        return (
            subprocess.run(
                ["pacman", "-Q", pkg],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode
            == 0
        )

    def plan(self, p, use_codex=False):
        s = self.spec(p)
        root = self.source_dir(p)
        if not root.is_dir():
            self.fetch(p)
        audit = self.audit(p, use_codex=use_codex)
        mappings = []
        missing = []
        for m in s.config:
            exists = (root / m.source).exists()
            mappings.append({"source": m.source, "target": m.target, "exists": exists})
            if not exists:
                missing.append(m.source)
        official, aur = self._packages(s, root)
        qs = shutil.which("qs") is not None
        mo = [
            x
            for x in official
            if not self._installed(x) and not (qs and x in PROVIDERS)
        ]
        ma = [x for x in aur if not self._installed(x) and not (qs and x in PROVIDERS)]
        blocked = bool(
            audit["static"]["blockers"]
            or missing
            or audit.get("codex", {}).get("verdict") == "block"
        )
        return {
            "profile": p,
            "name": s.name,
            "repository": s.repository,
            "ref": s.ref,
            "runtime": s.runtime,
            "capabilities": s.capabilities,
            "mappings": mappings,
            "protected": sorted(set(PROTECTED) | set(s.protected)),
            "packages": {
                "official": official,
                "aur": aur,
                "missing_official": mo,
                "missing_aur": ma,
                "quickshell_provider_reused": qs
                and bool(PROVIDERS.intersection(official + aur)),
            },
            "audit": audit,
            "blocked": blocked,
            "notes": s.notes,
        }

    def prepare(self, p, use_codex=False, force_review=False):
        plan = self.plan(p, use_codex=use_codex)
        if plan["blocked"]:
            raise ProfileError(
                "profile is blocked by safety checks; inspect desktopctl plan output"
            )
        if plan["audit"]["static"]["warnings"] and not force_review:
            raise ProfileError(
                "profile has static warnings; re-run prepare with --accept-review after reading the plan"
            )
        s = self.spec(p)
        root = self.source_dir(p)
        payload = self.payload_dir(p)
        tmp = payload.with_name("payload.new")
        shutil.rmtree(tmp, ignore_errors=True)
        (tmp / "config").mkdir(parents=True)
        for m in s.config:
            src = root / m.source
            dst = tmp / "config" / m.target
            if src.is_dir():
                shutil.copytree(src, dst, symlinks=True)
            else:
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
        scan = scan_tree(tmp)
        if scan["blockers"]:
            shutil.rmtree(tmp, ignore_errors=True)
            raise ProfileError(
                "curated payload contains a hard blocker; refusing to stage"
            )
        lock = {
            "profile": p,
            "repository": s.repository,
            "ref": s.ref,
            "commit": self._git(root, "rev-parse", "HEAD").strip(),
            "prepared_at": _now(),
            "scan": scan,
        }
        _write(tmp / "profile-lock.json", lock)
        payload.parent.mkdir(parents=True, exist_ok=True)
        old = payload.with_name("payload.old")
        shutil.rmtree(old, ignore_errors=True)
        if payload.exists():
            payload.rename(old)
        tmp.rename(payload)
        shutil.rmtree(old, ignore_errors=True)
        reg = self.registry()
        reg.setdefault("profiles", {})[p] = {
            "prepared": True,
            "commit": lock["commit"],
            "prepared_at": lock["prepared_at"],
        }
        self.save_registry(reg)
        return lock

    @staticmethod
    def _query_installed():
        if not shutil.which("pacman"):
            return []
        r = subprocess.run(["pacman", "-Qq"], text=True, capture_output=True)
        return [x for x in r.stdout.splitlines() if x]

    def _record_package_ownership(self, p: str, plan: dict, added: list[str]) -> None:
        ledger = _read(self.package_ledger_path, {"packages": {}})
        added_set = set(added)

        # Record the complete transaction delta, including transitive
        # dependencies, so profile removal can clean up packages the manager
        # introduced indirectly.
        for pkg in added:
            entry = ledger["packages"].setdefault(
                pkg,
                {
                    "preexisting": False,
                    "installed_by_manager": True,
                    "owners": [],
                },
            )
            if p not in entry["owners"]:
                entry["owners"].append(p)

        # A later profile can reuse a package previously installed by the
        # manager. Add the new owner even when there is no pacman transaction.
        # Truly pre-existing packages remain ineligible for manager removal.
        for pkg in set(plan["packages"]["official"]) - added_set:
            existing = ledger["packages"].get(pkg)
            if existing and existing.get("installed_by_manager"):
                if p not in existing.setdefault("owners", []):
                    existing["owners"].append(p)
                continue
            if not self._installed(pkg):
                continue
            entry = ledger["packages"].setdefault(
                pkg,
                {
                    "preexisting": True,
                    "installed_by_manager": False,
                    "owners": [],
                },
            )
            if p not in entry["owners"]:
                entry["owners"].append(p)

        _write(self.package_ledger_path, ledger)

    def install_packages(self, p, apply=False):
        plan = self.plan(p)
        missing = list(plan["packages"]["missing_official"])
        aur = list(plan["packages"]["missing_aur"])
        out = {
            "missing_official": missing,
            "missing_aur": aur,
            "installed": [],
            "apply": apply,
        }
        if not apply:
            return out
        if os.geteuid() == 0:
            raise ProfileError("do not run desktopctl as root")

        added: list[str] = []
        if missing:
            sim = subprocess.run(
                ["pacman", "-S", "--needed", "--print-format", "%n", *missing],
                text=True,
                capture_output=True,
            )
            out["simulation"] = [x for x in sim.stdout.splitlines() if x.strip()]
            if sim.returncode:
                raise ProfileError(
                    f"pacman transaction simulation failed ({sim.returncode}): "
                    f"{sim.stderr.strip()[:1000]}"
                )
            before = set(self._query_installed())
            r = subprocess.run(["sudo", "pacman", "-S", "--needed", *missing])
            if r.returncode:
                raise ProfileError(f"pacman dependency install failed ({r.returncode})")
            after = set(self._query_installed())
            added = sorted(after - before)
            out["installed"] = added

        self._record_package_ownership(p, plan, added)
        return out

    def capture_monitors(self):
        if not (
            shutil.which("hyprctl") and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
        ):
            return []
        r = subprocess.run(
            ["hyprctl", "monitors", "-j"], text=True, capture_output=True
        )
        try:
            data = json.loads(r.stdout) if r.returncode == 0 else []
        except json.JSONDecodeError:
            data = []
        keys = ("name", "width", "height", "refreshRate", "x", "y", "scale")
        return [{k: i.get(k) for k in keys} for i in data]

    def select(self, p):
        if p != "arch-wm":
            self.spec(p)
            if not self.payload_dir(p).is_dir():
                raise ProfileError(f"{p} is not prepared")
        reg = self.registry()
        captured = self.capture_monitors()
        monitors = captured or list(reg.get("monitor_snapshot") or [])
        if p != "arch-wm" and not monitors:
            raise ProfileError(
                "cannot safely select a foreign desktop without a monitor snapshot; "
                "run `desktopctl select` from the working Arch-WM Hyprland session"
            )
        reg["pending"] = p
        if monitors:
            reg["monitor_snapshot"] = monitors
        self.save_registry(reg)
        return {"pending": p, "monitors_captured": len(monitors)}

    def _copy_current_path(self, src: Path, dst: Path) -> None:
        """Copy a managed path's contents, dereferencing only the top-level link."""
        if src.is_symlink():
            try:
                source = src.resolve(strict=True)
            except FileNotFoundError as error:
                raise ProfileError(f"managed config path is a broken symlink: {src}") from error
        else:
            source = src

        if source.is_dir():
            shutil.copytree(source, dst, symlinks=True)
        elif source.exists():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dst)

    def _capture_arch(self):
        payload = self.payload_dir("arch-wm")
        if payload.is_dir():
            return

        stage = payload.with_name("payload.capture")
        shutil.rmtree(stage, ignore_errors=True)
        (stage / "config").mkdir(parents=True)
        try:
            for n in MANAGED:
                src = self.paths.config / n
                if not (src.exists() or src.is_symlink()):
                    continue
                self._copy_current_path(src, stage / "config" / n)
            payload.parent.mkdir(parents=True, exist_ok=True)
            stage.rename(payload)
        except Exception:
            shutil.rmtree(stage, ignore_errors=True)
            raise

        reg = self.registry()
        reg.setdefault("profiles", {})["arch-wm"] = {
            "prepared": True,
            "captured_at": _now(),
            "local_snapshot": True,
        }
        self.save_registry(reg)

    # Compatibility names kept explicit for tests and the future Qt client.
    def _ensure_arch_wm_snapshot(self):
        self._capture_arch()

    def _apply_monitor_snapshot(self, p, monitors):
        self._monitors(p, monitors)

    def _backup(self):
        backup = self.paths.data_root / "backups" / _now()
        (backup / "config").mkdir(parents=True)
        for n in MANAGED:
            src = self.paths.config / n
            if not (src.exists() or src.is_symlink()):
                continue
            self._copy_current_path(src, backup / "config" / n)
        return backup

    def _restore_backup(self, backup: Path) -> None:
        cfg = backup / "config"
        for n in MANAGED:
            target = self.paths.config / n
            if target.exists() or target.is_symlink():
                if target.is_dir() and not target.is_symlink():
                    shutil.rmtree(target)
                else:
                    target.unlink()
            source = cfg / n
            if source.exists() or source.is_symlink():
                self._copy_current_path(source, target)

    def _monitors(self, p, monitors):
        if p == "arch-wm" or not monitors:
            return
        s = self.spec(p)
        hypr = self.payload_dir(p) / "config/hypr"
        if not hypr.is_dir():
            return
        lines = ["-- Managed monitor safety overlay generated by desktopctl."]
        for m in monitors:
            if not (m.get("name") and m.get("width") and m.get("height")):
                continue
            mode = f'{int(m["width"])}x{int(m["height"])}'
            rr = m.get("refreshRate")
            if rr:
                mode += f'@{float(rr):.3f}'.rstrip("0").rstrip(".")
            pos = f'{int(m.get("x") or 0)}x{int(m.get("y") or 0)}'
            scale = float(m.get("scale") or 1)
            lines.append(
                "hl.monitor({ output = "
                f'{json.dumps(str(m["name"]))}, mode = {json.dumps(mode)}, '
                f'position = {json.dumps(pos)}, scale = {scale:g} }} )'.replace("} )", "})")
            )
        overlay = "\n".join(lines) + "\n"
        if s.monitor_adapter == "mainstream-monitors-lua":
            (hypr / "monitors.lua").write_text(overlay)
        elif s.monitor_adapter == "tsugumori-user-lua":
            f = hypr / "user.lua"
            old = f.read_text() if f.is_file() else ""
            begin = "-- desktopctl monitor overlay: begin"
            end = "-- desktopctl monitor overlay: end"
            if begin in old and end in old:
                old = (
                    old.split(begin, 1)[0].rstrip()
                    + "\n"
                    + old.split(end, 1)[1].lstrip()
                ).strip() + "\n"
            f.write_text(old.rstrip() + "\n\n" + begin + "\n" + overlay + end + "\n")

    def _theme_paths(self) -> tuple[Path, Path]:
        return (
            self.paths.config / "theme-engine/targets.conf",
            self.paths.state_root / "theme-targets.saved",
        )

    def _theme_state(self) -> dict[str, str | None]:
        targets, saved = self._theme_paths()
        return {
            "targets": targets.read_text() if targets.is_file() else None,
            "saved": saved.read_text() if saved.is_file() else None,
        }

    def _restore_theme_state(self, state: dict[str, str | None]) -> None:
        targets, saved = self._theme_paths()
        for path, key in ((targets, "targets"), (saved, "saved")):
            value = state.get(key)
            if value is None:
                try:
                    path.unlink()
                except FileNotFoundError:
                    pass
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(value)

    def _theme(self, suspend):
        f, saved = self._theme_paths()
        if suspend:
            if not f.is_file() or saved.exists():
                return
            text = f.read_text()
            saved.write_text(text)
            out = []
            for raw in text.splitlines():
                value = raw.split("#", 1)[0].strip().split("=", 1)[0].strip()
                if value not in {"hypr", "hyprlock", "wallpaper"}:
                    out.append(raw)
            f.write_text("\n".join(out) + "\n")
        elif saved.is_file():
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_text(saved.read_text())
            saved.unlink()

    def _links(self, p):
        cfg = self.payload_dir(p) / "config"
        if not cfg.is_dir():
            raise ProfileError(f"profile payload is missing: {p}")
        for n in MANAGED:
            target = self.paths.config / n
            source = cfg / n
            if target.exists() or target.is_symlink():
                if target.is_dir() and not target.is_symlink():
                    shutil.rmtree(target)
                else:
                    target.unlink()
            if source.exists():
                target.symlink_to(source, target_is_directory=source.is_dir())

    def activate_pending(self, apply=False):
        if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            raise ProfileError(
                "refusing to swap Hyprland config inside a running Hyprland session; "
                "log out and run `desktopctl launch --apply` from a TTY"
            )

        reg = self.registry()
        p = reg.get("pending") or reg.get("active") or "arch-wm"
        if not apply:
            return {"would_activate": p, "apply": False}

        self._capture_arch()
        # _capture_arch can add the recovery profile to registry, so refresh it
        # before committing any switch state.
        reg = self.registry()
        p = reg.get("pending") or reg.get("active") or p
        if p != "arch-wm" and not self.payload_dir(p).is_dir():
            raise ProfileError(f"profile is not prepared: {p}")

        previous = reg.get("active")
        backup = self._backup()
        theme_state = self._theme_state()
        journal_path = self.paths.state_root / "switch-journal.json"
        journal: dict[str, Any] = {
            "started_at": _now(),
            "from": previous,
            "to": p,
            "backup": str(backup),
            "status": "switching",
        }
        _write(journal_path, journal)

        try:
            self._theme(p != "arch-wm")
            self._monitors(p, reg.get("monitor_snapshot") or [])
            self._links(p)
            reg["previous"] = previous
            reg["active"] = p
            reg["pending"] = None
            self.save_registry(reg)
            journal["status"] = "committed"
            journal["finished_at"] = _now()
            _write(journal_path, journal)
            return {"active": p, "backup": str(backup), "apply": True}
        except Exception as error:
            journal["error"] = str(error)
            try:
                restored = False
                if previous and self.payload_dir(previous).is_dir():
                    try:
                        self._links(previous)
                        restored = True
                    except Exception:
                        restored = False
                if not restored:
                    self._restore_backup(backup)
                self._restore_theme_state(theme_state)
                journal["status"] = "rolled_back"
                journal["finished_at"] = _now()
                _write(journal_path, journal)
            except Exception as rollback_error:
                journal["status"] = "rollback_failed"
                journal["rollback_error"] = str(rollback_error)
                journal["finished_at"] = _now()
                _write(journal_path, journal)
                raise ProfileError(
                    f"activation failed ({error}); automatic rollback also failed "
                    f"({rollback_error}); restore from {backup}"
                ) from error
            raise ProfileError(f"activation failed and was rolled back: {error}") from error

    def launch(self, apply=False):
        self.activate_pending(apply=apply)
        if not apply:
            return 0
        exe = shutil.which("Hyprland") or shutil.which("hyprland")
        if not exe:
            raise ProfileError("Hyprland executable not found")
        os.execv(exe, [exe])
        return 0

    def status(self):
        r = self.registry()
        return {
            "active": r.get("active"),
            "pending": r.get("pending"),
            "previous": r.get("previous"),
            "prepared": sorted(
                k for k, v in r.get("profiles", {}).items() if v.get("prepared")
            ),
            "theme_hypr_targets_suspended": (
                self.paths.state_root / "theme-targets.saved"
            ).exists(),
        }

    def remove(self, p, apply=False, remove_packages=False):
        if p == "arch-wm":
            raise ProfileError(
                "the captured Arch-WM recovery profile cannot be removed by this command"
            )
        reg = self.registry()
        if p in {reg.get("active"), reg.get("pending")}:
            raise ProfileError(
                "cannot remove an active or pending profile; select arch-wm first"
            )
        out = {"profile": p, "removed": False, "packages_removed": []}
        if not apply:
            return out
        shutil.rmtree(self.payload_dir(p).parent, ignore_errors=True)
        shutil.rmtree(self.source_dir(p), ignore_errors=True)
        reg.get("profiles", {}).pop(p, None)
        self.save_registry(reg)
        if remove_packages:
            ledger = _read(self.package_ledger_path, {"packages": {}})
            candidates = []
            for pkg, entry in ledger.get("packages", {}).items():
                entry["owners"] = [o for o in entry.get("owners", []) if o != p]
                if (
                    entry.get("installed_by_manager")
                    and not entry.get("preexisting")
                    and not entry["owners"]
                ):
                    candidates.append(pkg)
            if candidates:
                r = subprocess.run(["sudo", "pacman", "-R", "--noconfirm", *candidates])
                if r.returncode == 0:
                    out["packages_removed"] = candidates
                    for x in candidates:
                        ledger["packages"].pop(x, None)
            _write(self.package_ledger_path, ledger)
        out["removed"] = True
        return out
