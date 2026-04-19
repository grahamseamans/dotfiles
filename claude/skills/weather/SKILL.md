---
name: weather
description: Get current weather for the location set in WEATHER_LAT/WEATHER_LON env vars.
user-invocable: true
---

# Weather

Requires `WEATHER_LAT` and `WEATHER_LON` env vars (set in shell). If they're
not set, say so and stop — don't fall back to a default location.

```bash
if [ -z "$WEATHER_LAT" ] || [ -z "$WEATHER_LON" ]; then
    echo "Set WEATHER_LAT and WEATHER_LON env vars in your shell."
    exit 1
fi
FORECAST_URL=$(curl -s "https://api.weather.gov/points/${WEATHER_LAT},${WEATHER_LON}" | jq -r '.properties.forecast')
curl -s "$FORECAST_URL" | jq -r '.properties.periods[:3][] | "\(.name): \(.shortForecast), \(.temperature)°\(.temperatureUnit). Wind: \(.windSpeed) \(.windDirection)."'
```

National Weather Service API, no key needed. Show the output directly —
no extra commentary needed.
