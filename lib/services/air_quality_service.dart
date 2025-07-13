import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/air_quality_data.dart';

class AirQualityService {
  static Future<AirQualityData?> fetchAirQualityByCoordinates(
      double lat, double lng) async {
    try {
      // Try OpenWeatherMap first
      final openWeatherData = await _fetchFromOpenWeatherMap(lat, lng);
      if (openWeatherData != null) return openWeatherData;

      // Fallback to WAQI if OpenWeatherMap fails
      final waqiData = await _fetchFromWAQI(lat, lng);
      if (waqiData != null) return waqiData;

      // If both APIs fail, use realistic mock data
      return _getRealisticMockData(
          lat, lng, await _getCityNameFromCoordinates(lat, lng));
    } catch (e) {
      print('Error fetching air quality: $e');
      return _getRealisticMockData(lat, lng, 'Current Location');
    }
  }

  static Future<AirQualityData?> _fetchFromOpenWeatherMap(
      double lat, double lng) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lng&appid=$apiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final cityName = await _getCityNameFromCoordinates(lat, lng);

      return AirQualityData(
        aqi: _calculateAQIFromPM25(jsonData['list'][0]['components']['pm2_5']),
        category: AirQualityData.getCategory(
            _calculateAQIFromPM25(jsonData['list'][0]['components']['pm2_5'])),
        color: AirQualityData.getColor(
            _calculateAQIFromPM25(jsonData['list'][0]['components']['pm2_5'])),
        description: AirQualityData.getDescription(
            _calculateAQIFromPM25(jsonData['list'][0]['components']['pm2_5'])),
        pollutants: {
          'pm25': jsonData['list'][0]['components']['pm2_5'].toDouble(),
          'pm10': jsonData['list'][0]['components']['pm10'].toDouble(),
          'o3': jsonData['list'][0]['components']['o3'].toDouble(),
          'no2': jsonData['list'][0]['components']['no2'].toDouble(),
          'so2': jsonData['list'][0]['components']['so2'].toDouble(),
          'co': jsonData['list'][0]['components']['co'].toDouble(),
        },
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            jsonData['list'][0]['dt'] * 1000),
        latitude: lat,
        longitude: lng,
        city: cityName,
        dataSource: 'OpenWeatherMap',
        aqiMethod: 'US EPA Standard',
        historicalAqi: [],
      );
    }
    return null;
  }

  static Future<AirQualityData?> _fetchFromWAQI(double lat, double lng) async {
    final token = dotenv.env['WAQI_API_KEY'] ?? 'demo';
    final url =
        Uri.parse('https://api.waqi.info/feed/geo:$lat;$lng/?token=$token');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] != 'ok') return null;

      final data = jsonData['data'];
      final aqi = data['aqi'] is int ? data['aqi'].toDouble() : data['aqi'];

      return AirQualityData(
        aqi: aqi,
        category: AirQualityData.getCategory(aqi),
        color: AirQualityData.getColor(aqi),
        description: AirQualityData.getDescription(aqi),
        pollutants: {
          'pm25': data['iaqi']['pm25']?['v']?.toDouble() ?? 0.0,
          'pm10': data['iaqi']['pm10']?['v']?.toDouble() ?? 0.0,
          'o3': data['iaqi']['o3']?['v']?.toDouble() ?? 0.0,
          'no2': data['iaqi']['no2']?['v']?.toDouble() ?? 0.0,
          'so2': data['iaqi']['so2']?['v']?.toDouble() ?? 0.0,
          'co': data['iaqi']['co']?['v']?.toDouble() ?? 0.0,
        },
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(data['time']['v'] * 1000),
        latitude: lat,
        longitude: lng,
        city: data['city']['name'] ?? 'Unknown',
        dataSource: 'WAQI',
        aqiMethod: 'Ground Stations',
        historicalAqi: [],
      );
    }
    return null;
  }

  static Future<String> _getCityNameFromCoordinates(
      double lat, double lng) async {
    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return 'Current Location';

      final url = Uri.parse(
          'https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lng&limit=1&appid=$apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is List && jsonData.isNotEmpty) {
          return jsonData[0]['name'] ?? 'Current Location';
        }
      }
    } catch (e) {
      print('Error getting city name: $e');
    }
    return 'Current Location';
  }

  static AirQualityData _getRealisticMockData(
      double lat, double lng, String city) {
    final baseAqi = 30.0 + Random().nextDouble() * 50.0;
    return AirQualityData(
      aqi: baseAqi,
      category: AirQualityData.getCategory(baseAqi),
      color: AirQualityData.getColor(baseAqi),
      description: AirQualityData.getDescription(baseAqi),
      pollutants: {
        'pm25': 10.0 + Random().nextDouble() * 30.0,
        'pm10': 15.0 + Random().nextDouble() * 40.0,
        'o3': 20.0 + Random().nextDouble() * 30.0,
        'no2': 5.0 + Random().nextDouble() * 15.0,
        'so2': 2.0 + Random().nextDouble() * 8.0,
        'co': 300.0 + Random().nextDouble() * 200.0,
      },
      timestamp: DateTime.now(),
      latitude: lat,
      longitude: lng,
      city: city,
      dataSource: 'Mock Data',
      aqiMethod: 'Simulated',
      historicalAqi: [],
    );
  }

  static double _calculateAQIFromPM25(double pm25) {
    // US EPA AQI calculation for PM2.5
    if (pm25 <= 12.0) return (pm25 / 12.0) * 50.0;
    if (pm25 <= 35.4) return 51.0 + ((pm25 - 12.1) / (35.4 - 12.1)) * 49.0;
    if (pm25 <= 55.4) return 101.0 + ((pm25 - 35.5) / (55.4 - 35.5)) * 49.0;
    if (pm25 <= 150.4) return 151.0 + ((pm25 - 55.5) / (150.4 - 55.5)) * 49.0;
    if (pm25 <= 250.4) return 201.0 + ((pm25 - 150.5) / (250.4 - 150.5)) * 99.0;
    if (pm25 <= 500.4) {
      return 301.0 + ((pm25 - 250.5) / (500.4 - 250.5)) * 199.0;
    }
    return 500.0;
  }

  static AirQualityData getMockData() {
    return _getRealisticMockData(5.6037, -0.1870, 'Accra');
  }

  static List<AirQualityData> getHistoricalData() {
    return List.generate(24, (index) {
      final hourAgo = DateTime.now().subtract(Duration(hours: index));
      final aqi =
          30 + Random().nextInt(70) + (10 * sin(index * pi / 6)).toInt();
      return AirQualityData(
        aqi: aqi.toDouble(),
        category: AirQualityData.getCategory(aqi.toDouble()),
        color: AirQualityData.getColor(aqi.toDouble()),
        description: AirQualityData.getDescription(aqi.toDouble()),
        pollutants: {
          'pm25': 5 + Random().nextInt(30).toDouble(),
          'pm10': 10 + Random().nextInt(50).toDouble(),
          'o3': 20 + Random().nextInt(40).toDouble(),
          'no2': 5 + Random().nextInt(20).toDouble(),
          'so2': 1 + Random().nextInt(10).toDouble(),
          'co': 0.1 + Random().nextInt(2).toDouble(),
        },
        timestamp: hourAgo,
        latitude: 5.6037,
        longitude: -0.1870,
        city: 'Accra',
        dataSource: 'Mock Data',
        aqiMethod: 'Simulated',
        historicalAqi: [],
      );
    });
  }
}
