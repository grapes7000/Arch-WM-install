import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../components" as Components
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
        spacing: context.variant === "compact" ? Core.UiStyle.spacingXs : Core.UiStyle.spacingSm

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact" && context.allows("media.control")
            text: Services.MprisService.canPrev ? "󰒮" : ""
            color: Core.Theme.muted
            font.pixelSize: Core.UiStyle.iconSize + 4

            MouseArea {
                id: prevArea
                anchors.fill: parent
                onClicked: Services.MprisService.previous()
            }

            Components.PressBounce { pressed: prevArea.pressed }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.allows("media.control")
            text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"
            color: Core.Theme.foreground
            font.pixelSize: context.variant === "compact" ? Core.UiStyle.iconSize + 4 : Core.UiStyle.iconSize + 7

            MouseArea {
                id: playPauseArea
                anchors.fill: parent
                onClicked: Services.MprisService.playPause()
            }

            Components.PressBounce { pressed: playPauseArea.pressed }
        }

        Text {
            font.family: Core.Theme.fontFamily
            visible: context.variant !== "compact" && context.allows("media.control")
            text: Services.MprisService.canNext ? "󰒭" : ""
            color: Core.Theme.muted
            font.pixelSize: Core.UiStyle.iconSize + 4

            MouseArea {
                id: nextArea
                anchors.fill: parent
                onClicked: Services.MprisService.next()
            }

            Components.PressBounce { pressed: nextArea.pressed }
        }

        Item {
            id: mediaLabelArea
            implicitWidth: mediaLabels.implicitWidth
            implicitHeight: mediaLabels.implicitHeight

            ColumnLayout {
                id: mediaLabels
                anchors.fill: parent
                spacing: 0

                Text {
                    font.family: Core.Theme.fontFamily
                    Layout.maximumWidth: context.variant === "compact" ? 120 : 200
                    text: Services.MprisService.title
                    color: Core.Theme.foreground
                    font.pixelSize: context.variant === "compact" ? Core.UiStyle.fontSecondary : Core.UiStyle.fontBody
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    font.family: Core.Theme.fontFamily
                    Layout.maximumWidth: context.variant === "compact" ? 120 : 200
                    visible: context.variant !== "compact"
                    text: Services.MprisService.artist
                    color: Core.Theme.muted
                    font.pixelSize: Core.UiStyle.fontSecondary
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: openMediaArea
                anchors.fill: parent
                enabled: context.allows("drawer.open")
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: context.request("drawer.open", { kind: "media" })
            }

            Components.PressBounce { target: mediaLabelArea; pressed: openMediaArea.pressed }
        }
    }
}
