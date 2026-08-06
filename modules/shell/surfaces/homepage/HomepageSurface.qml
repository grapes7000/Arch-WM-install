import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../core" as Core
import "../../services" as Services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            property string selectedPage: "home"
            property int slideIndex: 0
            property var slides: {
                const configured = Core.Theme.data.wallpapers || []
                if (Array.isArray(configured) && configured.length > 0)
                    return configured
                const wallpaper = Core.Theme.data.wallpaper || ""
                return wallpaper ? [wallpaper] : []
            }
            readonly property string currentSlide: slides.length > 0
                ? String(slides[Math.min(slideIndex, slides.length - 1)]) : ""
            readonly property bool mediaActive: Services.MprisService.status !== "Stopped"
            readonly property string artwork: Services.MprisService.artUrl || ""

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            margins {
                top: Core.Theme.barHeight + Core.Theme.gap * 2
                bottom: Core.Theme.gap * 2
                left: Core.Theme.gap * 2
                right: Core.Theme.gap * 2
            }
            aboveWindows: false
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: !Services.LockStateService.locked

            function select(page) {
                selectedPage = selectedPage === page ? "home" : page
            }

            Item {
                anchors.fill: parent

                Image {
                    id: ambientImage
                    anchors.fill: parent
                    source: root.mediaActive && root.artwork ? root.artwork : root.currentSlide
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: status === Image.Ready ? 0.34 : 0
                    scale: 1.12

                    Behavior on opacity { NumberAnimation { duration: Core.Theme.animationMs * 2 } }

                    SequentialAnimation on x {
                        running: ambientImage.status === Image.Ready
                        loops: Animation.Infinite
                        NumberAnimation { from: -20; to: 20; duration: 18000; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 20; to: -20; duration: 18000; easing.type: Easing.InOutSine }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Core.Theme.radius + 10
                    color: Core.Theme.background
                    opacity: 0.48
                    border.width: Core.Theme.borderWidth
                    border.color: Core.Theme.accent2
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Core.Theme.gap * 2
                    spacing: Core.Theme.gap * 2

                    ColumnLayout {
                        Layout.preferredWidth: 238
                        Layout.fillHeight: true
                        spacing: Core.Theme.gap

                        GlassCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 150

                            Column {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 5

                                Text {
                                    text: Services.TimeService.timeShort
                                    color: Core.Theme.foreground
                                    font.pixelSize: 42
                                    font.bold: true
                                }
                                Text {
                                    text: Services.TimeService.dateLong
                                    color: Core.Theme.muted
                                    font.pixelSize: 13
                                }
                                Text {
                                    text: Core.Theme.data.name || "Current theme"
                                    color: Core.Theme.accent
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }

                        RailCard {
                            Layout.fillWidth: true
                            icon: "󰃭"
                            title: "Calendar"
                            subtitle: "Agenda and upcoming events"
                            active: root.selectedPage === "calendar"
                            onActivated: root.select("calendar")
                        }

                        RailCard {
                            Layout.fillWidth: true
                            icon: "󰍛"
                            title: "System"
                            subtitle: "CPU, memory and storage"
                            active: root.selectedPage === "system"
                            onActivated: root.select("system")
                        }

                        RailCard {
                            Layout.fillWidth: true
                            icon: "󰖩"
                            title: "Network"
                            subtitle: Services.NetworkService.connected ? Services.NetworkService.ssid : "Disconnected"
                            active: root.selectedPage === "network"
                            onActivated: root.select("network")
                        }

                        RailCard {
                            Layout.fillWidth: true
                            icon: "󰂚"
                            title: "Activity"
                            subtitle: "Notifications and recent events"
                            active: root.selectedPage === "activity"
                            onActivated: root.select("activity")
                        }

                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Core.Theme.gap * 1.5

                        GlassCard {
                            id: centerStage
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Loader {
                                anchors.fill: parent
                                anchors.margins: Core.Theme.gap * 2
                                sourceComponent: root.selectedPage === "home" ? homeStage : detailStage
                            }
                        }

                        GlassCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 126

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 14

                                ColumnLayout {
                                    Layout.preferredWidth: 220
                                    spacing: 2
                                    Text {
                                        Layout.fillWidth: true
                                        text: Services.MprisService.title || "Nothing playing"
                                        color: Core.Theme.foreground
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: Services.MprisService.artist || "Your slideshow is active"
                                        color: Core.Theme.muted
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    spacing: 12
                                    Text { text: "󰒮"; color: Core.Theme.muted; font.pixelSize: 21; MouseArea { anchors.fill: parent; onClicked: Services.MprisService.previous() } }
                                    Text { text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"; color: Core.Theme.accent; font.pixelSize: 28; MouseArea { anchors.fill: parent; onClicked: Services.MprisService.playPause() } }
                                    Text { text: "󰒭"; color: Core.Theme.muted; font.pixelSize: 21; MouseArea { anchors.fill: parent; onClicked: Services.MprisService.next() } }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Row {
                                        anchors.fill: parent
                                        spacing: 3
                                        Repeater {
                                            model: Services.CavaService.bars
                                            Rectangle {
                                                required property real modelData
                                                width: Math.max(3, (parent.width - (Services.CavaService.bars.length - 1) * parent.spacing) / Math.max(1, Services.CavaService.bars.length))
                                                height: Math.max(3, parent.height * modelData)
                                                anchors.bottom: parent.bottom
                                                radius: width / 2
                                                color: index % 2 ? Core.Theme.accent2 : Core.Theme.accent
                                                Behavior on height { NumberAnimation { duration: 70 } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 250
                        Layout.fillHeight: true
                        spacing: Core.Theme.gap

                        RailCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 136
                            icon: Services.WeatherService.icon || "󰖐"
                            title: Services.WeatherService.available ? Services.WeatherService.temp : "Weather"
                            subtitle: Services.WeatherService.condition || "Weather unavailable"
                            active: root.selectedPage === "weather"
                            onActivated: root.select("weather")
                        }

                        RailCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 124
                            icon: "󰒓"
                            title: "Quick controls"
                            subtitle: "Audio · Wi-Fi · Bluetooth · VPN"
                            active: root.selectedPage === "controls"
                            onActivated: root.select("controls")
                        }

                        GlassCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 10

                                Text {
                                    text: "Pinned apps"
                                    color: Core.Theme.foreground
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 3
                                    rowSpacing: 12
                                    columnSpacing: 12

                                    Repeater {
                                        model: [
                                            { icon: "󰈹", name: "Browser", command: "firefox" },
                                            { icon: "󰆍", name: "Terminal", command: "kitty" },
                                            { icon: "󰏘", name: "Krita", command: "krita" },
                                            { icon: "󰉋", name: "Files", command: "thunar" },
                                            { icon: "󰒓", name: "Settings", command: "hyprctl dispatch exec nwg-look" },
                                            { icon: "+", name: "Add", command: "" }
                                        ]

                                        Rectangle {
                                            required property var modelData
                                            Layout.preferredWidth: 62
                                            Layout.preferredHeight: 68
                                            radius: Core.Theme.radius
                                            color: Core.Theme.surface
                                            opacity: appHover.hovered ? 0.96 : 0.72
                                            border.width: 1
                                            border.color: appHover.hovered ? Core.Theme.accent : Core.Theme.accent2

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; color: Core.Theme.foreground; font.pixelSize: 23 }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: Core.Theme.muted; font.pixelSize: 9 }
                                            }
                                            HoverHandler { id: appHover; cursorShape: Qt.PointingHandCursor }
                                            TapHandler { onTapped: if (modelData.command) Quickshell.execDetached(["sh", "-lc", modelData.command]) }
                                        }
                                    }
                                }

                                Item { Layout.fillHeight: true }
                            }
                        }
                    }
                }
            }

            Component {
                id: homeStage
                Item {
                    Image {
                        anchors.fill: parent
                        source: root.mediaActive && root.artwork ? root.artwork : root.currentSlide
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Core.Theme.animationMs * 2 } }
                    }
                    Column {
                        anchors.centerIn: parent
                        visible: !(root.mediaActive && root.artwork) && !root.currentSlide
                        spacing: 8
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰎈"; color: Core.Theme.accent; font.pixelSize: 72 }
                        Text { text: root.mediaActive ? "Album artwork unavailable" : "Add wallpapers to the theme contract"; color: Core.Theme.muted; font.pixelSize: 13 }
                    }
                }
            }

            Component {
                id: detailStage
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 14
                        Text {
                            text: root.selectedPage.charAt(0).toUpperCase() + root.selectedPage.slice(1)
                            color: Core.Theme.foreground
                            font.pixelSize: 28
                            font.bold: true
                        }
                        Rectangle { Layout.fillWidth: true; height: 2; color: Core.Theme.accent; opacity: 0.7 }
                        Text {
                            Layout.fillWidth: true
                            text: root.selectedPage === "weather" ? "Current weather: " + Services.WeatherService.temp + " · " + Services.WeatherService.condition
                                : root.selectedPage === "system" ? "Detailed system monitoring will use the shared SystemStats service."
                                : root.selectedPage === "network" ? "Connected network: " + (Services.NetworkService.ssid || "None")
                                : root.selectedPage === "calendar" ? Qt.formatDate(new Date(), "dddd, MMMM d, yyyy")
                                : root.selectedPage === "controls" ? "Quick settings use the shell's shared audio, network and power services."
                                : "This detail page is ready for its shared service-backed content."
                            color: Core.Theme.muted
                            font.pixelSize: 15
                            wrapMode: Text.WordWrap
                        }
                        Item { Layout.fillHeight: true }
                        Text { text: "Click the selected rail card again to return"; color: Core.Theme.accent2; font.pixelSize: 11 }
                    }
                }
            }

            Timer {
                interval: 30000
                running: root.slides.length > 1 && !root.mediaActive
                repeat: true
                onTriggered: root.slideIndex = (root.slideIndex + 1) % root.slides.length
            }
        }
    }
}
