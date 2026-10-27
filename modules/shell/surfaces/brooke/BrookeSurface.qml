import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core" as Core
import "../../services" as Services
import "../../widgets/brooke-panel" as Brooke
import "../../components" as Components
Scope {
    id: root
    property var layout: ({regions: {start: []}})
    property var assets: ({launchers: [], topLaunchers: []})
    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/brooke-desktop"
    FileView {
        id: configFile
        path: Quickshell.shellDir + "/layouts/bar.brooke.json"
        watchChanges: true
        blockLoading: true
        onTextChanged: { try { root.layout = JSON.parse(configFile.text()) } catch (e) { console.warn(e) } }
        onFileChanged: reload()
    }
    FileView {
        id: assetsFile
        path: root.dataDir + "/assets.json"
        blockLoading: true
        onTextChanged: { try { root.assets = JSON.parse(assetsFile.text()) } catch (e) { console.warn(e) } }
    }
    Component.onCompleted: {
        try { root.layout = JSON.parse(configFile.text()) } catch (e) { console.warn("Brooke layout unavailable:", e) }
        try { root.assets = JSON.parse(assetsFile.text()) } catch (e) { console.warn("Import Brooke assets before launch:", e) }
    }
    Components.TrayMenu { id: trayMenu }
    QtObject {
        id: trayController
        function open(item, anchorItem, screen) { return trayMenu.openFor(item, anchorItem) }
        function close() { trayMenu.close(); return true }
    }
    Binding { target: Core.InteractiveShellController; property: "trayMenuController"; value: trayController }
    Variants {
        model: Quickshell.screens
        Scope {
            id: monitor
            required property var modelData
            property bool controlsOpen: false
            WindowControls { targetScreen: monitor.modelData; shown: monitor.controlsOpen; onDismiss: monitor.controlsOpen = false }
            Variants {
                model: root.layout.regions.start || []
                PanelWindow {
                    id: panel
                    required property var modelData
                    readonly property var options: modelData.settings || ({})
                    screen: monitor.modelData
                    anchors { left: true; right: true; top: options.position === "top"; bottom: options.position === "bottom" }
                    implicitHeight: options.height || (options.position === "top" ? 29 : 41)
                    exclusiveZone: options.exclusive ? implicitHeight : 0
                    exclusionMode: options.exclusive ? ExclusionMode.Normal : ExclusionMode.Ignore
                    color: "transparent"
                    visible: !Services.LockStateService.locked
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "brooke-" + options.position
                    Rectangle {
                        anchors.fill: parent
                        color: Core.Theme.background
                        Image { anchors.fill: parent; source: root.assets.stripes || ""; fillMode: Image.Tile; visible: status === Image.Ready }
                        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#eeeeee" }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#333333" }
                    }
                    Components.WidgetHost {
                        anchors.fill: parent
                        anchors.margins: 2
                        widgetId: panel.modelData.widget
                        surfaceKind: "bar"
                        instanceId: panel.modelData.instance
                        variant: panel.modelData.variant
                        locked: Services.LockStateService.locked
                        settings: ({position: panel.options.position, assets: root.assets, options: panel.options,
                            screen: panel.screen,
                            openControls: function() { monitor.controlsOpen = !monitor.controlsOpen }})
                        requestHandler: function(capability, payload) { return Core.InteractiveShellController.requestFromBar(capability, payload, panel.screen) }
                    }
                }
            }
        }
    }
}
