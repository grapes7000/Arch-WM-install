pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int volume: 0
    property bool muted: false
    property var sinks: []
    property var sources: []
    property var streams: []
    property string error: ""
    property string _operation: ""

    function clear() {
        volume = 0
        muted = false
        sinks = []
        sources = []
        streams = []
    }

    function parse(contents) {
        let section = ""
        let audioSection = false
        const parsed = { sinks: [], sources: [], streams: [] }
        for (const raw of contents.split("\n")) {
            const heading = raw.trim()
            if (heading === "Audio") {
                audioSection = true
                section = ""
                continue
            }
            if (heading === "Video" || heading === "Settings") {
                audioSection = false
                section = ""
                continue
            }
            const sectionMatch = audioSection ? heading.match(/(Sinks|Sources|Streams):$/) : null
            if (sectionMatch) {
                section = sectionMatch[1].toLowerCase()
                continue
            }
            if (!section) continue
            const match = raw.match(/^[^0-9*]*([*]?)\s*(\d+)\.\s+(.+?)\s+\[vol:\s*([0-9.]+)(?:\s+(MUTED))?\]\s*$/)
            if (!match) continue
            parsed[section].push({
                id: Number(match[2]),
                name: match[3].trim(),
                volume: Math.max(0, Math.min(100, Math.round(Number(match[4]) * 100))),
                muted: match[5] === "MUTED",
                isDefault: match[1] === "*"
            })
        }
        if (parsed.sinks.length === 0 && parsed.sources.length === 0 && parsed.streams.length === 0) {
            clear()
            error = "wpctl returned no audio devices"
            return false
        }
        sinks = parsed.sinks
        sources = parsed.sources
        streams = parsed.streams
        const defaultSink = parsed.sinks.find(row => row.isDefault) || parsed.sinks[0]
        volume = defaultSink ? defaultSink.volume : 0
        muted = defaultSink ? defaultSink.muted : false
        error = ""
        return true
    }

    function run(command, operation) {
        if (serviceProcess.running) return false
        _operation = operation
        serviceProcess.command = command
        serviceProcess.running = true
        watchdog.restart()
        return true
    }

    function refresh() { return run(["wpctl", "status", "-n"], "poll") }
    function setVolume(percent) { return setSinkVolume("@DEFAULT_AUDIO_SINK@", percent) }
    function setSinkVolume(id, percent) {
        return run(["wpctl", "set-volume", String(id), Math.max(0, Math.min(100, percent)) + "%"], "action")
    }
    function setSourceVolume(id, percent) {
        return run(["wpctl", "set-volume", String(id), Math.max(0, Math.min(100, percent)) + "%"], "action")
    }
    function setStreamVolume(id, percent) {
        return run(["wpctl", "set-volume", String(id), Math.max(0, Math.min(100, percent)) + "%"], "action")
    }
    function toggleMute() { return toggleSinkMute("@DEFAULT_AUDIO_SINK@") }
    function toggleSinkMute(id) { return run(["wpctl", "set-mute", String(id), "toggle"], "action") }
    function toggleSourceMute(id) { return run(["wpctl", "set-mute", String(id), "toggle"], "action") }
    function toggleStreamMute(id) { return run(["wpctl", "set-mute", String(id), "toggle"], "action") }
    function setDefaultSink(id) { return run(["wpctl", "set-default", String(id)], "action") }
    function setDefaultSource(id) { return run(["wpctl", "set-default", String(id)], "action") }

    Process {
        id: serviceProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._operation === "poll") root.parse(text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            const operation = root._operation
            root._operation = ""
            command = []
            if (exitCode !== 0) {
                root.clear()
                root.error = operation + " failed (exit " + exitCode + ")"
            } else if (operation === "action") {
                Qt.callLater(root.refresh)
            }
        }
    }

    Timer {
        id: watchdog
        interval: 15000
        onTriggered: {
            if (!serviceProcess.running) return
            serviceProcess.running = false
            root.clear()
            root.error = root._operation + " timed out"
            root._operation = ""
            serviceProcess.command = []
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
