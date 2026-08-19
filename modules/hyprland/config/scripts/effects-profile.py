#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

VALID = {"performance", "balanced", "cinematic"}


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1].lower() not in VALID:
        print("usage: effects-profile.py performance|balanced|cinematic")
        return 2

    profile = sys.argv[1].lower()
    home = Path.home()
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    target = config_home / "hypr" / "effects-profile"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(profile + "\n", encoding="utf-8")

    try:
        subprocess.run(["hyprctl", "reload"], check=False)
    except FileNotFoundError:
        pass

    print(f"Hyprland effects profile: {profile}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
