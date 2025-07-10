import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/air_quality_data.dart';

class AirQualityService {
  // Multiple API endpoints for better coverage
  static const String _waqiBaseUrl = 'https://api.waqi.info/feed';
  static const String _openWeatherBaseUrl =
      'https://api.openweathermap.org/data/2.5/air_pollution';
  static const String _airVisualBaseUrl = 'http://api.airvisual.com/v2';

  // API Keys loaded from .env
  static String get _openWeatherApiKey =>
      dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static String get _airVisualApiKey => dotenv.env['AIRVISUAL_API_KEY'] ?? '';

  // Major Ghanaian cities for fallback data
  static const List<String> ghanaCities = [
    'Accra',
    'Kumasi',
    'Tamale',
    'Sekondi-Takoradi',
    'Ashaiman',
    'Tema',
    'Cape Coast',
    'Obuasi',
    'Teshie',
    'Madina',
    'Koforidua',
    'Wa',
    'Ho',
    'Sunyani',
    'Bolgatanga',
    'Techiman',
    'Nkawkaw',
    'Hohoe',
    'Yendi',
    'Aflao'
  ];

  // Ghana coordinates (approximate center)
  static const double ghanaCenterLat = 7.9465;
  static const double ghanaCenterLon = -1.0232;

  /// Fetch air quality data by coordinates using multiple APIs
  static Future<AirQualityData?> fetchAirQualityByCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      print(
          'DEBUG: Fetching air quality for coordinates: $latitude, $longitude');

      // Try multiple APIs in sequence for better accuracy
      // No location restrictions - let APIs return real data for actual location

      // 1. Try AirVisual API first (has excellent global coverage and accuracy)
      if (_airVisualApiKey.isNotEmpty) {
        print('DEBUG: Trying AirVisual API first...');
        final airVisualData = await _fetchFromAirVisual(latitude, longitude);
        if (airVisualData != null) {
          print(
              'DEBUG: AirVisual returned valid data: AQI ${airVisualData.aqi} for ${airVisualData.city}');
          return airVisualData;
        }
      }

      // 2. Try WAQI API for the nearest city
      final nearestCity = _findNearestCity(latitude, longitude);
      print('DEBUG: Trying WAQI API for nearest city: $nearestCity');
      final waqiData = await _fetchFromWAQI(nearestCity);
      if (waqiData != null) {
        print(
            'DEBUG: WAQI returned valid data: AQI ${waqiData.aqi} for ${waqiData.city}');
        return waqiData;
      }

      // 3. Try OpenWeatherMap API as last resort (has good global coverage)
      if (_openWeatherApiKey.isNotEmpty) {
        print('DEBUG: Trying OpenWeatherMap API with key...');
        final openWeatherData =
            await _fetchFromOpenWeatherMap(latitude, longitude);
        if (openWeatherData != null) {
          print(
              'DEBUG: OpenWeatherMap returned valid data: AQI ${openWeatherData.aqi} for ${openWeatherData.city}');
          return openWeatherData;
        }
      }

      // 4. Try OpenWeatherMap without key as final fallback
      print('DEBUG: Trying OpenWeatherMap API without key...');
      final openWeatherData =
          await _fetchFromOpenWeatherMap(latitude, longitude);
      if (openWeatherData != null) {
        print(
            'DEBUG: OpenWeatherMap returned valid data: AQI ${openWeatherData.aqi} for ${openWeatherData.city}');
        return openWeatherData;
      }

      // If all APIs fail, use realistic mock data for the actual location
      print(
          'DEBUG: All APIs failed, using realistic mock data for actual location');
      return _getRealisticMockData(latitude, longitude, nearestCity);
    } catch (e) {
      print('DEBUG: Error fetching air quality data: $e');
      return _getRealisticMockData(latitude, longitude, 'Unknown Location');
    }
  }

  /// Fetch air quality data by city name using multiple APIs
  static Future<AirQualityData?> fetchAirQualityByCity(String city) async {
    try {
      print('DEBUG: Fetching data for city: $city');

      // Try multiple APIs for the city

      // 1. Try AirVisual API first (has excellent global coverage and accuracy)
      if (_airVisualApiKey.isNotEmpty) {
        print('DEBUG: Trying AirVisual API for city: $city');
        // AirVisual doesn't support city search directly, so we'll use coordinates
        // For now, we'll use the city's approximate coordinates
        final cityCoords = _getCityCoordinates(city);
        if (cityCoords != null) {
          final airVisualData =
              await _fetchFromAirVisual(cityCoords[0], cityCoords[1]);
          if (airVisualData != null) {
            print(
                'DEBUG: AirVisual returned valid data for $city: AQI ${airVisualData.aqi}');
            return airVisualData;
          }
        }
      }

      // 2. Try WAQI API
      print('DEBUG: Trying WAQI API for city: $city');
      final waqiData = await _fetchFromWAQI(city);
      if (waqiData != null) {
        print('DEBUG: WAQI returned valid data for $city: AQI ${waqiData.aqi}');
        return waqiData;
      }

      // 3. Try OpenWeatherMap API as last resort
      if (_openWeatherApiKey.isNotEmpty) {
        print('DEBUG: Trying OpenWeatherMap API for city: $city');
        final cityCoords = _getCityCoordinates(city);
        if (cityCoords != null) {
          final openWeatherData =
              await _fetchFromOpenWeatherMap(cityCoords[0], cityCoords[1]);
          if (openWeatherData != null) {
            print(
                'DEBUG: OpenWeatherMap returned valid data for $city: AQI ${openWeatherData.aqi}');
            return openWeatherData;
          }
        }
      }

      // If all APIs fail, return realistic mock data
      print('DEBUG: All APIs failed for $city, using realistic mock data');
      final cityCoords = _getCityCoordinates(city);
      if (cityCoords != null) {
        return _getRealisticMockData(cityCoords[0], cityCoords[1], city);
      }

      return null;
    } catch (e) {
      print('DEBUG: Error fetching air quality data for city: $e');
      return null;
    }
  }

  /// Fetch data from OpenWeatherMap API
  static Future<AirQualityData?> _fetchFromOpenWeatherMap(
      double latitude, double longitude) async {
    try {
      final url = _openWeatherApiKey.isNotEmpty
          ? '$_openWeatherBaseUrl?lat=$latitude&lon=$longitude&appid=$_openWeatherApiKey'
          : '$_openWeatherBaseUrl?lat=$latitude&lon=$longitude';

      print('DEBUG: OpenWeather URL: $url');
      final response = await http.get(Uri.parse(url));

      print('DEBUG: OpenWeather response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(
            'DEBUG: OpenWeather response data: ${jsonData.toString().substring(0, jsonData.toString().length > 500 ? 500 : jsonData.toString().length)}...');

        // Get city name from coordinates using reverse geocoding
        final cityName = await _getCityNameFromCoordinates(latitude, longitude);
        print('DEBUG: Reverse geocoded city name: $cityName');

        final airQualityData = AirQualityData.fromJson(jsonData);

        // Log PM2.5 and AQI calculation details
        print(
            'DEBUG: OpenWeatherMap PM2.5: ${airQualityData.pollutants['pm25']} μg/m³');
        print('DEBUG: Calculated AQI from PM2.5: ${airQualityData.aqi}');

        // Create a new AirQualityData object with the correct city name and attribution
        final correctedData = AirQualityData(
          aqi: airQualityData.aqi,
          category: airQualityData.category,
          color: airQualityData.color,
          description: airQualityData.description,
          pollutants: airQualityData.pollutants,
          timestamp: airQualityData.timestamp,
          latitude: airQualityData.latitude,
          longitude: airQualityData.longitude,
          city: cityName,
          dataSource: 'OpenWeatherMap',
          aqiMethod: 'Satellite & Ground Data',
        );

        print('DEBUG: OpenWeather parsed city: ${correctedData.city}');
        return correctedData;
      }
      return null;
    } catch (e) {
      print('DEBUG: Error fetching from OpenWeatherMap: $e');
      return null;
    }
  }

  /// Fetch data from WAQI API
  static Future<AirQualityData?> _fetchFromWAQI(String city) async {
    try {
      final url = '$_waqiBaseUrl/$city/?token=demo';
      print('DEBUG: WAQI URL: $url');
      final response = await http.get(Uri.parse(url));

      print('DEBUG: WAQI response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(
            'DEBUG: WAQI response data: ${jsonData.toString().substring(0, jsonData.toString().length > 500 ? 500 : jsonData.toString().length)}...');

        if (jsonData['status'] == 'ok' && jsonData['data'] != null) {
          final airQualityData = AirQualityData.fromJson(jsonData);
          print('DEBUG: WAQI parsed city: ${airQualityData.city}');
          return airQualityData;
        }
      }
      return null;
    } catch (e) {
      print('DEBUG: Error fetching from WAQI: $e');
      return null;
    }
  }

  /// Fetch data from AirVisual API
  static Future<AirQualityData?> _fetchFromAirVisual(
      double latitude, double longitude) async {
    try {
      final url =
          '$_airVisualBaseUrl/nearest_city?lat=$latitude&lon=$longitude&key=$_airVisualApiKey';
      print('DEBUG: AirVisual URL: $url');
      final response = await http.get(Uri.parse(url));

      print('DEBUG: AirVisual response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(
            'DEBUG: AirVisual response data: ${jsonData.toString().substring(0, jsonData.toString().length > 500 ? 500 : jsonData.toString().length)}...');

        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final data = jsonData['data'];
          final current = data['current'];
          final pollution = current['pollution'];

          final aqi = pollution['aqius']?.toDouble() ?? 0.0;

          return AirQualityData(
            aqi: aqi,
            category: AirQualityData.getCategory(aqi),
            color: AirQualityData.getColor(aqi),
            description: AirQualityData.getDescription(aqi),
            pollutants: _getValidPollutants(pollution),
            timestamp: DateTime.now(),
            latitude: data['location']['coordinates'][1].toDouble(),
            longitude: data['location']['coordinates'][0].toDouble(),
            city: data['city'] ?? 'Unknown',
            dataSource: 'AirVisual (IQAir)',
            aqiMethod: 'Ground Monitoring Network',
          );
        }
      }
      return null;
    } catch (e) {
      print('DEBUG: Error fetching from AirVisual: $e');
      return null;
    }
  }

  /// Extract only valid pollutant data (non-zero values)
  static Map<String, double> _getValidPollutants(
      Map<String, dynamic> pollution) {
    final Map<String, double> validPollutants = {};

    // Only include pollutants that have actual values (not null or zero)
    if (pollution['pm25'] != null && pollution['pm25'] > 0) {
      validPollutants['pm25'] = pollution['pm25'].toDouble();
    }
    if (pollution['pm10'] != null && pollution['pm10'] > 0) {
      validPollutants['pm10'] = pollution['pm10'].toDouble();
    }
    if (pollution['o3'] != null && pollution['o3'] > 0) {
      validPollutants['o3'] = pollution['o3'].toDouble();
    }
    if (pollution['no2'] != null && pollution['no2'] > 0) {
      validPollutants['no2'] = pollution['no2'].toDouble();
    }
    if (pollution['so2'] != null && pollution['so2'] > 0) {
      validPollutants['so2'] = pollution['so2'].toDouble();
    }
    if (pollution['co'] != null && pollution['co'] > 0) {
      validPollutants['co'] = pollution['co'].toDouble();
    }

    return validPollutants;
  }

  /// Check if coordinates are within Ghana (approximate bounds)
  static bool isWithinGhana(double latitude, double longitude) {
    // Ghana's approximate boundaries
    return latitude >= 4.5 &&
        latitude <= 11.5 &&
        longitude >= -3.5 &&
        longitude <= 1.5;
  }

  /// Find the nearest major city to the given coordinates (global)
  static String _findNearestCity(double latitude, double longitude) {
    // Major world cities with coordinates
    final cityCoordinates = {
      'Accra': [5.5600, -0.2057],
      'Lagos': [6.5244, 3.3792],
      'Cairo': [30.0444, 31.2357],
      'Johannesburg': [-26.2041, 28.0473],
      'Nairobi': [-1.2921, 36.8219],
      'London': [51.5074, -0.1278],
      'Paris': [48.8566, 2.3522],
      'Berlin': [52.5200, 13.4050],
      'Moscow': [55.7558, 37.6176],
      'New York': [40.7128, -74.0060],
      'Los Angeles': [34.0522, -118.2437],
      'Toronto': [43.6532, -79.3832],
      'Mexico City': [19.4326, -99.1332],
      'São Paulo': [-23.5505, -46.6333],
      'Buenos Aires': [-34.6118, -58.3960],
      'Sydney': [-33.8688, 151.2093],
      'Melbourne': [-37.8136, 144.9631],
      'Tokyo': [35.6762, 139.6503],
      'Beijing': [39.9042, 116.4074],
      'Shanghai': [31.2304, 121.4737],
      'Mumbai': [19.0760, 72.8777],
      'Delhi': [28.7041, 77.1025],
      'Bangkok': [13.7563, 100.5018],
      'Singapore': [1.3521, 103.8198],
      'Jakarta': [-6.2088, 106.8456],
      'Manila': [14.5995, 120.9842],
    };

    String nearestCity = 'Unknown';
    double minDistance = double.infinity;

    for (final entry in cityCoordinates.entries) {
      final cityLat = entry.value[0];
      final cityLon = entry.value[1];

      final distance =
          _calculateDistance(latitude, longitude, cityLat, cityLon);

      if (distance < minDistance) {
        minDistance = distance;
        nearestCity = entry.key;
      }
    }

    return nearestCity;
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(_degreesToRadians(lat1)) *
            sin(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Get Ghana-specific mock data
  static AirQualityData _getGhanaMockData(
      double latitude, double longitude, String city) {
    // Generate realistic AQI values for Ghana based on city
    // Different cities have different typical AQI ranges
    // Updated to match more realistic values like Plume Labs shows
    double baseAqi;

    switch (city.toLowerCase()) {
      case 'accra':
        baseAqi = 20.0 +
            (DateTime.now().millisecond % 15); // 20-35 (good to moderate)
        break;
      case 'kumasi':
        baseAqi = 25.0 +
            (DateTime.now().millisecond % 20); // 25-45 (good to moderate)
        break;
      case 'tema':
        baseAqi = 30.0 + (DateTime.now().millisecond % 15); // 30-45 (moderate)
        break;
      case 'tamale':
        baseAqi = 15.0 +
            (DateTime.now().millisecond % 20); // 15-35 (good to moderate)
        break;
      case 'sekondi-takoradi':
        baseAqi = 18.0 +
            (DateTime.now().millisecond % 17); // 18-35 (good to moderate)
        break;
      case 'cape coast':
        baseAqi = 12.0 +
            (DateTime.now().millisecond % 18); // 12-30 (good to moderate)
        break;
      default:
        baseAqi = 20.0 +
            (DateTime.now().millisecond % 25); // 20-45 (good to moderate)
    }

    // Add some time-based variation (morning rush hour, evening traffic, etc.)
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour <= 9) {
      baseAqi += 8; // Morning rush hour
    } else if (hour >= 17 && hour <= 19) {
      baseAqi += 12; // Evening rush hour
    }

    return AirQualityData(
      aqi: baseAqi,
      category: AirQualityData.getCategory(baseAqi),
      color: AirQualityData.getColor(baseAqi),
      description: AirQualityData.getDescription(baseAqi),
      pollutants: {
        'pm25': 8.0 + (DateTime.now().millisecond % 12),
        'pm10': 15.0 + (DateTime.now().millisecond % 20),
        'o3': 12.0 + (DateTime.now().millisecond % 15),
        'no2': 10.0 + (DateTime.now().millisecond % 12),
        'so2': 2.0 + (DateTime.now().millisecond % 5),
        'co': 300.0 + (DateTime.now().millisecond % 200),
      },
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      city: city,
      dataSource: 'Mock Data',
      aqiMethod: 'Simulated Estimates',
    );
  }

  /// Get realistic mock data for any location
  static AirQualityData _getRealisticMockData(
      double latitude, double longitude, String city) {
    // Generate realistic AQI values based on typical urban/rural patterns
    double baseAqi;

    // Determine if it's likely an urban or rural area based on coordinates
    // This is a simplified approach - in reality you'd use more sophisticated logic
    final isUrban = _isLikelyUrban(latitude, longitude);

    if (isUrban) {
      // Urban areas typically have higher AQI
      baseAqi = 35.0 +
          (DateTime.now().millisecond %
              40); // 35-75 (moderate to unhealthy for sensitive groups)
    } else {
      // Rural areas typically have lower AQI
      baseAqi =
          15.0 + (DateTime.now().millisecond % 25); // 15-40 (good to moderate)
    }

    // Add some time-based variation
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour <= 9) {
      baseAqi += 10; // Morning rush hour
    } else if (hour >= 17 && hour <= 19) {
      baseAqi += 15; // Evening rush hour
    }

    return AirQualityData(
      aqi: baseAqi,
      category: AirQualityData.getCategory(baseAqi),
      color: AirQualityData.getColor(baseAqi),
      description: AirQualityData.getDescription(baseAqi),
      pollutants: {
        'pm25': 8.0 + (DateTime.now().millisecond % 20),
        'pm10': 15.0 + (DateTime.now().millisecond % 30),
        'o3': 12.0 + (DateTime.now().millisecond % 25),
        'no2': 10.0 + (DateTime.now().millisecond % 20),
        'so2': 2.0 + (DateTime.now().millisecond % 8),
        'co': 300.0 + (DateTime.now().millisecond % 200),
      },
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      city: city,
      dataSource: 'Mock Data',
      aqiMethod: 'Simulated Estimates',
    );
  }

  /// Simple heuristic to determine if coordinates are likely urban
  static bool _isLikelyUrban(double latitude, double longitude) {
    // This is a simplified approach - checks if coordinates are near major cities
    // In a real app, you'd use a more sophisticated geocoding service

    // Major urban areas (simplified bounding boxes)
    final urbanAreas = [
      // Accra area
      [5.4, -0.3, 5.7, -0.1],
      // Lagos area
      [6.4, 3.2, 6.7, 3.5],
      // Cairo area
      [29.9, 31.1, 30.2, 31.4],
      // London area
      [51.4, -0.2, 51.6, 0.0],
      // New York area
      [40.6, -74.1, 40.8, -73.9],
      // Tokyo area
      [35.6, 139.6, 35.7, 139.8],
    ];

    for (final area in urbanAreas) {
      if (latitude >= area[0] &&
          latitude <= area[2] &&
          longitude >= area[1] &&
          longitude <= area[3]) {
        return true;
      }
    }

    return false;
  }

  /// Get mock data for testing when API is unavailable
  static AirQualityData getMockData() {
    return _getGhanaMockData(5.5600, -0.2057, 'Accra');
  }

  /// Get historical data (mock for now, can be extended with paid APIs)
  static List<AirQualityData> getHistoricalData() {
    final now = DateTime.now();
    return List.generate(24, (index) {
      now.subtract(Duration(hours: 23 - index));
// Varying AQI for demo

      return _getGhanaMockData(5.5600, -0.2057, 'Accra');
    });
  }

  /// Helper to get coordinates for a city (approximate)
  static List<double>? _getCityCoordinates(String city) {
    // This is a simplified approach. For accurate coordinates,
    // you'd need a geocoding service or a more extensive database.
    // For now, we'll return approximate coordinates for major cities.
    switch (city.toLowerCase()) {
      case 'accra':
        return [5.5600, -0.2057]; // Accra
      case 'kumasi':
        return [6.6885, -1.6244]; // Kumasi
      case 'tamale':
        return [9.4035, -0.8430]; // Tamale
      case 'sekondi-takoradi':
        return [4.9000, -1.7833]; // Sekondi-Takoradi
      case 'cape coast':
        return [5.1053, -1.2466]; // Cape Coast
      case 'obuasi':
        return [6.2000, -1.6833]; // Obuasi
      case 'tema':
        return [5.6833, -0.0167]; // Tema
      case 'madina':
        return [5.6833, -0.1667]; // Madina
      case 'wa':
        return [10.0667, -2.5000]; // Wa
      case 'ho':
        return [6.6000, 0.4667]; // Ho
      case 'sunyani':
        return [7.3333, -2.3333]; // Sunyani
      case 'bolgatanga':
        return [10.7833, -0.8500]; // Bolgatanga
      case 'techiman':
        return [7.5833, -1.9333]; // Techiman
      case 'nkawkaw':
        return [6.5500, -0.7667]; // Nkawkaw
      case 'hohoe':
        return [7.1500, 0.4667]; // Hohoe
      case 'yendi':
        return [9.4333, -0.0167]; // Yendi
      case 'aflao':
        return [6.1167, 1.1833]; // Aflao
      default:
        // For other cities, return approximate coordinates
        // This is a placeholder and needs a proper geocoding service
        return null;
    }
  }

  /// Get city name from coordinates using OpenWeatherMap reverse geocoding
  static Future<String> _getCityNameFromCoordinates(
      double latitude, double longitude) async {
    try {
      // Use OpenWeatherMap's reverse geocoding API
      final url = _openWeatherApiKey.isNotEmpty
          ? 'http://api.openweathermap.org/geo/1.0/reverse?lat=$latitude&lon=$longitude&limit=1&appid=$_openWeatherApiKey'
          : 'http://api.openweathermap.org/geo/1.0/reverse?lat=$latitude&lon=$longitude&limit=1';

      print('DEBUG: Reverse geocoding URL: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('DEBUG: Reverse geocoding response: ${jsonData.toString()}');

        if (jsonData is List && jsonData.isNotEmpty) {
          final location = jsonData[0];
          final cityName = location['name'] ?? 'Unknown';
          final state = location['state'];
          final country = location['country'];

          // Return the most specific location name available
          if (state != null && state.isNotEmpty) {
            return '$cityName, $state';
          } else if (country != null && country.isNotEmpty) {
            return '$cityName, $country';
          } else {
            return cityName;
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error in reverse geocoding: $e');
    }

    // Fallback: return coordinates if geocoding fails
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}
