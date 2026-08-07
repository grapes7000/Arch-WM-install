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
    property var requestHandler: null
    property real density: 1.0
    property string loadError: ""
    property var loadedItem: null
    property var loadedComponent: null

    readonly property var _registry: Core.WidgetRegistry.widgets
    readonly property var definition: _registry ? Core.WidgetRegistry.definition(widgetId) : null
    readonly property bool supported: _registry ? Core.WidgetRegistry.supports(widgetId, surfaceKind, locked) : false
    readonly property var requestedCapabilities: definition && definition.capabilities
        ? definition.capabilities : []
    readonly property bool contentVisible: loadedItem ? loadedItem.visible : true

    implicitWidth: {
        if (!supported || !contentVisible)
            return 0
        if (loadedItem)
            return Math.max(0, loadedItem.implicitWidth)
        return loadError ? 24 : 0
    }
    implicitHeight: {
        if (!supported || !contentVisible)
            return 0
        if (loadedItem)
            return Math.max(0, loadedItem.implicitHeight)
        return loadError ? 24 : 0
    }
    visible: supported

    function clearWidget() {
        if (root.loadedItem) {
            root.loadedItem.destroy()
            root.loadedItem = null
        }
        root.loadedComponent = null
    }

    function finishCreate(component) {
        if (component !== root.loadedComponent)
            return

        if (component.status === Component.Error) {
            root.loadError = component.errorString()
            console.warn("Failed to load", root.widgetId, root.loadError)
            return
        }
        if (component.status !== Component.Ready)
            return

        const item = component.createObject(root, { context: widgetContext })
        if (!item) {
            root.loadError = component.errorString() || ("Failed to create " + root.widgetId)
            console.warn(root.loadError)
            return
        }

        root.loadedItem = item
        item.width = Qt.binding(function() { return root.width })
        item.height = Qt.binding(function() { return root.height })
        root.loadError = ""
    }

    function reloadWidget() {
        root.clearWidget()
        root.loadError = ""

        if (!root.supported)
            return

        const url = Core.WidgetRegistry.entryUrl(root.widgetId)
        if (!url) {
            root.loadError = "No entry for " + root.widgetId
            return
        }

        const component = Qt.createComponent(url, Component.PreferSynchronous)
        root.loadedComponent = component

        if (component.status === Component.Loading) {
            component.statusChanged.connect(function() {
                root.finishCreate(component)
            })
        } else {
            root.finishCreate(component)
        }
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
        requestHandler: root.requestHandler
    }

    Rectangle {
        anchors.fill: parent
        visible: root.supported && root.loadError.length > 0
        radius: Math.max(4, Core.Theme.radius)
        color: Core.Theme.background
        border.width: 1
        border.color: Core.Theme.urgent

        Text {
            font.family: Core.Theme.fontFamily
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
    Component.onDestruction: clearWidget()
}
