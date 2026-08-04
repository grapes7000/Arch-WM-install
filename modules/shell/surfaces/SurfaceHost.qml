import QtQuick

Item {
    id: root

    required property string surfaceKind
    property string layoutPath
    property bool locked: surfaceKind === "lockscreen"
    property real density: 1.0

    // Surface-specific windows wrap this content host. The production host
    // parses layouts, resolves manifests, intersects capabilities and creates
    // widget instances through Loader.
    default property alias content: container.data

    Item {
        id: container
        anchors.fill: parent
    }
}
