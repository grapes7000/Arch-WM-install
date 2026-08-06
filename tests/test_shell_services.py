from __future__ import annotations

import json
import pathlib
import re
import subprocess
import unittest
from collections.abc import Mapping
from dataclasses import dataclass
from typing import Final


ROOT = pathlib.Path(__file__).resolve().parents[1]
SERVICES = ROOT / "modules" / "shell" / "services"
NODE_RUNNER: Final = r"""
const fs = require("fs");
const vm = require("vm");
const payload = JSON.parse(fs.readFileSync(0, "utf8"));
const context = { console: { log() {}, warn() {}, error() {} } };
Object.assign(context, payload.state);
context.root = context;
vm.createContext(context);
vm.runInContext(payload.functions.join("\n"), context);
const returned = vm.runInContext(
    payload.call + "(" + JSON.stringify(payload.input) + ")", context);
const state = {};
for (const key of payload.projection) state[key] = context[key];
process.stdout.write((returned ? "1" : "0") + "\n");
process.stdout.write((Boolean(context.error) ? "1" : "0") + "\n");
process.stdout.write((JSON.stringify(state).includes("stale") ? "1" : "0") + "\n");
"""

type JsonScalar = None | bool | int | float | str
type JsonValue = JsonScalar | list["JsonValue"] | dict[str, "JsonValue"]


@dataclass(frozen=True, slots=True)
class ParserRun:
    returned: bool
    has_error: bool
    has_stale: bool


def qml_function(source: str, name: str) -> str:
    match = re.search(rf"\bfunction\s+{re.escape(name)}\s*\([^)]*\)\s*\{{", source)
    if match is None:
        raise AssertionError(f"missing QML function: {name}")
    depth = 1
    quote = ""
    escaped = False
    index = match.end()
    while index < len(source) and depth:
        character = source[index]
        if escaped:
            escaped = False
        elif quote and character == "\\":
            escaped = True
        elif quote:
            if character == quote:
                quote = ""
        elif character in ('"', "'", "`"):
            quote = character
        elif character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
        index += 1
    if depth:
        raise AssertionError(f"unterminated QML function: {name}")
    return source[match.start() : index]


def run_qml_parser(
    source: str,
    function_names: tuple[str, ...],
    call: str,
    state: Mapping[str, JsonValue],
    malformed_input: str,
    projection: tuple[str, ...],
) -> ParserRun:
    payload = {
        "functions": [qml_function(source, name) for name in function_names],
        "call": call,
        "state": state,
        "input": malformed_input,
        "projection": projection,
    }
    completed = subprocess.run(
        ["node", "-e", NODE_RUNNER],
        input=json.dumps(payload),
        capture_output=True,
        check=True,
        text=True,
    )
    returned, has_error, has_stale = completed.stdout.splitlines()
    return ParserRun(
        returned=returned == "1",
        has_error=has_error == "1",
        has_stale=has_stale == "1",
    )


class ShellServiceContractTests(unittest.TestCase):
    def service(self, name: str) -> str:
        return (SERVICES / f"{name}Service.qml").read_text(encoding="utf-8")

    def test_each_shared_service_owns_one_process(self) -> None:
        for name in (
            "Audio",
            "Network",
            "SystemStats",
            "Notification",
            "Mpris",
            "Session",
            "Cava",
        ):
            processes = re.findall(r"^\s*Process\s*\{", self.service(name), re.MULTILINE)
            self.assertEqual(len(processes), 1, name)

    def test_service_contracts_are_exported(self) -> None:
        contracts = {
            "Audio": ("sinks", "sources", "streams", "setVolume", "toggleMute"),
            "Network": ("activeConnection", "accessPoints", "scan", "connectWifi"),
            "SystemStats": ("temperature", "topProcesses", "uptime"),
            "Notification": ("recent", "dndEnabled", "toggleDnd"),
            "Cava": ("available", "running", "bars"),
            "Session": ("pendingAction", "confirm", "error"),
        }
        for name, members in contracts.items():
            source = self.service(name)
            for member in members:
                self.assertRegex(source, rf"\b{re.escape(member)}\b", f"{name}.{member}")

        for qmldir in (SERVICES / "qmldir", ROOT / "modules" / "shell" / "qmldir"):
            self.assertIn("singleton CavaService 1.0", qmldir.read_text(encoding="utf-8"))

    def test_shell_packages_contain_single_dunst_and_cava(self) -> None:
        packages = [
            line.strip()
            for line in (ROOT / "manifests" / "packages-shell.txt").read_text().splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        self.assertEqual(packages.count("dunst"), 1)
        self.assertEqual(packages.count("cava"), 1)

    def test_wifi_password_is_not_interpolated_into_a_shell_command(self) -> None:
        source = self.service("Network")
        self.assertNotIn('"sh", "-c"', source)
        self.assertNotRegex(source, r"console\.(log|warn|error)[^\n]*(password|passphrase)")

    def test_malformed_parser_input_clears_seeded_state_and_sets_error(self) -> None:
        cases: dict[str, tuple[tuple[str, ...], str, dict[str, JsonValue], str, tuple[str, ...]]] = {
            "Audio": (("clear", "parse"), "parse", {"volume": 75, "muted": True, "sinks": [{"id": 1}], "sources": [], "streams": [], "error": ""}, "not wpctl", ("volume", "muted", "sinks", "error")),
            "Network": (("splitEscaped", "clearActive", "parseStatus"), "parseStatus", {"connected": True, "ssid": "stale", "type": "wifi", "strength": 80, "ipAddress": "stale", "security": "WPA2", "downloadRate": "1 KiB/s", "uploadRate": "1 KiB/s", "activeConnection": {"name": "stale"}, "error": ""}, "malformed", ("connected", "ssid", "activeConnection", "error")),
            "SystemStats": (("clear", "parse"), "parse", {"cpuPercent": 80, "memoryPercent": 70, "diskPercent": 60, "uptime": "stale", "temperature": 40, "topProcesses": [{"pid": 1}], "error": ""}, "cpu=12\nmemory=nope", ("cpuPercent", "uptime", "topProcesses", "error")),
            "Notification": (("clearHistory", "parseHistory"), "parseHistory", {"count": 1, "recent": [{"summary": "stale"}], "error": ""}, "{", ("count", "recent", "error")),
            "Mpris": (("clear", "parse"), "parse", {"title": "stale", "artist": "stale", "status": "Playing", "canNext": True, "canPrev": True, "error": ""}, "", ("title", "status", "canNext", "error")),
            "Cava": (("clear", "parse"), "parse", {"available": True, "bars": [0.5], "error": ""}, "bad;", ("available", "bars", "error")),
            "Tailscale": (("clear", "parse"), "parse", {"running": True, "connected": True, "tailnet": "stale", "exitNodeActive": True, "exitNodeName": "stale", "isMullvad": True, "mullvadLocation": "stale", "ipAddress": "stale", "peerCount": 2, "error": ""}, "{", ("running", "connected", "tailnet", "peerCount", "error")),
        }
        for name, (functions, call, seeded, malformed, projection) in cases.items():
            with self.subTest(service=name):
                result = run_qml_parser(
                    self.service(name), functions, call, seeded, malformed, projection
                )
                self.assertFalse(result.returned)
                self.assertTrue(result.has_error)
                self.assertFalse(result.has_stale)

    def test_failure_and_liveness_paths_are_bounded(self) -> None:
        bounded = ("Audio", "Network", "SystemStats", "Notification", "Mpris", "Session", "Tailscale")
        for name in bounded:
            source = self.service(name)
            self.assertIn("onExited:", source, name)
            self.assertIn("interval: 15000", source, name)
            self.assertRegex(source, r"running\s*=\s*false", name)
        cava = self.service("Cava")
        self.assertIn("onExited:", cava)
        self.assertIn("restartTimer.restart()", cava)
        self.assertIn("interval: 10000", cava)

    def test_session_dangerous_actions_have_four_second_confirmation(self) -> None:
        source = self.service("Session")
        self.assertIn("interval: 4000", source)
        for action in ("logout", "suspend", "reboot", "poweroff"):
            self.assertIn(f'return confirm("{action}")', source)
        self.assertNotIn('return confirm("lock")', source)

    def test_cava_config_is_bounded_to_24_ascii_bars(self) -> None:
        config = (SERVICES / "cava.conf").read_text(encoding="utf-8")
        self.assertIn("bars = 24", config)
        self.assertIn("data_format = ascii", config)
        self.assertIn("ascii_max_range = 1000", config)


if __name__ == "__main__":
    _ = unittest.main()
