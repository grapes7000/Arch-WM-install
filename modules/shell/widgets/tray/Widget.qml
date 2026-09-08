import QtQuick
import QtQuick.Layouts
import "../../core" as Core
import "../../services" as Services

// Renders StatusNotifierItem icons published by running applications.
//
// The widget deliberately owns no window: opening an item's D-Bus menu is a
// capability request handled by the host surface, which keeps window ownership
// with the surface as the widget contract requires.
Item {
    id: root

    property var context: ({
        variant: "standard",
        settings: ({}),
        locked: false,
        allows: function() { return false },
        request: function() { return false }
    })

    readonly property bool compact: root.context.variant === "compact"
    readonly property int iconSize: root.compact ? Core.UiStyle.iconBox + 2 : Core.UiStyle.iconBox + 4
    readonly property int slotSize: root.iconSize + Core.UiStyle.spacingXs * 2

    readonly property var items: root.context.locked ? [] : Services.TrayService.items

    // Collapsing to zero width keeps the bar layout tidy when nothing is
    // registered, rather than leaving an unexplained gap.
    implicitWidth: root.items.length === 0 ? 0 : content.implicitWidth
    implicitHeight: root.items.length === 0 ? 0 : content.implicitHeight
    visible: root.items.length > 0

    RowLayout {
        id: content

        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.items

            delegate: Item {
                id: slot

                required property var modelData

                readonly property bool passive: Services.TrayService.isPassive(slot.modelData)
                readonly property bool attention: Services.TrayService.needsAttentionFor(slot.modelData)

                Layout.preferredWidth: root.slotSize
                Layout.preferredHeight: root.slotSize

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Core.UiStyle.radiusControl
                    color: slotArea.containsMouse ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.5) : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 110
                        }
                    }
                }

                Image {
                    id: icon

                    anchors.centerIn: parent
                    width: root.iconSize
                    height: root.iconSize
                    source: slot.modelData ? String(slot.modelData.icon || "") : ""
                    sourceSize.width: root.iconSize * 2
                    sourceSize.height: root.iconSize * 2
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    // Applications that mark an item passive consider it
                    // uninteresting; dim rather than hide so the user can still
                    // tell the application is running.
                    opacity: slot.passive ? 0.55 : 1.0
                    scale: slotArea.containsMouse ? 1.12 : 1.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 130
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                // Fallback glyph for items that publish no usable icon, so a
                // broken icon theme cannot make an item unclickable.
                Text {
                    anchors.centerIn: parent
                    visible: icon.status === Image.Error || icon.source === ""
                    text: "󰄰"
                    font.family: Core.Theme.fontFamily
                    font.pixelSize: root.iconSize
                    color: Core.Theme.muted
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    width: 4
                    height: 4
                    radius: 2
                    color: Core.Theme.urgent
                    visible: slot.attention
                }

                MouseArea {
                    id: slotArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    onClicked: function (mouse) {
                        if (!slot.modelData)
                            return;
                        if (mouse.button === Qt.RightButton) {
                            root.openMenu(slot.modelData, slot);
                            return;
                        }
                        if (mouse.button === Qt.MiddleButton) {
                            if (root.context.allows("tray.activate"))
                                Services.TrayService.secondaryActivate(slot.modelData);
                            return;
                        }
                        // Items that only provide a menu have no activate
                        // action, so a left click should show the menu instead
                        // of silently doing nothing.
                        if (slot.modelData.onlyMenu || !root.context.allows("tray.activate")) {
                            root.openMenu(slot.modelData, slot);
                            return;
                        }
                        if (!Services.TrayService.activate(slot.modelData))
                            root.openMenu(slot.modelData, slot);
                    }

                    onWheel: function (wheel) {
                        if (!slot.modelData || !root.context.allows("tray.activate"))
                            return;
                        if (wheel.angleDelta.y !== 0)
                            Services.TrayService.scroll(slot.modelData, wheel.angleDelta.y, false);
                        else if (wheel.angleDelta.x !== 0)
                            Services.TrayService.scroll(slot.modelData, wheel.angleDelta.x, true);
                    }
                }
            }
        }
    }

    function openMenu(item, anchorItem) {
        if (!item || !item.hasMenu || !root.context.allows("tray.menu"))
            return false;
        return root.context.request("tray.menu", {
            item: item,
            anchorItem: anchorItem
        });
    }
}
