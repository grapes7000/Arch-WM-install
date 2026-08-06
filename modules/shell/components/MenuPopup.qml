import QtQuick
import QtQuick.Layouts
import Quickshell
import "../core" as Core

PopupWindow {
    id: popup

    property bool menuOpen: false
    property string currentWidget: ""
    property string currentWidgetName: ""

    visible: menuOpen
    anchor.window: popup.parent
    anchor.edges: Edges.Bottom | Edges.Right
    width: 320
    height: contentCol.implicitHeight + Core.Theme.gap * 2
    color: "transparent"

    function toggle() {
        if (menuOpen) {
            menuOpen = false
            currentWidget = ""
        } else {
            menuOpen = true
        }
    }

    onVisibleChanged: {
        if (!visible) {
            menuOpen = false
            currentWidget = ""
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Core.Theme.surface
        radius: Core.Theme.radius
        border.width: Core.Theme.borderWidth
        border.color: Core.Theme.accent2

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: Core.Theme.gap
            spacing: Core.Theme.gap

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "←"
                    color: Core.Theme.foreground
                    font.pixelSize: 16
                    visible: popup.currentWidget !== ""

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.currentWidget = ""
                            popup.currentWidgetName = ""
                        }
                    }
                }

                Text {
                    text: popup.currentWidget === "" ? "Widgets" : popup.currentWidgetName
                    color: Core.Theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Core.Theme.muted
                opacity: 0.3
            }

            MenuWidgetList {
                Layout.fillWidth: true
                visible: popup.currentWidget === ""
                onWidgetSelected: function(widgetId, widgetName) {
                    popup.currentWidget = widgetId
                    popup.currentWidgetName = widgetName
                }
            }

            Loader {
                id: panelLoader
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                active: popup.currentWidget !== ""
                visible: active
                source: active
                    ? Qt.resolvedUrl("../widgets/" + popup.currentWidget + "/Panel.qml")
                    : ""
                onStatusChanged: {
                    if (status === Loader.Error)
                        console.warn("Failed to load panel for", popup.currentWidget)
                }
            }
        }
    }
}
