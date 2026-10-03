pragma Singleton
// Time and date, already formatted. Updates itself every minute.
import QtQuick
import Quickshell
import qs.config

Singleton {
    readonly property date now: clock.date
    readonly property var loc: Config.locale ? Qt.locale(Config.locale) : Qt.locale()
    readonly property string time: loc.toString(now, Config.timeFormat)
    readonly property string date: loc.toString(now, Config.dateFormat)

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
