import QtQuick
import "../core" as Core

Item {
    id: root

    required property string widgetId
    readonly property bool pillEnabled: root.surfaceKind === "bar"
    // Extra horizontal room the pill reserves beyond the widget's natural
    // content width, so the pill reads as a pill rather than a tight
    // outline around the glyphs.
    readonly property real pillPadding: 10
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
                + (root.pillEnabled ? root.pillPadding * 2 : 0)
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

        // Widget content lives inside the pill so hover/press state bubbles up
        // from the widget's own mouse areas to the pill's passive handler.
        const container = root.pillEnabled ? pill : root
        const item = component.createObject(container, { context: widgetContext })
        if (!item) {
            root.loadError = component.errorString() || ("Failed to create " + root.widgetId)
            console.warn(root.loadError)
            return
        }

        root.loadedItem = item
        // Fill the pill completely rather than inset by the padding: the
        // widget's own root Item is what carries its click MouseArea, so
        // shrinking it here would leave the pill's padding band dead to
        // clicks even though it bounces (PillBox's tap tracking is passive
        // and covers the full pill). Widgets already center their content
        // via anchors.centerIn, so filling the larger area doesn't shift
        // anything visually.
        item.width = Qt.binding(function() { return container.width })
        item.height = Qt.binding(function() { return container.height })
        item.x = 0
        item.y = 0
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

    PillBox {
        id: pill
        anchors.fill: parent
        visible: root.pillEnabled && root.supported && root.contentVisible
            && root.loadError.length === 0
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
