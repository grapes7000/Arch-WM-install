from __future__ import annotations

import json
import os
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable

TEXT_SUFFIXES = {
    ".sh", ".bash", ".zsh", ".fish", ".py", ".lua", ".qml", ".js", ".ts",
    ".json", ".toml", ".yaml", ".yml", ".conf", ".ini", ".service", ".desktop",
    ".rules", ".hook", ".install", ".md", ".txt", ".xml", ".css", ".scss",
}
TEXT_NAMES = {"PKGBUILD", "Makefile", "meson.build", "CMakeLists.txt", "AGENTS.md"}

# Commands that are dangerous regardless of where their arguments point.
BLOCK_PATTERNS: tuple[tuple[str, str], ...] = (
    ("boot_or_initramfs", r"\b(?:mkinitcpio|grub-install|bootctl)\b"),
    ("kernel_or_driver", r"\b(?:modprobe|dracut)\b|\b(?:pacman|yay|paru)\b[^\n]*(?:nvidia(?:-dkms|-open)?|amdgpu)"),
    ("destructive_disk", r"(?:\bmkfs(?:\.|\s)|\bfdisk\b|\bparted\b|\bdd\s+if=)"),
    ("display_manager", r"\bsystemctl\s+(?:enable|disable|mask|unmask)\b[^\n]*\bsddm\b"),
)

# Merely reading these paths can be legitimate (for example checking that a
# PAM service exists before launching a lock screen). They become hard blockers
# only when the same line also looks mutating.
SENSITIVE_PATHS: tuple[tuple[str, str], ...] = (
    ("pam", r"/etc/pam\.d(?:/|\b)"),
    ("sudoers", r"(?:/etc/sudoers(?:\.d/|\b))"),
    ("pacman_trust", r"(?:/etc/pacman\.conf\b|/etc/pacman\.d/(?:gnupg|mirrorlist)\b)"),
    ("display_manager", r"(?:/etc/sddm(?:\.conf|\.conf\.d/|/)|/usr/share/sddm/themes/)"),
    ("boot_files", r"/boot/"),
)

MUTATING_CONTEXT = re.compile(
    r"(?:"
    r"\b(?:cp|mv|install|tee|rm|ln|touch|chmod|chown|truncate)\b"
    r"|\bsed\b[^\n]*\s-i(?:\b|['\"]?)"
    r"|\b(?:write_text|write_bytes|unlink|remove|rename|replace)\s*\("
    r"|(?:^|[^<])>>?\s*['\"]?/"
    r")",
    re.IGNORECASE,
)

WARN_PATTERNS: tuple[tuple[str, str], ...] = (
    ("sudo", r"\bsudo\b"),
    ("system_service", r"\bsystemctl\s+(?:enable|disable|mask|unmask|start|stop)\b"),
    ("package_install", r"\b(?:pacman\s+-S|yay\s+-S|paru\s+-S|makepkg\s+-si)\b"),
    ("recursive_delete", r"\brm\s+-rf\b"),
    ("ownership_change", r"\b(?:chown|chmod)\s+-R\b"),
    ("remote_pipe_shell", r"(?:curl|wget)[^\n|]*\|\s*(?:sudo\s+)?(?:bash|sh)\b"),
    ("global_usr_local", r"/usr/local/(?:bin|lib|share)/"),
    ("systemd_global", r"/etc/systemd/system/"),
    ("polkit", r"(?:/usr/share/polkit-1|/etc/polkit-1)"),
    ("udev", r"/etc/udev/rules\.d/"),
    ("network_listener", r"(?:python(?:3)?\s+-m\s+http\.server|nc\s+-l\b|cloudflared\s+tunnel|\blisten\()"),
    ("notification_owner", r"org\.freedesktop\.Notifications"),
    ("session_lock", r"(?:ext-session-lock-v1|hyprlock|loginctl\s+lock-session)"),
)

PROTECTED_PATTERNS: tuple[tuple[str, str], ...] = (
    ("kitty", r"(?:^|/)\.config/kitty(?:/|$)|(?:^|/)config/kitty(?:/|$)"),
    ("starship", r"(?:^|/)\.config/starship\.toml$|(?:^|/)config/starship\.toml$"),
    ("nvim", r"(?:^|/)\.config/nvim(?:/|$)|(?:^|/)config/nvim(?:/|$)"),
    ("ssh", r"(?:^|/)\.ssh(?:/|$)"),
    ("shell_rc", r"(?:^|/)\.(?:zshrc|bashrc|profile|zshenv)$"),
)


@dataclass(frozen=True)
class Finding:
    severity: str
    category: str
    path: str
    line: int
    evidence: str


def _is_text(path: Path) -> bool:
    return path.suffix.lower() in TEXT_SUFFIXES or path.name in TEXT_NAMES


def _safe_evidence(line: str, limit: int = 220) -> str:
    value = line.strip().replace("\t", " ")
    return value[:limit] + ("…" if len(value) > limit else "")


def _scan_lines(relative: str, lines: Iterable[str]) -> list[Finding]:
    findings: list[Finding] = []
    protected_hit = [name for name, rx in PROTECTED_PATTERNS if re.search(rx, relative)]
    if protected_hit:
        findings.append(Finding("warn", "protected_config", relative, 0, ", ".join(protected_hit)))

    for number, line in enumerate(lines, 1):
        stripped = line.lstrip()
        if stripped.startswith(("#", "--", "//")):
            continue

        evidence = _safe_evidence(line)
        for name, rx in BLOCK_PATTERNS:
            if re.search(rx, line, re.IGNORECASE):
                findings.append(Finding("block", name, relative, number, evidence))

        for name, rx in SENSITIVE_PATHS:
            if re.search(rx, line, re.IGNORECASE):
                severity = "block" if MUTATING_CONTEXT.search(line) else "warn"
                category = name if severity == "block" else f"sensitive_reference:{name}"
                findings.append(Finding(severity, category, relative, number, evidence))

        for name, rx in WARN_PATTERNS:
            if re.search(rx, line, re.IGNORECASE):
                findings.append(Finding("warn", name, relative, number, evidence))
    return findings


def scan_tree(root: Path, *, max_file_bytes: int = 2_000_000) -> dict:
    root = root.resolve()
    findings: list[Finding] = []
    scanned_files = 0
    skipped_files = 0
    symlinks = 0

    for path in sorted(root.rglob("*")):
        try:
            relative = path.relative_to(root).as_posix()
        except ValueError:
            continue
        if relative.startswith(".git/") or relative == ".git":
            continue
        if path.is_symlink():
            symlinks += 1
            target = (path.parent / os.readlink(path)).resolve()
            try:
                target.relative_to(root)
            except ValueError:
                findings.append(Finding("block", "symlink_escape", relative, 0, os.readlink(path)))
            continue
        if not path.is_file():
            continue
        if path.stat().st_size > max_file_bytes or not _is_text(path):
            skipped_files += 1
            continue
        scanned_files += 1
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            skipped_files += 1
            continue
        findings.extend(_scan_lines(relative, text.splitlines()))

    blocks = sum(item.severity == "block" for item in findings)
    warnings = sum(item.severity == "warn" for item in findings)
    risk = min(100, blocks * 35 + warnings * 3)
    return {
        "version": 1,
        "root": str(root),
        "scanned_files": scanned_files,
        "skipped_files": skipped_files,
        "symlinks": symlinks,
        "blockers": blocks,
        "warnings": warnings,
        "risk_score": risk,
        "verdict": "blocked" if blocks else ("review" if warnings else "pass"),
        "findings": [asdict(item) for item in findings],
    }


def dumps(report: dict) -> str:
    return json.dumps(report, indent=2, sort_keys=True)
