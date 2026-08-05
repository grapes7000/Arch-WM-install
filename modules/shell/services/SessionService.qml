pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function lock() { actionProc.command = ["loginctl", "lock-session"]; actionProc.running = true }
    function logout() { actionProc.command = ["hyprctl", "dispatch", "exit"]; actionProc.running = true }
    function suspend() { actionProc.command = ["systemctl", "suspend"]; actionProc.running = true }
    function reboot() { actionProc.command = ["systemctl", "reboot"]; actionProc.running = true }
    function poweroff() { actionProc.command = ["systemctl", "poweroff"]; actionProc.running = true }

    Process { id: actionProc }
}
