from __future__ import annotations

import json
import os
import shutil
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = 1


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    except Exception:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def copy_path(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if source.is_symlink():
        destination.symlink_to(os.readlink(source))
    elif source.is_dir():
        shutil.copytree(source, destination, symlinks=True)
    else:
        shutil.copy2(source, destination, follow_symlinks=False)


def remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink(missing_ok=True)
    elif path.is_dir():
        shutil.rmtree(path)


@dataclass(frozen=True)
class BackupRecord:
    target: str
    backup: str
    kind: str


class StateStore:
    """Persistent ownership and rollback state for one installation run."""

    def __init__(self, state_root: Path, backup_root: Path, run_id: str) -> None:
        self.state_root = state_root
        self.backup_root = backup_root
        self.run_id = run_id
        self.run_dir = state_root / "runs" / run_id
        self.path = self.run_dir / "state.json"
        self.active_path = state_root / "active.json"
        self.backup_dir = backup_root / run_id
        self.data = self._load_or_initialize()

    def _load_or_initialize(self) -> dict[str, Any]:
        if self.path.exists():
            payload = json.loads(self.path.read_text(encoding="utf-8"))
            if payload.get("schema_version") != SCHEMA_VERSION:
                raise RuntimeError(
                    f"unsupported installer state schema: {payload.get('schema_version')}"
                )
            return payload

        return {
            "schema_version": SCHEMA_VERSION,
            "run_id": self.run_id,
            "created_at": utc_now(),
            "updated_at": utc_now(),
            "status": "running",
            "profile": None,
            "theme": None,
            "completed_stages": [],
            "created_paths": [],
            "backups": [],
            "installed_packages": [],
            "enabled_services": [],
            "notes": [],
        }

    @classmethod
    def load_active(cls, state_root: Path, backup_root: Path) -> StateStore:
        active_path = state_root / "active.json"
        if not active_path.exists():
            raise FileNotFoundError("no active Arch WM installation state was found")
        active = json.loads(active_path.read_text(encoding="utf-8"))
        run_id = str(active["run_id"])
        return cls(state_root, backup_root, run_id)

    def save(self) -> None:
        self.data["updated_at"] = utc_now()
        atomic_write_json(self.path, self.data)
        atomic_write_json(
            self.active_path,
            {
                "schema_version": SCHEMA_VERSION,
                "run_id": self.run_id,
                "state_file": str(self.path),
                "updated_at": self.data["updated_at"],
            },
        )

    def set_metadata(self, *, profile: str, theme: str) -> None:
        self.data["profile"] = profile
        self.data["theme"] = theme
        self.save()

    def stage_complete(self, name: str) -> bool:
        return name in self.data["completed_stages"]

    def mark_stage_complete(self, name: str) -> None:
        if name not in self.data["completed_stages"]:
            self.data["completed_stages"].append(name)
            self.save()

    def mark_status(self, status: str) -> None:
        self.data["status"] = status
        self.save()

    def note(self, message: str) -> None:
        if message not in self.data["notes"]:
            self.data["notes"].append(message)
            self.save()

    def record_created_path(self, path: Path) -> None:
        value = str(path)
        if value not in self.data["created_paths"]:
            self.data["created_paths"].append(value)
            self.save()

    def record_installed_packages(self, packages: list[str]) -> None:
        changed = False
        for package in packages:
            if package not in self.data["installed_packages"]:
                self.data["installed_packages"].append(package)
                changed = True
        if changed:
            self.save()

    def record_enabled_service(self, service: str) -> None:
        if service not in self.data["enabled_services"]:
            self.data["enabled_services"].append(service)
            self.save()

    def backup_target(self, target: Path, *, dry_run: bool = False) -> BackupRecord | None:
        if not target.exists() and not target.is_symlink():
            return None

        for record in self.data["backups"]:
            if record["target"] == str(target):
                return BackupRecord(**record)

        safe_name = str(target).lstrip("/").replace("/", "__") or "root"
        backup = self.backup_dir / safe_name
        suffix = 1
        while backup.exists() or backup.is_symlink():
            backup = self.backup_dir / f"{safe_name}.{suffix}"
            suffix += 1

        kind = "symlink" if target.is_symlink() else "directory" if target.is_dir() else "file"
        record = BackupRecord(str(target), str(backup), kind)
        if not dry_run:
            copy_path(target, backup)
            self.data["backups"].append(record.__dict__)
            self.save()
        return record

    def restore(self, *, dry_run: bool = False) -> list[str]:
        actions: list[str] = []

        for raw in reversed(self.data.get("created_paths", [])):
            target = Path(raw)
            actions.append(f"remove {target}")
            if not dry_run:
                remove_path(target)

        for raw in reversed(self.data.get("backups", [])):
            record = BackupRecord(**raw)
            target = Path(record.target)
            backup = Path(record.backup)
            actions.append(f"restore {target} from {backup}")
            if not dry_run:
                remove_path(target)
                if backup.exists() or backup.is_symlink():
                    copy_path(backup, target)

        if not dry_run:
            self.data["status"] = "rolled-back"
            self.save()
        return actions
