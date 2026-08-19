import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../core" as Core
import "../../components" as Components

Item {
    id: root

    property bool compact: false
    property var apps: []
    property string activeSection: "apps"
    property var projects: []
    property string projectScanStatus: "Scanning projects…"
    readonly property string homePath: Quickshell.env("HOME") || ""
    readonly property var commonPlaces: [
        { icon: "󰉋", name: "Home", detail: "Personal files", path: root.homePath },
        { icon: "󰏇", name: "Projects", detail: "Code & repositories", path: root.homePath + "/Projects" },
        { icon: "󰉍", name: "Downloads", detail: "Recent downloads", path: root.homePath + "/Downloads" },
        { icon: "󰈙", name: "Documents", detail: "Documents", path: root.homePath + "/Documents" },
        { icon: "󰉏", name: "Pictures", detail: "Images & screenshots", path: root.homePath + "/Pictures" },
        { icon: "󰒓", name: "Config", detail: "~/.config", path: root.homePath + "/.config" }
    ]

    implicitHeight: accessLayout.implicitHeight

    function desktopIconFor(command) {
        if (!command)
            return ""
        const bin = command.trim().split(" ")[0].split("/").pop().toLowerCase()
        const entries = [...DesktopEntries.applications.values]
        const match = entries.find(entry => {
            const id = String(entry.id || "").toLowerCase()
            const execBin = String(entry.execString || "").trim().split(" ")[0].split("/").pop().toLowerCase()
            return execBin === bin || id === bin || id === bin + ".desktop"
        })
        return match ? match.icon : ""
    }

    function launchShell(command) {
        if (!command || actionProcess.running)
            return
        actionProcess.command = ["sh", "-lc", command]
        actionProcess.running = true
    }

    function openPath(path) {
        if (!path || actionProcess.running)
            return
        actionProcess.command = ["xdg-open", path]
        actionProcess.running = true
    }

    function openTerminal(path) {
        if (!path || actionProcess.running)
            return
        actionProcess.command = ["kitty", "--directory", path]
        actionProcess.running = true
    }

    function addProject(path) {
        const clean = String(path || "").trim()
        if (!clean || root.projects.some(entry => entry.path === clean))
            return
        const bits = clean.split("/").filter(value => value.length > 0)
        root.projects = root.projects.concat([{
            name: bits.length ? bits[bits.length - 1] : clean,
            path: clean
        }])
    }

    function scanProjects() {
        if (projectScan.running || !root.homePath)
            return
        root.projects = []
        root.projectScanStatus = "Scanning projects…"
        projectScan.command = [
            "sh", "-lc",
            "for base in \"$HOME/Projects\" \"$HOME/Code\" \"$HOME/Developer\"; do "
                + "[ -d \"$base\" ] || continue; "
                + "find \"$base\" -mindepth 2 -maxdepth 4 -name .git -print 2>/dev/null; "
                + "done | while IFS= read -r marker; do dirname \"$marker\"; done | sort -u | head -n 8"
        ]
        projectScan.running = true
    }

    Process {
        id: actionProcess
        onExited: command = []
    }

    Process {
        id: projectScan
        stdout: SplitParser {
            onRead: data => root.addProject(data)
        }
        onExited: (exitCode, exitStatus) => {
            command = []
            root.projectScanStatus = root.projects.length > 0
                ? root.projects.length + " Git repositories found"
                : "No Git repositories found"
        }
    }

    Component.onCompleted: root.scanProjects()

    ColumnLayout {
        id: accessLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10

        Rectangle {
            id: launcherStrip
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? 54 : 62
            radius: Math.max(11, Core.Theme.homepageCardRadius - 4)
            color: launcherHover.hovered
                ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.78)
                : Core.Theme.alphaColor(Core.Theme.surfaceElevated, 0.62)
            border.width: 1
            border.color: launcherHover.hovered
                ? Core.Theme.alphaColor(Core.Theme.accent, 0.62)
                : Core.Theme.alphaColor(Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor, 0.62)
            scale: launcherHover.hovered ? 1.008 : 1.0

            Behavior on color { ColorAnimation { duration: 130 } }
            Behavior on border.color { ColorAnimation { duration: 130 } }
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 11
                    color: Core.Theme.alphaColor(Core.Theme.accent, 0.14)

                    Text {
                        anchors.centerIn: parent
                        text: "󰍉"
                        color: Core.Theme.accent
                        font.family: Core.Theme.fontFamily
                        font.pixelSize: 18
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: "Search, launch, or jump anywhere"
                        color: Core.Theme.foreground
                        font.family: Core.Theme.fontFamily
                        font.pixelSize: root.compact ? 13 : 14
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Apps, files, commands and open windows"
                        color: Core.Theme.muted
                        font.family: Core.Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }

                StatusChip {
                    text: "SUPER  SPACE"
                    tone: "secondary"
                }
            }

            HoverHandler { id: launcherHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                id: launcherTap
                onTapped: Core.InteractiveShellController.launcher("open")
            }
            Components.PressBounce { target: launcherStrip; pressed: launcherTap.pressed }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { key: "apps", label: "Apps", icon: "󰀻" },
                    { key: "places", label: "Places", icon: "󰉋" },
                    { key: "projects", label: "Git Projects", icon: "󰊢" }
                ]

                Rectangle {
                    id: sectionButton
                    required property var modelData
                    Layout.preferredWidth: sectionLabel.implicitWidth + 32
                    Layout.preferredHeight: 30
                    radius: 10
                    color: root.activeSection === modelData.key
                        ? Core.Theme.alphaColor(Core.Theme.accent, 0.14)
                        : Core.Theme.alphaColor(Core.Theme.surfaceElevated, sectionHover.hovered ? 0.68 : 0.42)
                    border.width: 1
                    border.color: root.activeSection === modelData.key
                        ? Core.Theme.alphaColor(Core.Theme.accent, 0.42)
                        : Core.Theme.alphaColor(Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor, 0.42)

                    RowLayout {
                        id: sectionLabel
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: modelData.icon; color: root.activeSection === modelData.key ? Core.Theme.accent : Core.Theme.muted; font.pixelSize: 12 }
                        Text { text: modelData.label; color: Core.Theme.foreground; font.family: Core.Theme.fontFamily; font.pixelSize: 10; font.bold: true }
                    }

                    HoverHandler { id: sectionHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.activeSection = modelData.key }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: root.activeSection === "projects"
                text: root.projectScanStatus
                color: Core.Theme.muted
                font.family: Core.Theme.fontFamily
                font.pixelSize: 9
            }
        }

        GridLayout {
            visible: root.activeSection === "apps"
            Layout.fillWidth: true
            columns: root.compact ? 4 : 5
            rowSpacing: 7
            columnSpacing: 7

            Repeater {
                model: root.apps.slice(0, root.compact ? 8 : 10)

                Rectangle {
                    id: appTile
                    required property var modelData
                    readonly property string desktopIcon: root.desktopIconFor(modelData.command)
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.compact ? 62 : 72
                    radius: 11
                    color: appHover.hovered
                        ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.62)
                        : Core.Theme.alphaColor(Core.Theme.surfaceElevated, 0.38)
                    border.width: 1
                    border.color: Core.Theme.alphaColor(
                        appHover.hovered ? Core.Theme.accent : (Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor),
                        appHover.hovered ? 0.42 : 0.32
                    )

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: appTile.desktopIcon !== ""
                            implicitSize: root.compact ? 25 : 30
                            source: appTile.desktopIcon !== "" ? Quickshell.iconPath(appTile.desktopIcon, "") : ""
                            scale: appHover.hovered ? 1.08 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: appTile.desktopIcon === ""
                            text: modelData.icon
                            color: Core.Theme.accent
                            font.pixelSize: root.compact ? 23 : 27
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
                            color: Core.Theme.foreground
                            font.family: Core.Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    HoverHandler { id: appHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: appTap; onTapped: root.launchShell(modelData.command) }
                    Components.PressBounce { target: appTile; pressed: appTap.pressed }
                }
            }
        }

        GridLayout {
            visible: root.activeSection === "places"
            Layout.fillWidth: true
            columns: root.compact ? 2 : 3
            rowSpacing: 7
            columnSpacing: 7

            Repeater {
                model: root.commonPlaces

                Rectangle {
                    id: placeTile
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.compact ? 56 : 62
                    radius: 11
                    color: placeHover.hovered
                        ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.62)
                        : Core.Theme.alphaColor(Core.Theme.surfaceElevated, 0.38)
                    border.width: 1
                    border.color: Core.Theme.alphaColor(
                        placeHover.hovered ? Core.Theme.accent : (Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor),
                        placeHover.hovered ? 0.42 : 0.32
                    )

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 9
                        Text { text: modelData.icon; color: Core.Theme.accent2; font.pixelSize: 19 }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text { Layout.fillWidth: true; text: modelData.name; color: Core.Theme.foreground; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: modelData.detail; color: Core.Theme.muted; font.pixelSize: 9; elide: Text.ElideRight }
                        }
                    }

                    HoverHandler { id: placeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: placeTap; onTapped: root.openPath(modelData.path) }
                    Components.PressBounce { target: placeTile; pressed: placeTap.pressed }
                }
            }
        }

        GridLayout {
            visible: root.activeSection === "projects" && root.projects.length > 0
            Layout.fillWidth: true
            columns: root.compact ? 1 : 2
            rowSpacing: 7
            columnSpacing: 7

            Repeater {
                model: root.projects

                Rectangle {
                    id: projectTile
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    radius: 11
                    color: projectHover.hovered
                        ? Core.Theme.alphaColor(Core.Theme.surfaceHover, 0.62)
                        : Core.Theme.alphaColor(Core.Theme.surfaceElevated, 0.38)
                    border.width: 1
                    border.color: Core.Theme.alphaColor(
                        projectHover.hovered ? Core.Theme.accent : (Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor),
                        projectHover.hovered ? 0.42 : 0.32
                    )

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 10
                            color: Core.Theme.alphaColor(Core.Theme.accent2, 0.12)
                            Text { anchors.centerIn: parent; text: "󰊢"; color: Core.Theme.accent2; font.pixelSize: 17 }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text { Layout.fillWidth: true; text: modelData.name; color: Core.Theme.foreground; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: modelData.path; color: Core.Theme.muted; font.pixelSize: 8; elide: Text.ElideMiddle }
                        }

                        Rectangle {
                            id: terminalButton
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: 9
                            color: terminalHover.hovered
                                ? Core.Theme.alphaColor(Core.Theme.accent, 0.18)
                                : Core.Theme.alphaColor(Core.Theme.surfaceOverlay, 0.66)
                            Text { anchors.centerIn: parent; text: "󰆍"; color: Core.Theme.accent; font.pixelSize: 15 }
                            HoverHandler { id: terminalHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.openTerminal(modelData.path) }
                        }
                    }

                    HoverHandler { id: projectHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: projectTap; onTapped: root.openPath(modelData.path) }
                    Components.PressBounce { target: projectTile; pressed: projectTap.pressed }
                }
            }
        }

        Rectangle {
            visible: root.activeSection === "projects" && root.projects.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            radius: 11
            color: Core.Theme.alphaColor(Core.Theme.surfaceElevated, 0.34)
            border.width: 1
            border.color: Core.Theme.alphaColor(Core.Theme.roles.border_subtle || Core.Theme.barOutlineColor, 0.34)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 11
                spacing: 10
                Text { text: "󰊢"; color: Core.Theme.muted; font.pixelSize: 20 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text { text: "No projects discovered yet"; color: Core.Theme.foreground; font.pixelSize: 11; font.bold: true }
                    Text { Layout.fillWidth: true; text: "Scans ~/Projects, ~/Code and ~/Developer"; color: Core.Theme.muted; font.pixelSize: 9; elide: Text.ElideRight }
                }
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 30
                    radius: 9
                    color: Core.Theme.alphaColor(Core.Theme.accent, refreshHover.hovered ? 0.20 : 0.10)
                    Text { anchors.centerIn: parent; text: "󰑓"; color: Core.Theme.accent; font.pixelSize: 15 }
                    HoverHandler { id: refreshHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.scanProjects() }
                }
            }
        }
    }
}
