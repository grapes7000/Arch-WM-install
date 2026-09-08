import QtQuick
import QtQuick.Layouts
import Quickshell
import "../core" as Core

// Renders a StatusNotifierItem's D-Bus menu.
//
// Submenus are drilled into in place rather than opened as nested popup
// windows. Nested layer-shell popups are fragile and can end up positioned off
// screen, and an in-place stack also keeps keyboard and pointer grabs in a
// single surface.
PopupWindow {
    id: menu

    property var trayItem: null
    property var anchorItem: null
    property bool openUpwards: Core.Theme.barPosition === "bottom"

    // Stack of menu handles. Index 0 is the item's root menu; deeper entries
    // are submenus the user drilled into.
    property var handleStack: []
    property string titleText: ""
    property var titleStack: []

    readonly property var currentHandle: menu.handleStack.length > 0 ? menu.handleStack[menu.handleStack.length - 1] : null
    readonly property bool nested: menu.handleStack.length > 1

    readonly property color insetFill: Core.Theme.alphaColor(Core.Theme.surfaceHover, Core.UiStyle.flatSurfaces ? 0.34 : 0.58)
    readonly property color insetBorder: Core.Theme.alphaColor(Core.Theme.barOutlineColor, Core.UiStyle.flatSurfaces ? 0.34 : 0.56)

    readonly property int rowHeight: Math.max(Core.UiStyle.controlHeight, 28)
    readonly property int menuPadding: Core.UiStyle.spacingSm

    signal dismissed

    function openFor(item, anchor) {
        if (!item || !item.hasMenu || !item.menu)
            return false;
        menu.trayItem = item;
        menu.anchorItem = anchor || menu.anchorItem;
        menu.titleText = item.tooltipTitle || item.title || item.id || "";
        menu.titleStack = [];
        menu.handleStack = [item.menu];
        menu.visible = true;
        return true;
    }

    function close() {
        menu.visible = false;
        menu.handleStack = [];
        menu.titleStack = [];
        menu.trayItem = null;
        menu.dismissed();
    }

    function descend(entry) {
        if (!entry || !entry.hasChildren)
            return;
        const stack = menu.handleStack.slice();
        stack.push(entry);
        const titles = menu.titleStack.slice();
        titles.push(menu.titleText);
        menu.titleStack = titles;
        menu.titleText = String(entry.text || "").replace(/_/g, "");
        menu.handleStack = stack;
    }

    function ascend() {
        if (menu.handleStack.length <= 1)
            return;
        const stack = menu.handleStack.slice();
        stack.pop();
        const titles = menu.titleStack.slice();
        const previous = titles.pop();
        menu.titleStack = titles;
        menu.titleText = previous === undefined ? "" : previous;
        menu.handleStack = stack;
    }

    function trigger(entry) {
        if (!entry || !entry.enabled)
            return;
        if (entry.hasChildren) {
            menu.descend(entry);
            return;
        }
        entry.triggered();
        menu.close();
    }

    visible: false
    color: "transparent"
    // The popup must take focus so that clicking elsewhere dismisses it, but it
    // is closed on deactivation so it can never trap input.
    grabFocus: true

    implicitWidth: Math.max(180, Math.min(360, card.implicitWidth))
    implicitHeight: card.implicitHeight

    anchor {
        item: menu.anchorItem
        edges: menu.openUpwards ? Edges.Top : Edges.Bottom
        gravity: menu.openUpwards ? Edges.Top : Edges.Bottom
        margins {
            top: menu.openUpwards ? 0 : Core.UiStyle.spacingXs
            bottom: menu.openUpwards ? Core.UiStyle.spacingXs : 0
        }
    }

    onVisibleChanged: {
        if (!menu.visible && menu.handleStack.length > 0)
            menu.close();
    }

    QsMenuOpener {
        id: opener

        menu: menu.currentHandle
    }

    // D-Bus menus routinely contain leading, trailing, and doubled separators
    // that only look like stray lines once rendered, so collapse them.
    readonly property var visibleEntries: {
        const source = opener.children ? opener.children.values : [];
        const result = [];
        for (const entry of source) {
            if (!entry)
                continue;
            if (entry.isSeparator) {
                if (result.length === 0 || result[result.length - 1].isSeparator)
                    continue;
            }
            result.push(entry);
        }
        while (result.length > 0 && result[result.length - 1].isSeparator)
            result.pop();
        return result;
    }

    Rectangle {
        id: card

        anchors.fill: parent
        color: Core.Theme.alphaColor(Core.Theme.surface, Core.UiStyle.flatSurfaces ? 0.97 : 0.94)
        radius: Core.UiStyle.radiusOverlay
        border.width: 1
        border.color: menu.insetBorder

        implicitWidth: column.implicitWidth + menu.menuPadding * 2
        implicitHeight: column.implicitHeight + menu.menuPadding * 2

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: menu.menuPadding
            spacing: 2

            // Header doubles as the back affordance when inside a submenu.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: menu.rowHeight
                visible: menu.titleText !== ""

                Rectangle {
                    anchors.fill: parent
                    radius: Core.UiStyle.radiusControl
                    color: backArea.containsMouse && menu.nested ? menu.insetFill : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Core.UiStyle.spacingSm
                    anchors.rightMargin: Core.UiStyle.spacingSm
                    spacing: Core.UiStyle.spacingXs

                    Text {
                        visible: menu.nested
                        text: "\u2039"
                        color: Core.Theme.accent
                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.UiStyle.fontBody + 2
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: menu.titleText
                        color: Core.Theme.muted
                        font.family: Core.Theme.fontFamily
                        font.pixelSize: Core.UiStyle.fontCaption
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: backArea

                    anchors.fill: parent
                    hoverEnabled: menu.nested
                    enabled: menu.nested
                    cursorShape: menu.nested ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: menu.ascend()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: menu.insetBorder
                visible: menu.titleText !== ""
            }

            Repeater {
                model: menu.visibleEntries

                delegate: Item {
                    id: row

                    required property var modelData

                    readonly property bool separator: !!row.modelData && row.modelData.isSeparator
                    readonly property bool checkable: !!row.modelData && row.modelData.buttonType !== undefined && row.modelData.buttonType !== 0
                    readonly property bool actionable: !!row.modelData && !row.separator && row.modelData.enabled

                    Layout.fillWidth: true
                    Layout.preferredHeight: row.separator ? Core.UiStyle.spacingSm : menu.rowHeight

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: menu.insetBorder
                        visible: row.separator
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Core.UiStyle.radiusControl
                        visible: !row.separator
                        color: rowArea.containsMouse && row.actionable ? menu.insetFill : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 90
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Core.UiStyle.spacingSm
                        anchors.rightMargin: Core.UiStyle.spacingSm
                        spacing: Core.UiStyle.spacingXs
                        visible: !row.separator

                        // Checkbox and radio state, drawn rather than themed via
                        // an icon set so it always matches the shell palette.
                        Item {
                            Layout.preferredWidth: row.checkable ? Core.UiStyle.iconBox : 0
                            Layout.preferredHeight: Core.UiStyle.iconBox
                            visible: row.checkable

                            Rectangle {
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                radius: row.modelData && row.modelData.buttonType === 2 ? 6 : 3
                                color: row.modelData && row.modelData.checkState === Qt.Checked ? Core.Theme.accent : "transparent"
                                border.width: 1
                                border.color: row.modelData && row.modelData.checkState === Qt.Checked ? Core.Theme.accent : menu.insetBorder
                            }
                        }

                        Image {
                            Layout.preferredWidth: Core.UiStyle.iconBox
                            Layout.preferredHeight: Core.UiStyle.iconBox
                            visible: !!row.modelData && String(row.modelData.icon || "") !== ""
                            source: row.modelData ? String(row.modelData.icon || "") : ""
                            sourceSize.width: Core.UiStyle.iconBox * 2
                            sourceSize.height: Core.UiStyle.iconBox * 2
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            asynchronous: true
                        }

                        Text {
                            Layout.fillWidth: true
                            // D-Bus menu labels carry mnemonic underscores that
                            // have no meaning without keyboard traversal.
                            text: row.modelData ? String(row.modelData.text || "").replace(/_/g, "") : ""
                            color: row.actionable ? Core.Theme.foreground : Core.Theme.muted
                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.UiStyle.fontBody
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: !!row.modelData && row.modelData.hasChildren
                            text: "\u203a"
                            color: Core.Theme.muted
                            font.family: Core.Theme.fontFamily
                            font.pixelSize: Core.UiStyle.fontBody + 2
                        }
                    }

                    MouseArea {
                        id: rowArea

                        anchors.fill: parent
                        hoverEnabled: row.actionable
                        enabled: row.actionable
                        cursorShape: row.actionable ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: menu.trigger(row.modelData)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: menu.rowHeight
                visible: menu.visibleEntries.length === 0
                text: "No menu entries"
                color: Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: Core.UiStyle.fontCaption
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
