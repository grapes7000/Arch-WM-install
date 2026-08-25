from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


class ProfileError(RuntimeError):
    pass


@dataclass(frozen=True)
class ConfigMap:
    source: str
    target: str


@dataclass(frozen=True)
class ProfileSpec:
    id: str
    name: str
    repository: str
    ref: str
    kind: str
    runtime: dict[str, Any]
    config: tuple[ConfigMap, ...]
    official_packages: tuple[str, ...] = ()
    package_files: tuple[str, ...] = ()
    aur_packages: tuple[str, ...] = ()
    aur_package_files: tuple[str, ...] = ()
    protected: tuple[str, ...] = ()
    capabilities: tuple[str, ...] = ()
    notes: tuple[str, ...] = ()
    monitor_adapter: str | None = None
    risk_policy: str = "curated"

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "ProfileSpec":
        required = ("id", "name", "repository", "ref", "kind", "runtime", "config")
        missing = [key for key in required if key not in data]
        if missing:
            raise ProfileError("profile missing required fields: " + ", ".join(missing))
        maps = tuple(ConfigMap(str(item["source"]), str(item["target"])) for item in data["config"])
        for mapping in maps:
            target = Path(mapping.target)
            if target.is_absolute() or ".." in target.parts or len(target.parts) != 1:
                raise ProfileError(f"unsafe config target in profile: {mapping.target!r}")
        return cls(
            id=str(data["id"]),
            name=str(data["name"]),
            repository=str(data["repository"]),
            ref=str(data["ref"]),
            kind=str(data["kind"]),
            runtime=dict(data["runtime"]),
            config=maps,
            official_packages=tuple(map(str, data.get("official_packages", []))),
            package_files=tuple(map(str, data.get("package_files", []))),
            aur_packages=tuple(map(str, data.get("aur_packages", []))),
            aur_package_files=tuple(map(str, data.get("aur_package_files", []))),
            protected=tuple(map(str, data.get("protected", []))),
            capabilities=tuple(map(str, data.get("capabilities", []))),
            notes=tuple(map(str, data.get("notes", []))),
            monitor_adapter=data.get("monitor_adapter"),
            risk_policy=str(data.get("risk_policy", "curated")),
        )


def load_profile(path: Path) -> ProfileSpec:
    return ProfileSpec.from_dict(json.loads(path.read_text(encoding="utf-8")))
