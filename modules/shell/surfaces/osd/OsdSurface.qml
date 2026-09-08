import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core" as Core
import "../../services" as Services

// Transient on-screen display for volume and brightness.
//
// The OSD reacts to the underlying value changing rather than to the key press
// that caused it, so it appears for hardware keys, the bar widgets, and any
// external tool alike without those paths needing to know the OSD exists.
Scope {
    id: osdScope

    property string kind: ""
    property int value: 0
    property bool muted: false

    // Value changes that happen while the shell is starting up, or while
    // PipeWire is still binding, are not user actions and must not flash the
    // OSD on login.
    property bool armed: false

    readonly property int visibleMs: 1400

    function show(nextKind, nextValue, nextMuted) {
        if (!osdScope.armed || Services.LockStateService.locked)
            return false;
        // Value and mute state are assigned before the kind so that anything
        // reacting to the OSD becoming visible never renders a frame carrying
        // the previous reading, which is otherwise visible during the fade in.
        osdScope.value = nextValue;
        osdScope.muted = !!nextMuted;
        osdScope.kind = nextKind;
        hideTimer.restart();
        return true;
    }

    function hide() {
        osdScope.kind = "";
        hideTimer.stop();
        return true;
    }

    Timer {
        id: armTimer

        running: true
        interval: 1200
        onTriggered: osdScope.armed = true
    }

    Timer {
        id: hideTimer

        interval: osdScope.visibleMs
        onTriggered: osdScope.kind = ""
    }

    Connections {
        target: Services.AudioService

        function onVolumeChanged() {
            if (Services.AudioService.ready)
                osdScope.show("volume", Services.AudioService.volume, Services.AudioService.muted);
        }

        function onMutedChanged() {
            if (Services.AudioService.ready)
                osdScope.show("volume", Services.AudioService.volume, Services.AudioService.muted);
        }
    }

    Connections {
        target: Services.BrightnessService

        function onPercentChanged() {
            if (Services.BrightnessService.available)
                osdScope.show("brightness", Services.BrightnessService.percent, false);
        }
    }

    Binding {
        target: Core.InteractiveShellController
        property: "osdController"
        value: osdScope
        restoreMode: Binding.RestoreBindingOrValue
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData

            readonly property bool active: osdScope.kind !== "" && !Services.LockStateService.locked

            screen: modelData

            anchors {
                bottom: true
                left: true
                right: true
            }
            margins.bottom: Math.round(window.screen ? window.screen.height * 0.12 : 120)

            implicitHeight: 96
            color: "transparent"
            // An OSD must never steal input; it is purely informational and
            // appears while the user is typing or gaming.
            focusable: false
            exclusionMode: ExclusionMode.Ignore
            visible: window.active || card.opacity > 0
            mask: Region {}

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "arch-wm:osd"

            Rectangle {
                id: card

                anchors.centerIn: parent
                width: 260
                height: 72
                radius: Core.UiStyle.radiusOverlay + 6
                color: Core.Theme.alphaColor(Core.Theme.surface, 0.88)
                border.width: 1
                border.color: Core.Theme.alphaColor(Core.Theme.barOutlineColor, 0.45)

                opacity: window.active ? 1 : 0
                scale: window.active ? 1 : 0.94

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 170
                        easing.type: Easing.OutBack
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Core.UiStyle.spacingLg
                    spacing: Core.UiStyle.spacingMd

                    Text {
                        Layout.preferredWidth: 28
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.UiStyle.iconSize + 10
                        color: osdScope.muted && osdScope.kind === "volume" ? Core.Theme.muted : Core.Theme.foreground
                        text: {
                            if (osdScope.kind === "brightness") {
                                if (osdScope.value >= 66)
                                    return "󰃠";
                                if (osdScope.value >= 33)
                                    return "󰃞";
                                return "󰃝";
                            }
                            if (osdScope.muted)
                                return "󰝟";
                            if (osdScope.value >= 66)
                                return "󰕾";
                            if (osdScope.value >= 33)
                                return "󰖀";
                            return "󰕿";
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Core.UiStyle.spacingXs

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: osdScope.kind === "brightness" ? "Brightness" : (osdScope.muted ? "Muted" : "Volume")
                                color: Core.Theme.muted
                                font.family: Core.Theme.fontFamily
                                font.pixelSize: Core.UiStyle.fontCaption
                                font.bold: true
                            }

                            Text {
                                text: osdScope.value + "%"
                                color: Core.Theme.foreground
                                font.family: Core.Theme.fontFamily
                                font.pixelSize: Core.UiStyle.fontCaption
                                font.bold: true
                            }
                        }

                        Rectangle {
                            id: track

                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.7)

                            Rectangle {
                                width: Math.max(0, Math.min(1, osdScope.value / 100)) * track.width
                                height: track.height
                                radius: track.radius
                                color: osdScope.muted && osdScope.kind === "volume" ? Core.Theme.muted : Core.Theme.accent

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 120
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
