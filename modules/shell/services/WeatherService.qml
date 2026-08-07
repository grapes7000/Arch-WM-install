pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Current conditions
    property string temp: "--"
    property string condition: ""
    property string icon: ""
    property bool available: false
    property string locationName: ""
    property string feelsLike: "--"
    property string humidity: "--"
    property string wind: "--"
    property string sunrise: "--"
    property string sunset: "--"
    property string high: "--"
    property string low: "--"
    property string lastUpdated: ""
    property string error: ""

    // Today's hourly forecast: [{ time: "3 AM", temp: "19°", icon: "..." }]
    property var hourly: []
    // 10-day forecast: [{ day: "Today", icon, condition, high, low }]
    property var daily: []
    property bool forecastAvailable: false

    property real latitude: NaN
    property real longitude: NaN

    // Maps wttr.in weather codes to Nerd Font weather glyphs.
    function codeIcon(code) {
        code = Number(code)
        if (code === 113) return "󰖙"                    // Clear
        if (code === 116) return "󰖕"                    // Partly cloudy
        if (code === 119 || code === 122) return "󰖐"   // Cloudy / Overcast
        if (code === 143 || code === 248 || code === 260) return "󰖑"  // Mist / Fog
        if (code === 200 || (code >= 386 && code <= 395)) return "󰖓"  // Thunder
        if (code === 176 || (code >= 263 && code <= 320)
                || (code >= 353 && code <= 359)) return "󰖖"  // Drizzle / Rain
        if (code === 179 || code === 182 || code === 185 || code === 227
                || code === 230 || (code >= 323 && code <= 350)
                || (code >= 362 && code <= 377)) return "󰖘"  // Snow / Sleet
        return "󰖐"
    }

    // Maps Open-Meteo WMO codes to Nerd Font weather glyphs.
    function wmoIcon(code) {
        code = Number(code)
        if (code === 0) return "󰖙"                      // Clear sky
        if (code === 1 || code === 2) return "󰖕"        // Mainly / Partly cloudy
        if (code === 3) return "󰖐"                      // Overcast
        if (code === 45 || code === 48) return "󰖑"     // Fog
        if (code >= 51 && code <= 57) return "󰖖"        // Drizzle
        if (code >= 61 && code <= 67) return "󰖖"        // Rain
        if (code >= 71 && code <= 77) return "󰖘"        // Snow
        if (code >= 80 && code <= 82) return "󰖖"        // Rain showers
        if (code === 85 || code === 86) return "󰖘"     // Snow showers
        if (code >= 95) return "󰖓"                      // Thunderstorm
        return "󰖐"
    }

    function wmoLabel(code) {
        code = Number(code)
        if (code === 0) return "Clear"
        if (code === 1) return "Mainly clear"
        if (code === 2) return "Partly cloudy"
        if (code === 3) return "Overcast"
        if (code === 45 || code === 48) return "Fog"
        if (code >= 51 && code <= 57) return "Drizzle"
        if (code >= 61 && code <= 67) return "Rain"
        if (code >= 71 && code <= 77) return "Snow"
        if (code >= 80 && code <= 82) return "Showers"
        if (code === 85 || code === 86) return "Snow showers"
        if (code >= 95) return "Thunderstorm"
        return "Unknown"
    }

    // wttr.in j1 hourly times arrive as "0", "300", "600", ... (HHMM without
    // leading zeroes). Turn them into "3 AM" style labels.
    function hourLabel(value) {
        const padded = ("0000" + String(value)).slice(-4)
        let hour = Number(padded.slice(0, 2))
        const suffix = hour < 12 ? "AM" : "PM"
        hour = hour % 12 || 12
        return hour + " " + suffix
    }

    // Open-Meteo daily dates arrive as "2026-08-07". The first entry is today.
    function dayLabel(dateStr, index) {
        if (index === 0) return "Today"
        const parts = dateStr.split("-")
        const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
        return date.toLocaleDateString(undefined, { weekday: "short" })
    }

    function parseCurrent(contents) {
        let json
        try {
            json = JSON.parse(contents)
        } catch (failure) {
            if (!root.available) root.error = "Malformed current weather"
            return false
        }
        const current = json.current_condition && json.current_condition[0]
        if (!current) {
            if (!root.available) root.error = "Missing current conditions"
            return false
        }
        root.temp = Math.round(Number(current.temp_C)) + "°"
        root.condition = current.weatherDesc && current.weatherDesc[0]
            ? String(current.weatherDesc[0].value).trim() : ""
        root.icon = root.codeIcon(current.weatherCode)
        root.feelsLike = Math.round(Number(current.FeelsLikeC)) + "°"
        root.humidity = current.humidity + "%"
        root.wind = current.windspeedKmph + " km/h"

        const area = json.nearest_area && json.nearest_area[0]
        if (area) {
            root.locationName = area.areaName && area.areaName[0]
                ? String(area.areaName[0].value).trim() : ""
            root.latitude = Number(area.latitude)
            root.longitude = Number(area.longitude)
        }

        const today = json.weather && json.weather[0]
        if (today) {
            root.high = Math.round(Number(today.maxtempC)) + "°"
            root.low = Math.round(Number(today.mintempC)) + "°"
            const astronomy = today.astronomy && today.astronomy[0]
            if (astronomy) {
                root.sunrise = astronomy.sunrise || "--"
                root.sunset = astronomy.sunset || "--"
            }
            const hours = []
            if (Array.isArray(today.hourly)) {
                for (const slot of today.hourly) {
                    hours.push({
                        time: root.hourLabel(slot.time),
                        temp: Math.round(Number(slot.tempC)) + "°",
                        icon: root.codeIcon(slot.weatherCode)
                    })
                }
            }
            root.hourly = hours
        }

        root.available = true
        root.lastUpdated = new Date().toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit"
        })
        root.error = ""
        return true
    }

    function parseForecast(contents) {
        let json
        try {
            json = JSON.parse(contents)
        } catch (failure) {
            return false
        }
        const daily = json.daily
        if (!daily || !Array.isArray(daily.time) || !Array.isArray(daily.weather_code))
            return false
        const days = []
        const count = Math.min(daily.time.length, 10)
        for (let i = 0; i < count; i++) {
            days.push({
                day: root.dayLabel(daily.time[i], i),
                icon: root.wmoIcon(daily.weather_code[i]),
                condition: root.wmoLabel(daily.weather_code[i]),
                high: Math.round(Number(daily.temperature_2m_max[i])) + "°",
                low: Math.round(Number(daily.temperature_2m_min[i])) + "°"
            })
        }
        root.daily = days
        root.forecastAvailable = days.length > 0
        root.error = ""
        return true
    }

    function refresh() {
        if (currentProc.running) return false
        currentProc.running = true
        watchdog.restart()
        return true
    }

    function fetchForecast() {
        if (!Number.isFinite(root.latitude) || !Number.isFinite(root.longitude))
            return
        if (forecastProc.running) return
        forecastProc.command = [
            "sh", "-c",
            "curl -sf --max-time 15 'https://api.open-meteo.com/v1/forecast?latitude="
            + root.latitude + "&longitude=" + root.longitude
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&timezone=auto&forecast_days=10' 2>/dev/null || exit 0"
        ]
        forecastProc.running = true
        // The current-weather fetch may have used most of the watchdog budget;
        // give the chained forecast fetch its own window to complete in.
        watchdog.restart()
    }

    Process {
        id: currentProc
        command: [
            "sh", "-c",
            "curl -sf --max-time 15 'wttr.in/?format=j1' 2>/dev/null || exit 0"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.parseCurrent(text))
                    root.fetchForecast()
            }
        }
        onExited: (exitCode, exitStatus) => {
            // curl failures produce empty stdout (guarded by "|| exit 0"), so
            // parseCurrent reports the error; nothing else to do here. The
            // watchdog stays armed: fetchForecast() restarted it for the
            // chained forecast fetch that follows this exit.
            if (exitCode !== 0 && !root.available)
                root.error = "Weather fetch failed (exit " + exitCode + ")"
        }
    }

    Process {
        id: forecastProc
        stdout: StdioCollector {
            onStreamFinished: root.parseForecast(text)
        }
        onExited: (exitCode, exitStatus) => {
            watchdog.stop()
            if (exitCode !== 0 && !root.forecastAvailable)
                root.error = "Forecast fetch failed (exit " + exitCode + ")"
        }
    }

    Timer {
        id: watchdog
        interval: 15000
        onTriggered: {
            if (currentProc.running) currentProc.running = false
            if (forecastProc.running) forecastProc.running = false
            if (!root.available) root.error = "Weather fetch timed out"
        }
    }

    // Poll every 10 minutes: current conditions come from wttr.in and the
    // 10-day forecast is chained from the location it reports.
    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
