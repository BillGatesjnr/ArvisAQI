import 'package:flutter/material.dart';

class AirQualityData {
  final double aqi;
  final String category;
  final Color color;
  final String city;
  final String description;
  final Map<String, double>? pollutants;
  final List<double> historicalAqi;
  final DateTime timestamp;
  final String? dataSource;
  final String? aqiMethod;
  final double longitude;
  final double latitude;

  AirQualityData({
    required this.aqi,
    required this.category,
    required this.color,
    required this.city,
    required this.description,
    this.pollutants,
    required this.historicalAqi,
    required this.timestamp,
    this.dataSource,
    this.aqiMethod,
    required this.longitude,
    required this.latitude,
  });

  static String getCategory(double aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  static Color getColor(double aqi) {
    if (aqi <= 50) return const Color(0xFF009966);
    if (aqi <= 100) return const Color(0xFFFFDE33);
    if (aqi <= 150) return const Color(0xFFFF9933);
    if (aqi <= 200) return const Color(0xFFCC0033);
    if (aqi <= 300) return const Color(0xFF660099);
    return const Color(0xFF7E0023);
  }

  static String getDescription(double aqi) {
    if (aqi <= 50) return 'Air quality is satisfactory';
    if (aqi <= 100) return 'Air quality is acceptable';
    if (aqi <= 150) return 'Sensitive groups may experience health effects';
    if (aqi <= 200) return 'Everyone may begin to experience health effects';
    if (aqi <= 300) return 'Health warnings of emergency conditions';
    return 'Health alert: everyone may experience serious health effects';
  }

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    return AirQualityData(
      aqi: (json['aqi'] as num).toDouble(),
      category: getCategory((json['aqi'] as num).toDouble()),
      color: getColor((json['aqi'] as num).toDouble()),
      city: json['city'] ?? 'Unknown',
      description: getDescription((json['aqi'] as num).toDouble()),
      pollutants: json['pollutants'] != null
          ? Map<String, double>.from(json['pollutants'])
          : null,
      historicalAqi: json['historicalAqi'] != null
          ? List<double>.from(json['historicalAqi'])
          : <double>[],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      dataSource: json['dataSource'],
      aqiMethod: json['aqiMethod'],
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aqi': aqi,
      'category': category,
      'color': color.value,
      'city': city,
      'description': description,
      'pollutants': pollutants,
      'historicalAqi': historicalAqi,
      'timestamp': timestamp.toIso8601String(),
      'dataSource': dataSource,
      'aqiMethod': aqiMethod,
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}
