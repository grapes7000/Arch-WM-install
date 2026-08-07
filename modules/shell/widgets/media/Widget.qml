import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

Item {
    id: root

    property var context: ({
        variant: "standard",
        settings: ({}),
        locked: false,
        allows: function() { return false }
    })

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    visible: Services.MprisService.status !== "Stopped"

    MouseArea { anchors.fill: parent; z: 10; enabled: context.allows("drawer.open"); cursorShape: Qt.PointingHandCursor; onClicked: context.request("drawer.open", { kind: "audio", anchorItem: root }) }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: context.variant === "compact" ? 4 : 8

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact" && context.allows("media.control")
            text: Services.MprisService.canPrev ? "󰒮" : ""
            color: Core.Theme.muted
            font.pixelSize: 16

            MouseArea {
                anchors.fill: parent
                onClicked: Services.MprisService.previous()
            }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.allows("media.control")
            text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"
            color: Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? 16 : 20

            MouseArea {
                anchors.fill: parent
                onClicked: Services.MprisService.playPause()
            }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact" && context.allows("media.control")
            text: Services.MprisService.canNext ? "󰒭" : ""
            color: Core.Theme.muted
            font.pixelSize: 16

            MouseArea {
                anchors.fill: parent
                onClicked: Services.MprisService.next()
            }
        }

        ColumnLayout {
            spacing: 0

            MouseArea {
                anchors.fill: parent
                enabled: context.allows("drawer.open")
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: context.request("drawer.open", { kind: "media" })
            }

            Text {
                font.family: Core.Theme.fontFamily
                Layout.maximumWidth: context.variant === "compact" ? 120 : 200
                text: Services.MprisService.title
                color: Core.Theme.foreground
                font.pixelSize: context.variant === "compact" ? 11 : 13
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                font.family: Core.Theme.fontFamily
                Layout.maximumWidth: context.variant === "compact" ? 120 : 200
                visible: context.variant !== "compact"
                text: Services.MprisService.artist
                color: Core.Theme.muted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
}

