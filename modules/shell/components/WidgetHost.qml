import QtQuick
import ArchWmShell 1.0

Item {
    id: root

    required property string widgetId
    required property string surfaceKind
    required property string instanceId
    property string variant: "standard"
    property bool locked: false
    property var settings: ({})
    property real density: 1.0

    readonly property var definition: WidgetRegistry.definition(widgetId)
    readonly property bool supported: WidgetRegistry.supports(widgetId, surfaceKind, locked)
    readonly property var requestedCapabilities: definition && definition.capabilities
        ? definition.capabilities : []

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0
    visible: supported

    WidgetContext {
        id: widgetContext
        surface: root.surfaceKind
        instanceId: root.instanceId
        variant: root.variant
        density: root.density
        locked: root.locked
        availableWidth: root.width
        availableHeight: root.height
        capabilities: SurfaceRegistry.grant(root.surfaceKind, root.requestedCapabilities)
        settings: root.settings
    }

    Loader {
        id: loader
        anchors.fill: parent
        active: root.supported
        source: root.supported ? WidgetRegistry.entryUrl(root.widgetId) : ""
        onLoaded: {
            if (item)
                item.context = widgetContext
        }
    }
}
