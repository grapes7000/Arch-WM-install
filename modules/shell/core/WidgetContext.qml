import QtQuick

QtObject {
    required property string surface
    required property string instanceId
    property string variant: "standard"
    property real density: 1.0
    property bool locked: false
    property real availableWidth: 0
    property real availableHeight: 0
    property var capabilities: []
    property var settings: ({})
    property var requestHandler: null

    function allows(capability) {
        return capabilities.indexOf(capability) !== -1
    }

    function request(capability, payload) {
        return SurfaceRegistry.request(
            surface,
            capabilities,
            locked,
            requestHandler,
            capability,
            payload || ({})
        )
    }
}
