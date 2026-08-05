import QtQuick
import "../core" as Core

Item {
    id: root

    required property string widgetId
    required property string surfaceKind
    required property string instanceId
    property string variant: "standard"
    property bool locked: false
    property var settings: ({})
    property real density: 1.0

    readonly property var _registry: Core.WidgetRegistry.widgets
    readonly property var definition: _registry ? Core.WidgetRegistry.definition(widgetId) : null
    readonly property bool supported: _registry ? Core.WidgetRegistry.supports(widgetId, surfaceKind, locked) : false
    readonly property var requestedCapabilities: definition && definition.capabilities
        ? definition.capabilities : []

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0
    visible: supported

    Core.WidgetContext {
        id: widgetContext
        surface: root.surfaceKind
        instanceId: root.instanceId
        variant: root.variant
        density: root.density
        locked: root.locked
        availableWidth: root.width
        availableHeight: root.height
        capabilities: Core.SurfaceRegistry.grant(root.surfaceKind, root.requestedCapabilities)
        settings: root.settings
    }

    Loader {
        id: loader
        anchors.fill: parent
        active: root.supported
        source: root.supported ? Core.WidgetRegistry.entryUrl(root.widgetId) : ""
        onLoaded: {
            if (item)
                item.context = widgetContext
        }
    }
}
