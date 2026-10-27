import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    property date now: new Date()
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation
    Layout.minimumWidth: 112
    Layout.preferredWidth: 130
    Layout.minimumHeight: 24
    implicitWidth: 130
    implicitHeight: 25
    Timer { interval: 1000; repeat: true; running: true; onTriggered: root.now = new Date() }
    compactRepresentation: Rectangle {
        color: "#bfbfbf"
        border.color: "#333333"
        border.width: 1
        implicitWidth: 130
        implicitHeight: 25
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
        Text {
            id: clockText
            anchors.centerIn: parent
            text: Qt.formatTime(root.now, "h:mm:ss ap")
            color: "#080808"
            font.family: "More Perfect DOS VGA"
            font.pixelSize: 19
        }
    }
    fullRepresentation: ColumnLayout {
        implicitWidth: 300
        implicitHeight: 290
        property int shownMonth: root.now.getMonth()
        property int shownYear: root.now.getFullYear()
        function moveMonth(delta) {
            const date = new Date(shownYear, shownMonth + delta, 1)
            shownMonth = date.getMonth(); shownYear = date.getFullYear()
        }
        RowLayout {
            ToolButton { text: "‹"; onClicked: parent.parent.moveMonth(-1) }
            Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(new Date(parent.parent.shownYear, parent.parent.shownMonth, 1), "MMMM yyyy") }
            ToolButton { text: "›"; onClicked: parent.parent.moveMonth(1) }
        }
        MonthGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            month: parent.shownMonth
            year: parent.shownYear
        }
    }
}
