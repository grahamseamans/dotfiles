---
name: weather
description: Get current weather for Berkeley, CA.
user-invocable: true
---

# Weather

Run these two commands and display the result:

```bash
FORECAST_URL=$(curl -s "https://api.weather.gov/points/37.8716,-122.2727" | jq -r '.properties.forecast')
curl -s "$FORECAST_URL" | jq -r '.properties.periods[:3][] | "\(.name): \(.shortForecast), \(.temperature)°\(.temperatureUnit). Wind: \(.windSpeed) \(.windDirection)."'
```

National Weather Service API, no key needed. Show the output directly — no extra commentary needed.
