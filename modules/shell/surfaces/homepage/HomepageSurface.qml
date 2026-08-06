import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
            property bool compactMenuOpen: false
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
            readonly property bool compact: width < 1050 || height < 690
            readonly property bool medium: !compact && width < 1450
            readonly property real outerGap: compact ? Math.max(5, Core.Theme.gap * 0.7) : Core.Theme.gap * 2
            readonly property real innerGap: compact ? Math.max(5, Core.Theme.gap * 0.65) : Core.Theme.gap
            readonly property real railWidth: medium ? 205 : 238
            readonly property real rightRailWidth: medium ? 215 : 250

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            margins {
                top: Core.Theme.barHeight + (compact ? Core.Theme.gap : Core.Theme.gap * 2)
                bottom: compact ? Core.Theme.gap : Core.Theme.gap * 2
                left: compact ? Core.Theme.gap : Core.Theme.gap * 2
                right: compact ? Core.Theme.gap : Core.Theme.gap * 2
            }
            aboveWindows: false
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: !Services.LockStateService.locked

            function select(page) {
                selectedPage = selectedPage === page ? "home" : page
                compactMenuOpen = false
            }

            function launch(command) {
                if (!command || launchProcess.running)
                    return
                launchProcess.command = ["sh", "-lc", command]
                launchProcess.running = true
            }

            Process {
                id: launchProcess
                onExited: command = []
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
                        running: ambientImage.status === Image.Ready && !root.compact
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

                Loader {
                    anchors.fill: parent
                    anchors.margins: root.outerGap
                    sourceComponent: root.compact ? compactLayout : desktopLayout
                }
            }

            Component {
                id: desktopLayout
                RowLayout {
                    spacing: root.outerGap

                    ColumnLayout {
                        Layout.preferredWidth: root.railWidth
                        Layout.fillHeight: true
                        spacing: root.innerGap
                        ClockCard {}
                        NavCard { icon: "󰃭"; title: "Calendar"; subtitle: "Agenda and upcoming events"; page: "calendar" }
                        NavCard { icon: "󰍛"; title: "System"; subtitle: "CPU, memory and storage"; page: "system" }
                        NavCard { icon: "󰖩"; title: "Network"; subtitle: Services.NetworkService.connected ? Services.NetworkService.ssid : "Disconnected"; page: "network" }
                        NavCard { icon: "󰂚"; title: "Activity"; subtitle: "Notifications and recent events"; page: "activity" }
                        Item { Layout.fillHeight: true }
                    }

                    CenterColumn {}

                    ColumnLayout {
                        Layout.preferredWidth: root.rightRailWidth
                        Layout.fillHeight: true
                        spacing: root.innerGap
                        NavCard {
                            Layout.preferredHeight: root.medium ? 112 : 136
                            icon: Services.WeatherService.icon || "󰖐"
                            title: Services.WeatherService.available ? Services.WeatherService.temp : "Weather"
                            subtitle: Services.WeatherService.condition || "Weather unavailable"
                            page: "weather"
                        }
                        NavCard {
                            Layout.preferredHeight: root.medium ? 102 : 124
                            icon: "󰒓"
                            title: "Quick controls"
                            subtitle: "Audio · Wi-Fi · Bluetooth · VPN"
                            page: "controls"
                        }
                        LauncherCard { Layout.fillHeight: true }
                    }
                }
            }

            Component {
                id: compactLayout
                ColumnLayout {
                    spacing: root.innerGap

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        spacing: root.innerGap
                        GlassCard {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                Text { text: Services.TimeService.timeShort; color: Core.Theme.foreground; font.pixelSize: 25; font.bold: true }
                                Text { Layout.fillWidth: true; text: Services.TimeService.dateLong; color: Core.Theme.muted; font.pixelSize: 10; elide: Text.ElideRight }
                                Text { text: Services.WeatherService.available ? Services.WeatherService.temp : "Weather"; color: Core.Theme.accent; font.pixelSize: 12; font.bold: true }
                            }
                        }
                        GlassCard {
                            Layout.preferredWidth: 54
                            Layout.fillHeight: true
                            interactive: true
                            Text { anchors.centerIn: parent; text: root.compactMenuOpen ? "󰅖" : "󰍜"; color: Core.Theme.accent; font.pixelSize: 23 }
                            TapHandler { onTapped: root.compactMenuOpen = !root.compactMenuOpen }
                        }
                    }

                    CenterColumn {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 7
                            Repeater {
                                model: [
                                    { icon: "󰃭", page: "calendar" },
                                    { icon: "󰍛", page: "system" },
                                    { icon: "󰖩", page: "network" },
                                    { icon: "󰖐", page: "weather" },
                                    { icon: "󰒓", page: "controls" },
                                    { icon: "󰂚", page: "activity" }
                                ]
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: Core.Theme.radius
                                    color: root.selectedPage === modelData.page ? Core.Theme.accent : Core.Theme.surface
                                    opacity: root.selectedPage === modelData.page ? 0.95 : 0.75
                                    Text { anchors.centerIn: parent; text: modelData.icon; color: root.selectedPage === modelData.page ? Core.Theme.background : Core.Theme.foreground; font.pixelSize: 21 }
                                    TapHandler { onTapped: root.select(modelData.page) }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: root.compactMenuOpen
                        z: 20
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(210, root.height * 0.34)
                        radius: Core.Theme.radius + 4
                        color: Core.Theme.surface
                        border.width: Core.Theme.borderWidth
                        border.color: Core.Theme.accent
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8
                            Text { text: "Quick access"; color: Core.Theme.foreground; font.bold: true; font.pixelSize: 14 }
                            RowLayout {
                                Layout.fillWidth: true
                                NavCard { Layout.fillWidth: true; Layout.preferredHeight: 78; icon: Services.WeatherService.icon || "󰖐"; title: "Weather"; subtitle: Services.WeatherService.condition || "Unavailable"; page: "weather" }
                                NavCard { Layout.fillWidth: true; Layout.preferredHeight: 78; icon: "󰒓"; title: "Controls"; subtitle: "Audio and network"; page: "controls" }
                            }
                            LauncherCard { Layout.fillWidth: true; Layout.fillHeight: true; compactMode: true }
                        }
                    }
                }
            }

            component ClockCard: GlassCard {
                Layout.fillWidth: true
                Layout.preferredHeight: root.medium ? 126 : 150
                Column {
                    anchors.fill: parent
                    anchors.margins: root.medium ? 14 : 18
                    spacing: 5
                    Text { text: Services.TimeService.timeShort; color: Core.Theme.foreground; font.pixelSize: root.medium ? 34 : 42; font.bold: true }
                    Text { text: Services.TimeService.dateLong; color: Core.Theme.muted; font.pixelSize: 12 }
                    Text { text: Core.Theme.data.name || "Current theme"; color: Core.Theme.accent; font.pixelSize: 10; font.bold: true }
                }
            }

            component NavCard: RailCard {
                property string page: ""
                Layout.fillWidth: true
                implicitHeight: root.medium ? 78 : 92
                active: root.selectedPage === page
                onActivated: root.select(page)
            }

            component CenterColumn: ColumnLayout {
                spacing: root.innerGap
                GlassCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Loader {
                        anchors.fill: parent
                        anchors.margins: root.compact ? 10 : Core.Theme.gap * 2
                        sourceComponent: root.selectedPage === "home" ? homeStage : detailStage
                    }
                }
                GlassCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.compact ? 96 : 126
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: root.compact ? 9 : 15
                        spacing: root.compact ? 8 : 14
                        ColumnLayout {
                            Layout.preferredWidth: root.compact ? 145 : 220
                            spacing: 2
                            Text { Layout.fillWidth: true; text: Services.MprisService.title || "Nothing playing"; color: Core.Theme.foreground; font.pixelSize: root.compact ? 11 : 14; font.bold: true; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: Services.MprisService.artist || "Your slideshow is active"; color: Core.Theme.muted; font.pixelSize: root.compact ? 9 : 11; elide: Text.ElideRight }
                        }
                        RowLayout {
                            spacing: root.compact ? 7 : 12
                            Text { text: "󰒮"; color: Core.Theme.muted; font.pixelSize: root.compact ? 18 : 21; MouseArea { anchors.fill: parent; onClicked: Services.MprisService.previous() } }
                            Text { text: Services.MprisService.status === "Playing" ? "󰏤" : "󰐊"; color: Core.Theme.accent; font.pixelSize: root.compact ? 23 : 28; MouseArea { anchors.fill: parent; onClicked: Services.MprisService.playPause() } }
                            Text { text: "󰒭"; color: Core.Theme.muted; font.pixelSize: root.compact ? 18 : 21; MouseArea { anchors.fill: parent; onClicked: Services.MprisService.next() } }
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
                                        width: Math.max(2, (parent.width - (Services.CavaService.bars.length - 1) * parent.spacing) / Math.max(1, Services.CavaService.bars.length))
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

            component LauncherCard: GlassCard {
                property bool compactMode: false
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: compactMode ? 8 : 15
                    spacing: compactMode ? 6 : 10
                    Text { text: "Pinned apps"; color: Core.Theme.foreground; font.pixelSize: compactMode ? 11 : 14; font.bold: true }
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: compactMode ? 6 : (root.medium ? 2 : 3)
                        rowSpacing: compactMode ? 5 : 10
                        columnSpacing: compactMode ? 5 : 10
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
                                Layout.fillWidth: true
                                Layout.preferredHeight: compactMode ? 48 : 64
                                radius: Core.Theme.radius
                                color: Core.Theme.surface
                                opacity: appHover.hovered ? 0.96 : 0.72
                                border.width: 1
                                border.color: appHover.hovered ? Core.Theme.accent : Core.Theme.accent2
                                Column {
                                    anchors.centerIn: parent
                                    spacing: compactMode ? 1 : 3
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; color: Core.Theme.foreground; font.pixelSize: compactMode ? 17 : 22 }
                                    Text { visible: !compactMode; anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: Core.Theme.muted; font.pixelSize: 8 }
                                }
                                HoverHandler { id: appHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: root.launch(modelData.command) }
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
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰎈"; color: Core.Theme.accent; font.pixelSize: root.compact ? 48 : 72 }
                        Text { text: root.mediaActive ? "Album artwork unavailable" : "Add wallpapers to the theme contract"; color: Core.Theme.muted; font.pixelSize: root.compact ? 10 : 13 }
                    }
                }
            }

            Component {
                id: detailStage
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: root.compact ? 8 : 14
                        Text { text: root.selectedPage.charAt(0).toUpperCase() + root.selectedPage.slice(1); color: Core.Theme.foreground; font.pixelSize: root.compact ? 21 : 28; font.bold: true }
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
                            font.pixelSize: root.compact ? 12 : 15
                            wrapMode: Text.WordWrap
                        }
                        Item { Layout.fillHeight: true }
                        Text { text: "Click the selected navigation item again to return"; color: Core.Theme.accent2; font.pixelSize: root.compact ? 9 : 11 }
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
