pragma Singleton

import Quickshell

Singleton {
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property date date: clock.date
    readonly property string timeShort: Qt.formatDateTime(clock.date, "h:mm AP")
    readonly property string timeLong: Qt.formatDateTime(clock.date, "h:mm:ss AP")
    readonly property string dateShort: Qt.formatDateTime(clock.date, "ddd d MMM")
    readonly property string dateLong: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
}
