import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../components" as Components

Item {
    id: root

    required property string icon
    required property string label
    property bool active: false

    signal activated()

    implicitWidth: 72
    implicitHeight: 52
    activeFocusOnTab: true

    function activate() {
        root.activated()
    }

    Keys.onReturnPressed: root.activate()
    Keys.onEnterPressed: root.activate()
    Keys.onSpacePressed: root.activate()

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.centerIn: parent
                width: 38
                height: 32
                radius: Math.max(8, Core.Theme.radius)
                color: root.active
                    ? Core.Theme.alphaColor(Core.Theme.accent, 0.14)
                    : Core.Theme.alphaColor(Core.Theme.surfaceHover, toggleHover.hovered ? 0.42 : 0.0)
                border.width: root.active || root.activeFocus ? Core.Theme.borderWidth : 0
                border.color: Core.Theme.alphaColor(Core.Theme.accent, root.activeFocus ? 0.78 : 0.36)

                Behavior on color {
                    ColorAnimation {
                        duration: Math.round(Core.Theme.animationMs * Core.Theme.motionScale)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: root.active ? Core.Theme.accent : Core.Theme.muted
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: Core.Theme.shellFontSize + 5
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            color: root.active ? Core.Theme.foreground : Core.Theme.muted
            font.family: Core.Theme.fontFamily
            font.pixelSize: Core.Theme.shellFontSize
            font.bold: root.active
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.active ? 28 : 0
            Layout.preferredHeight: 2
            radius: 1
            color: Core.Theme.accent
            opacity: root.active ? 1 : 0

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Math.round(Core.Theme.homepageTransitionMs * Core.Theme.motionScale)
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Math.round(Core.Theme.animationMs * Core.Theme.motionScale)
                }
            }
        }
    }

    HoverHandler {
        id: toggleHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: toggleTap
        onTapped: root.activate()
    }

    Components.PressBounce {
        target: root
        pressed: toggleTap.pressed
    }
}
