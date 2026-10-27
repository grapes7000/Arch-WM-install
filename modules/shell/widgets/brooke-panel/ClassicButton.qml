import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../../core" as Core
Rectangle {
    id: root
    property string label: ""
    property string icon: ""
    property bool selected: false
    property bool available: true
    signal clicked()
    implicitWidth: 32
    implicitHeight: 32
    color: selected || mouse.pressed ? Core.Theme.selected : "#bfbfbf"
    opacity: available ? 1 : 0.45
    border.width: 1
    border.color: "#111111"
    Rectangle { x: 1; y: 1; width: parent.width - 2; height: 1; color: mouse.pressed ? "#555555" : "#ffffff" }
    Rectangle { x: 1; y: 1; width: 1; height: parent.height - 2; color: mouse.pressed ? "#555555" : "#ffffff" }
    IconImage {
        anchors.centerIn: parent
        width: Math.min(26, parent.width - 4); height: width
        visible: root.icon !== ""
        source: root.icon.startsWith("file:") ? root.icon : Quickshell.iconPath(root.icon, true)
    }
    Text { anchors.centerIn: parent; visible: root.icon === ""; text: root.label; color: "#080808"; font.pixelSize: root.label.length > 3 ? 14 : 20 }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.available) root.clicked() }
    ToolTip.visible: mouse.containsMouse && root.label !== ""
    ToolTip.text: root.label + (root.available ? "" : " — not available in this setup")
}
