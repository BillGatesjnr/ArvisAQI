# Air Quality API Integration Guide

## Overview

The ArvisAQI app now fetches real air quality data from global APIs. The implementation includes:

- **Multiple API Sources**: WAQI (World Air Quality Index) and OpenWeatherMap APIs
- **Fallback System**: Mock data when APIs are unavailable
- **Real-time Updates**: Current location-based air quality data
- **Historical Data**: 24-hour trend visualization
- **Pollutant Details**: Individual pollutant measurements (PM2.5, PM10, O₃, NO₂, SO₂, CO)

## API Sources

### 1. WAQI API (Primary)
- **URL**: `https://api.waqi.info/feed`
- **Free Tier**: Yes, with demo token
- **Rate Limit**: Limited for demo token
- **Coverage**: Global
- **Data**: Real-time AQI and pollutant levels

### 2. OpenWeatherMap API (Fallback)
- **URL**: `https://api.openweathermap.org/data/2.5/air_pollution`
- **Free Tier**: Yes (limited calls)
- **API Key**: Optional (add to `_openWeatherApiKey` in service)
- **Coverage**: Global
- **Data**: Air pollution data

## Implementation Details

### Files Created/Modified

1. **`lib/models/air_quality_data.dart`**
   - Data model for air quality information
   - Handles multiple API response formats
   - Includes AQI categorization and color coding

2. **`lib/services/air_quality_service.dart`**
   - API service for fetching data
   - Handles both coordinate and city-based queries
   - Includes fallback to mock data

3. **`lib/providers/air_quality_provider.dart`**
   - State management using Provider
   - Handles location permissions
   - Manages loading states and errors

4. **`lib/utils/color_utils.dart`**
   - Color utilities for AQI visualization
   - Hex to Color conversion
   - AQI category helpers

5. **`lib/screens/dashboard_screen.dart`**
   - Updated to use real data
   - Shows loading states and error handling
   - Displays pollutant details and trends

### Key Features

#### Real-time Data Fetching
```dart
// Fetch data for current location
await context.read<AirQualityProvider>().fetchCurrentLocationData();

// Fetch data for specific city
await context.read<AirQualityProvider>().fetchCityData('London');
```

#### Error Handling
- Network connectivity issues
- API rate limiting
- Location permission denials
- Graceful fallback to mock data

#### Data Visualization
- AQI gauge with color coding
- 24-hour trend graph
- Pollutant breakdown grid
- Min/Average/Max statistics

## Usage Instructions

### For Users
1. **Location Permission**: Grant location access when prompted
2. **Data Loading**: Wait for initial data fetch (shows loading indicator)
3. **Refresh**: Tap refresh button to update data
4. **Error Handling**: If API fails, app shows demo data with warning

### For Developers

#### Adding API Keys (Optional)
To increase API limits, add your API keys:

```dart
// In lib/services/air_quality_service.dart
static const String _openWeatherApiKey = 'your_api_key_here';
```

#### Customizing Data Sources
Add new API endpoints in `AirQualityService`:

```dart
static Future<AirQualityData?> fetchFromCustomAPI() async {
  // Your custom API implementation
}
```

#### Extending Data Model
Add new fields to `AirQualityData`:

```dart
class AirQualityData {
  // Existing fields...
  final Map<String, dynamic> additionalData;
  
  // Update fromJson factory
}
```

## AQI Categories

| AQI Range | Category | Color | Description |
|-----------|----------|-------|-------------|
| 0-50 | Good | Green | Satisfactory air quality |
| 51-100 | Moderate | Yellow | Acceptable with some concerns |
| 101-150 | Unhealthy for Sensitive Groups | Orange | Sensitive groups affected |
| 151-200 | Unhealthy | Red | Everyone may be affected |
| 201-300 | Very Unhealthy | Purple | Health warnings |
| 301+ | Hazardous | Maroon | Health alert |

## Pollutant Measurements

- **PM2.5**: Fine particulate matter (μg/m³)
- **PM10**: Coarse particulate matter (μg/m³)
- **O₃**: Ozone (ppb)
- **NO₂**: Nitrogen dioxide (ppb)
- **SO₂**: Sulfur dioxide (ppb)
- **CO**: Carbon monoxide (ppb)

## Troubleshooting

### Common Issues

1. **"Using demo data - API unavailable"**
   - Check internet connection
   - API may be rate limited
   - Try refreshing data

2. **"Location permissions are denied"**
   - Enable location services
   - Grant app location permission
   - Try fetching by city name instead

3. **"No data available"**
   - Check if location services are enabled
   - Verify internet connection
   - Try manual refresh

### Debug Mode
Enable debug logging by adding print statements in `AirQualityService`:

```dart
print('API Response: ${response.body}');
```

## Future Enhancements

1. **Caching**: Implement local data caching
2. **Multiple Cities**: Save favorite locations
3. **Notifications**: Air quality alerts
4. **Historical Data**: Extended time series
5. **Offline Mode**: Cached data when offline
6. **Custom APIs**: Support for local air quality stations

## API Documentation Links

- [WAQI API Documentation](https://aqicn.org/api/)
- [OpenWeatherMap Air Pollution API](https://openweathermap.org/api/air-pollution)
- [EPA Air Quality Index](https://www.airnow.gov/aqi/aqi-basics/)

## Support

For issues or questions about the API integration:
1. Check the troubleshooting section
2. Review API documentation
3. Test with different locations
4. Verify network connectivity 