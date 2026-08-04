#!/usr/bin/env python3
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
LAYOUT_DIR = ROOT / "modules" / "shell" / "layouts"
VALID_SURFACES = {"bar", "desktop", "lockscreen"}
VALID_REGIONS = {
    "bar": {"start", "center", "end"},
    "desktop": {"background", "top_left", "top_right", "bottom_left", "bottom_right", "center"},
    "lockscreen": {"top", "center", "bottom"},
}


def fail(message: str) -> None:
    print(f"layout validation error: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_instance(path: pathlib.Path, value: object) -> None:
    if not isinstance(value, dict):
        fail(f"{path}: widget instance must be an object")
    for key in ("instance", "widget", "variant"):
        if not isinstance(value.get(key), str) or not value[key]:
            fail(f"{path}: instance requires non-empty string {key!r}")


def validate(path: pathlib.Path) -> None:
    data = json.loads(path.read_text())
    surface = data.get("surface")
    if surface not in VALID_SURFACES:
        fail(f"{path}: invalid surface {surface!r}")
    regions = data.get("regions")
    if not isinstance(regions, dict):
        fail(f"{path}: regions must be an object")
    unknown = set(regions) - VALID_REGIONS[surface]
    if unknown:
        fail(f"{path}: unsupported regions for {surface}: {sorted(unknown)}")
    seen: set[str] = set()
    for region, instances in regions.items():
        if not isinstance(instances, list):
            fail(f"{path}: region {region!r} must be an array")
        for instance in instances:
            validate_instance(path, instance)
            instance_id = instance["instance"]
            if instance_id in seen:
                fail(f"{path}: duplicate instance id {instance_id!r}")
            seen.add(instance_id)


def main() -> None:
    paths = sorted(LAYOUT_DIR.glob("*.json"))
    if not paths:
        fail(f"no layouts found beneath {LAYOUT_DIR}")
    for path in paths:
        validate(path)
        print(f"valid: {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
