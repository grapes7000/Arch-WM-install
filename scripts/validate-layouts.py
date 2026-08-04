#!/usr/bin/env python3
from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SHELL_ROOT = ROOT / "modules" / "shell"
LAYOUT_DIR = SHELL_ROOT / "layouts"
WIDGET_DIR = SHELL_ROOT / "widgets"
REGISTRY_PATH = SHELL_ROOT / "generated" / "widgets.json"
VALID_SURFACES = {"bar", "desktop", "lockscreen"}
VALID_VARIANTS = {"compact", "standard", "expanded"}
VALID_REGIONS = {
    "bar": {"start", "center", "end"},
    "desktop": {
        "background",
        "top_left",
        "top_right",
        "bottom_left",
        "bottom_right",
        "center",
    },
    "lockscreen": {"top", "center", "bottom"},
}
ID = re.compile(r"^[a-z0-9][a-z0-9-]*$")


def fail(message: str) -> None:
    print(f"layout validation error: {message}", file=sys.stderr)
    raise SystemExit(1)


def load(path: pathlib.Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"{path}: {error}")
    if not isinstance(value, dict):
        fail(f"{path}: root must be an object")
    return value


def validate_manifest(path: pathlib.Path) -> dict:
    value = load(path)
    required = (
        "id",
        "name",
        "entry",
        "surfaces",
        "variants",
        "lockSafe",
        "services",
        "capabilities",
    )
    for key in required:
        if key not in value:
            fail(f"{path}: missing {key!r}")
    widget_id = value["id"]
    if not isinstance(widget_id, str) or not ID.fullmatch(widget_id):
        fail(f"{path}: invalid widget id {widget_id!r}")
    if path.parent.name != widget_id:
        fail(f"{path}: directory and widget id disagree")
    entry = value["entry"]
    if not isinstance(entry, str) or "/" in entry or not entry.endswith(".qml"):
        fail(f"{path}: invalid entry component {entry!r}")
    if not (path.parent / entry).is_file():
        fail(f"{path}: entry component does not exist: {entry}")
    surfaces = value["surfaces"]
    variants = value["variants"]
    if not isinstance(surfaces, list) or not surfaces or set(surfaces) - VALID_SURFACES:
        fail(f"{path}: invalid surfaces {surfaces!r}")
    if not isinstance(variants, list) or not variants or set(variants) - VALID_VARIANTS:
        fail(f"{path}: invalid variants {variants!r}")
    if value["lockSafe"] and "lockscreen" not in surfaces:
        fail(f"{path}: lockSafe widgets must support the lockscreen surface")
    for key in ("services", "capabilities"):
        if not isinstance(value[key], list) or not all(isinstance(item, str) for item in value[key]):
            fail(f"{path}: {key} must be an array of strings")
    return value


def manifests() -> dict[str, dict]:
    result: dict[str, dict] = {}
    for path in sorted(WIDGET_DIR.glob("*/manifest.json")):
        value = validate_manifest(path)
        widget_id = value["id"]
        if widget_id in result:
            fail(f"duplicate widget id: {widget_id}")
        result[widget_id] = value
    if not result:
        fail(f"no widget manifests found beneath {WIDGET_DIR}")
    return result


def validate_registry(known: dict[str, dict]) -> None:
    registry = load(REGISTRY_PATH)
    values = registry.get("widgets")
    if registry.get("schema_version") != 1 or not isinstance(values, list):
        fail(f"{REGISTRY_PATH}: invalid registry root")
    registered: set[str] = set()
    for value in values:
        if not isinstance(value, dict) or not isinstance(value.get("id"), str):
            fail(f"{REGISTRY_PATH}: invalid widget definition")
        widget_id = value["id"]
        if widget_id in registered:
            fail(f"{REGISTRY_PATH}: duplicate widget id {widget_id!r}")
        if widget_id not in known:
            fail(f"{REGISTRY_PATH}: unknown widget {widget_id!r}")
        manifest = known[widget_id]
        for key in ("entry", "surfaces", "variants", "lockSafe", "services", "capabilities"):
            if value.get(key) != manifest.get(key):
                fail(f"{REGISTRY_PATH}: {widget_id}.{key} differs from its manifest")
        registered.add(widget_id)
    missing = set(known) - registered
    if missing:
        fail(f"{REGISTRY_PATH}: missing widgets {sorted(missing)}")


def validate_instance(path: pathlib.Path, surface: str, value: object, known: dict[str, dict]) -> str:
    if not isinstance(value, dict):
        fail(f"{path}: widget instance must be an object")
    for key in ("instance", "widget", "variant"):
        if not isinstance(value.get(key), str) or not value[key]:
            fail(f"{path}: instance requires non-empty string {key!r}")
    widget_id = value["widget"]
    if widget_id not in known:
        fail(f"{path}: unknown widget {widget_id!r}")
    manifest = known[widget_id]
    if surface not in manifest["surfaces"]:
        fail(f"{path}: widget {widget_id!r} does not support {surface}")
    if value["variant"] not in manifest["variants"]:
        fail(f"{path}: widget {widget_id!r} does not support variant {value['variant']!r}")
    if surface == "lockscreen" and not manifest["lockSafe"]:
        fail(f"{path}: widget {widget_id!r} is not lock-safe")
    settings = value.get("settings", {})
    if not isinstance(settings, dict):
        fail(f"{path}: settings must be an object")
    return value["instance"]


def validate_layout(path: pathlib.Path, known: dict[str, dict]) -> None:
    data = load(path)
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
            instance_id = validate_instance(path, surface, instance, known)
            if instance_id in seen:
                fail(f"{path}: duplicate instance id {instance_id!r}")
            seen.add(instance_id)


def main() -> None:
    known = manifests()
    validate_registry(known)
    paths = sorted(LAYOUT_DIR.glob("*.json"))
    if not paths:
        fail(f"no layouts found beneath {LAYOUT_DIR}")
    for path in paths:
        validate_layout(path, known)
        print(f"valid: {path.relative_to(ROOT)}")
    print(f"valid: {len(known)} widget manifests and generated registry")


if __name__ == "__main__":
    main()
