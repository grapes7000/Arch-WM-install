pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Audio state comes straight from the PipeWire registry. Node properties only
// stay live while the node is bound, so every audio node this service reports
// is held by the tracker below.
Singleton {
    id: root

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    readonly property var audioNodes: {
        const nodes = Pipewire.nodes ? Pipewire.nodes.values : []
        const collected = []
        for (const node of nodes) {
            if (node && node.audio)
                collected.push(node)
        }
        return collected
    }

    readonly property var sinks: root.describe(node => node.isSink && !node.isStream, root.defaultSink)
    readonly property var sources: root.describe(node => !node.isSink && !node.isStream, root.defaultSource)
    readonly property var streams: root.describe(node => node.isStream, null)

    readonly property int volume: root.readVolume(root.defaultSink)
    readonly property bool muted: root.readMuted(root.defaultSink)
    readonly property int sourceVolume: root.readVolume(root.defaultSource)
    readonly property bool sourceMuted: root.readMuted(root.defaultSource)

    // A node reports zeroed audio until PipeWire finishes binding it, so gate
    // consumers on the default sink actually being bound rather than on the
    // registry merely existing.
    readonly property bool ready: !!(root.defaultSink && root.defaultSink.ready && root.defaultSink.audio)
    readonly property string error: {
        if (!Pipewire.ready)
            return "PipeWire registry unavailable"
        if (!root.defaultSink)
            return "No default audio sink"
        return ""
    }

    function readVolume(node) {
        if (!node || !node.audio)
            return 0
        return Math.max(0, Math.min(100, Math.round(node.audio.volume * 100)))
    }

    function readMuted(node) {
        return !!(node && node.audio && node.audio.muted)
    }

    function nodeLabel(node) {
        return String(node.description || node.nickname || node.name || ("node " + node.id))
    }

    function describe(predicate, defaultNode) {
        const rows = []
        for (const node of root.audioNodes) {
            if (!predicate(node))
                continue
            rows.push({
                id: node.id,
                name: root.nodeLabel(node),
                volume: root.readVolume(node),
                muted: root.readMuted(node),
                isDefault: !!defaultNode && node.id === defaultNode.id
            })
        }
        return rows
    }

    // Accepts a numeric PipeWire node id or the wpctl-style default aliases the
    // previous shell-based implementation took, so callers did not have to change.
    function resolveNode(id) {
        if (id === "@DEFAULT_AUDIO_SINK@" || id === "@DEFAULT_SINK@")
            return root.defaultSink
        if (id === "@DEFAULT_AUDIO_SOURCE@" || id === "@DEFAULT_SOURCE@")
            return root.defaultSource
        const numeric = Number(id)
        for (const node of root.audioNodes) {
            if (node.id === numeric)
                return node
        }
        return null
    }

    function applyVolume(id, percent) {
        const node = root.resolveNode(id)
        if (!node || !node.audio)
            return false
        node.audio.muted = false
        node.audio.volume = Math.max(0, Math.min(100, percent)) / 100
        return true
    }

    function applyMuteToggle(id) {
        const node = root.resolveNode(id)
        if (!node || !node.audio)
            return false
        node.audio.muted = !node.audio.muted
        return true
    }

    function setVolume(percent) { return root.applyVolume("@DEFAULT_AUDIO_SINK@", percent) }
    function setSinkVolume(id, percent) { return root.applyVolume(id, percent) }
    function setSourceVolume(id, percent) { return root.applyVolume(id, percent) }
    function setStreamVolume(id, percent) { return root.applyVolume(id, percent) }

    function adjustVolume(delta) {
        return root.applyVolume("@DEFAULT_AUDIO_SINK@", root.volume + delta)
    }

    function toggleMute() { return root.applyMuteToggle("@DEFAULT_AUDIO_SINK@") }
    function toggleSinkMute(id) { return root.applyMuteToggle(id) }
    function toggleSourceMute(id) { return root.applyMuteToggle(id) }
    function toggleStreamMute(id) { return root.applyMuteToggle(id) }

    function setDefaultSink(id) {
        const node = root.resolveNode(id)
        if (!node)
            return false
        Pipewire.preferredDefaultAudioSink = node
        return true
    }

    function setDefaultSource(id) {
        const node = root.resolveNode(id)
        if (!node)
            return false
        Pipewire.preferredDefaultAudioSource = node
        return true
    }

    // The registry is event driven, so there is nothing to poll. Kept so callers
    // written against the previous polling service keep working.
    function refresh() { return Pipewire.ready }

    PwObjectTracker {
        objects: root.audioNodes
    }
}
