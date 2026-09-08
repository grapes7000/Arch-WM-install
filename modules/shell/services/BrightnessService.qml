pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight control that needs no external helper binary.
//
// Reads come straight from sysfs, which supports change notification, so an
// external adjustment (hardware key, another tool, automatic dimming) is
// reflected immediately without polling. Writes go through logind's
// SetBrightness, which is permitted for the active session and therefore does
// not require root, a setuid helper, or brightnessctl to be installed.
Singleton {
    id: root

    readonly property string subsystem: "backlight"

    property string device: ""
    property int raw: -1
    property int maxRaw: -1
    property string error: ""

    readonly property bool available: root.device !== "" && root.maxRaw > 0
    readonly property int percent: root.available && root.raw >= 0 ? Math.max(0, Math.min(100, Math.round(root.raw / root.maxRaw * 100))) : -1

    // Never allow a fully dark panel; a user who cannot see the screen cannot
    // undo the change.
    readonly property int minimumPercent: 1

    function percentToRaw(value) {
        if (!root.available)
            return -1;
        const clamped = Math.max(root.minimumPercent, Math.min(100, Math.round(value)));
        return Math.max(1, Math.min(root.maxRaw, Math.round(clamped / 100 * root.maxRaw)));
    }

    function set(value) {
        const target = root.percentToRaw(value);
        if (target < 0)
            return false;
        if (target === root.raw)
            return true;
        writer.command = ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "SetBrightness", "ssu", root.subsystem, root.device, String(target)];
        writer.running = true;
        // Update optimistically so repeated key presses accumulate instead of
        // racing the sysfs notification.
        root.raw = target;
        return true;
    }

    function adjust(delta) {
        if (!root.available)
            return false;
        return root.set(root.percent + delta);
    }

    function refresh() {
        if (root.device !== "")
            currentFile.reload();
    }

    Process {
        id: discovery

        running: true
        command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.split("\n").map(line => line.trim()).filter(line => line.length > 0);
                if (names.length === 0) {
                    root.error = "No backlight device";
                    return;
                }
                // Prefer a real panel backlight over the ACPI video fallback,
                // which is frequently present but non-functional.
                const preferred = ["intel_backlight", "amdgpu_bl0", "amdgpu_bl1", "nvidia_wmi_ec_backlight"];
                let chosen = names.find(name => preferred.indexOf(name) !== -1);
                if (!chosen)
                    chosen = names.find(name => name !== "acpi_video0") || names[0];
                root.error = "";
                root.device = chosen;
            }
        }
    }

    FileView {
        id: maxFile

        path: root.device === "" ? "" : `/sys/class/backlight/${root.device}/max_brightness`
        onLoaded: {
            const value = parseInt(maxFile.text().trim(), 10);
            root.maxRaw = isNaN(value) ? -1 : value;
        }
        onLoadFailed: root.error = "Cannot read max_brightness"
    }

    FileView {
        id: currentFile

        path: root.device === "" ? "" : `/sys/class/backlight/${root.device}/brightness`
        watchChanges: true
        onFileChanged: currentFile.reload()
        onLoaded: {
            const value = parseInt(currentFile.text().trim(), 10);
            if (!isNaN(value))
                root.raw = value;
        }
        onLoadFailed: root.error = "Cannot read brightness"
    }

    Process {
        id: writer

        command: []
    }
}
