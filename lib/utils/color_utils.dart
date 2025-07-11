// File: lib/utils/color_utils.dart
import 'package:flutter/material.dart';

class ColorUtils {
  
  /// Convert hex color string to Flutter Color
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
    }
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Get AQI color based on AQI value
  static Color getAqiColor(double aqi) {
    if (aqi <= 50) return const Color(0xFF00E400); // Good - Green
    if (aqi <= 100) return const Color(0xFFFFFF00); // Moderate - Yellow
    if (aqi <= 150)
      return const Color(0xFFFF7E00); // Unhealthy for Sensitive Groups - Orange
    if (aqi <= 200) return const Color(0xFFFF0000); // Unhealthy - Red
    if (aqi <= 300) return const Color(0xFF8F3F97); // Very Unhealthy - Purple
    return const Color(0xFF7E0023); // Hazardous - Maroon
  }

  /// Get AQI category based on AQI value
  static String getAqiCategory(double aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  /// Get AQI description based on AQI value
  static String getAqiDescription(double aqi) {
    if (aqi <= 50)
      return 'Air quality is considered satisfactory, and air pollution poses little or no risk.';
    if (aqi <= 100)
      return 'Air quality is acceptable; however, some pollutants may be a concern for a small number of people.';
    if (aqi <= 150)
      return 'Members of sensitive groups may experience health effects. The general public is not likely to be affected.';
    if (aqi <= 200)
      return 'Everyone may begin to experience health effects; members of sensitive groups may experience more serious effects.';
    if (aqi <= 300)
      return 'Health warnings of emergency conditions. The entire population is more likely to be affected.';
    return 'Health alert: everyone may experience more serious health effects.';
  }
  
}
