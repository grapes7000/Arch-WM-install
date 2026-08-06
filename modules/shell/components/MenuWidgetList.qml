import QtQuick
import QtQuick.Layouts
import "../core" as Core

Item {
    id: listRoot

    signal widgetSelected(string widgetId, string widgetName)

    implicitHeight: listCol.implicitHeight

    readonly property var widgetIds: Object.keys(Core.WidgetRegistry.widgets)

    ColumnLayout {
        id: listCol
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 2

        Repeater {
            model: listRoot.widgetIds

            Rectangle {
                id: row
                required property string modelData
                readonly property var def: Core.WidgetRegistry.definition(modelData)
                readonly property bool hasPanel: def && def.panel === true
                Layout.fillWidth: true
                height: 36
                radius: Math.max(4, Core.Theme.radius / 2)
                color: rowMouse.containsMouse && hasPanel
                    ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: row.def ? row.def.name : row.modelData
                        color: row.hasPanel ? Core.Theme.foreground : Core.Theme.muted
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "›"
                        color: Core.Theme.muted
                        font.pixelSize: 16
                        visible: row.hasPanel
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: row.hasPanel ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: row.hasPanel
                    onClicked: listRoot.widgetSelected(row.modelData,
                        row.def ? row.def.name : row.modelData)
                }
            }
        }
    }
}
