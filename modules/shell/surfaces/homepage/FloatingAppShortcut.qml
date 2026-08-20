import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../core" as Core
import "../../components" as Components

Item {
    id: root

    required property string label
    property string iconName: ""
    property string fallbackIcon: "󰀻"

    signal activated()

    implicitWidth: 76
    implicitHeight: 76
    activeFocusOnTab: true
    scale: shortcutHover.hovered ? 1.06 : 1.0

    function activate() {
        root.activated()
    }

    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()
    Keys.onSpacePressed: root.activate()

    Behavior on scale {
        NumberAnimation {
            duration: Math.round(Core.Theme.animationMs * Core.Theme.motionScale)
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 3

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 52
            Layout.preferredHeight: 50

            Rectangle {
                anchors.centerIn: parent
                width: 48
                height: 48
                radius: Math.max(12, Core.Theme.radius + 2)
                color: shortcutHover.hovered || root.activeFocus
                    ? Core.Theme.alphaColor(Core.Theme.surfaceElevated, 0.76)
                    : "transparent"
                border.width: shortcutHover.hovered || root.activeFocus ? Core.Theme.borderWidth : 0
                border.color: Core.Theme.alphaColor(Core.Theme.accent, root.activeFocus ? 0.82 : 0.42)

                Behavior on color {
                    ColorAnimation {
                        duration: Math.round(Core.Theme.animationMs * Core.Theme.motionScale)
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    visible: root.iconName.length > 0
                    implicitSize: 38
                    source: visible ? Quickshell.iconPath(root.iconName, "") : ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.iconName.length === 0
                    text: root.fallbackIcon
                    color: Core.Theme.accent
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.shellFontSize + 13
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            color: shortcutHover.hovered || root.activeFocus
                ? Core.Theme.foreground : Core.Theme.muted
            font.family: Core.Theme.fontFamily
            font.pixelSize: Math.max(9, Core.Theme.shellFontSize - 1)
            font.bold: shortcutHover.hovered || root.activeFocus
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    HoverHandler {
        id: shortcutHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: shortcutTap
        onTapped: root.activate()
    }

    Components.PressBounce {
        target: root
        pressed: shortcutTap.pressed
    }
}
