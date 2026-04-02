pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string icon: "󰖙"
    property int temp: 0
    property string condition: "Loading..."
    property int humidity: 0
    property int windSpeed: 0
    property string city: "Unknown"
    property bool ready: false

    property var _lat: null
    property var _lon: null

    function update() {
        if (_lat === null || _lon === null) {
            fetchLocation();
        } else {
            fetchWeather(_lat, _lon);
        }
    }

    function fetchLocation() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "http://ip-api.com/json/");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    if (data && data.status === "success") {
                        root._lat = data.lat;
                        root._lon = data.lon;
                        root.city = data.city || "Unknown";
                        fetchWeather(data.lat, data.lon);
                    }
                } catch(e) { console.log("Location Parse Error:", e) }
            }
        };
        xhr.send();
    }

    function fetchWeather(lat, lon) {
        const xhr = new XMLHttpRequest();
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=auto`;
        
        xhr.open("GET", url);
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    if (data && data.current) {
                        const current = data.current;

                        const rawTemp = Math.round(current.temperature_2m ?? 0);
                        root.temp = rawTemp;
                        
                        const rawHum = current.relative_humidity_2m ?? 0;
                        root.humidity = rawHum | 0;
                        
                        const rawWind = Math.round(current.wind_speed_10m ?? 0);
                        root.windSpeed = rawWind | 0;
                        
                        root.icon = _getIcon(current.weather_code);
                        root.condition = _getConditionString(current.weather_code);
                        root.ready = true
                    }
                } catch(e) { console.log("Weather Parse Error:", e) }
            }
        };
        xhr.send();
    }

    function _getIcon(code) {
        if (code === 0) return "󰖙" 
        if (code >= 1 && code <= 3) return "󰖕" 
        if (code >= 45 && code <= 48) return "󰖑" 
        if (code >= 51 && code <= 67) return "󰖗" 
        if (code >= 71 && code <= 77) return "󰖘" 
        if (code >= 80 && code <= 82) return "󰖖" 
        if (code >= 95) return "󰖓" 
        return "󰖙"
    }

    function _getConditionString(code) {
        const map = {
            0: "Clear", 1: "Mainly Clear", 2: "Partly Cloudy", 3: "Overcast",
            45: "Foggy", 48: "Rime Fog", 51: "Light Drizzle", 61: "Rain",
            71: "Snow", 80: "Rain Showers", 95: "Thunderstorm"
        };
        return map[code] || "Clear"
    }

    Component.onCompleted: update()

    Timer {
        interval: 1000 * 60 * 30 
        running: true
        repeat: true
        onTriggered: update()
    }
}