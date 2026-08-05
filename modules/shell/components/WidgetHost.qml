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
    property string loadError: ""

    readonly property var definition: Core.WidgetRegistry.definition(widgetId)
    readonly property bool supported: Core.WidgetRegistry.supports(widgetId, surfaceKind, locked)
    readonly property var requestedCapabilities: definition && definition.capabilities
        ? definition.capabilities : []
    readonly property bool contentVisible: loader.item ? loader.item.visible : true

    implicitWidth: {
        if (!supported || !contentVisible)
            return 0
        if (loader.item)
            return Math.max(0, loader.item.implicitWidth)
        return loader.status === Loader.Error ? 24 : 0
    }
    implicitHeight: {
        if (!supported || !contentVisible)
            return 0
        if (loader.item)
            return Math.max(0, loader.item.implicitHeight)
        return loader.status === Loader.Error ? 24 : 0
    }
    visible: supported

    function reloadWidget() {
        loader.active = false
        loader.source = ""
        root.loadError = ""

        if (!root.supported)
            return

        const url = Core.WidgetRegistry.entryUrl(root.widgetId)
        if (!url) {
            root.loadError = "No entry for " + root.widgetId
            return
        }

        loader.setSource(url, { context: widgetContext })
        loader.active = true
    }

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
        active: false
        asynchronous: false

        onStatusChanged: {
            if (status === Loader.Error) {
                root.loadError = "Failed to load " + root.widgetId
                console.warn(root.loadError, source)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.supported && loader.status === Loader.Error
        radius: Math.max(4, Core.Theme.radius)
        color: Core.Theme.background
        border.width: 1
        border.color: Core.Theme.urgent

        Text {
            anchors.centerIn: parent
            text: "!"
            color: Core.Theme.urgent
            font.bold: true
            font.pixelSize: 14
        }
    }

    Connections {
        target: Core.WidgetRegistry
        function onWidgetsChanged() { Qt.callLater(root.reloadWidget) }
    }

    onWidgetIdChanged: Qt.callLater(reloadWidget)
    onSurfaceKindChanged: Qt.callLater(reloadWidget)
    onLockedChanged: Qt.callLater(reloadWidget)
    Component.onCompleted: Qt.callLater(reloadWidget)
}
