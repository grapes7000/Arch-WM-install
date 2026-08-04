pragma Singleton

import Quickshell

Singleton {
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property date date: clock.date
    readonly property string timeShort: Qt.formatDateTime(clock.date, "hh:mm")
    readonly property string timeLong: Qt.formatDateTime(clock.date, "hh:mm:ss")
    readonly property string dateShort: Qt.formatDateTime(clock.date, "ddd d MMM")
    readonly property string dateLong: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
}
