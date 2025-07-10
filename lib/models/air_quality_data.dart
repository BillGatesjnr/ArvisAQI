class AirQualityData {
  final double aqi;
  final String category;
  final String color;
  final String description;
  final Map<String, double> pollutants;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String city;
  final String dataSource;
  final String aqiMethod;

  AirQualityData({
    required this.aqi,
    required this.category,
    required this.color,
    required this.description,
    required this.pollutants,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.dataSource = 'Unknown',
    this.aqiMethod = 'Unknown',
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    // Handle different API response formats
    if (json.containsKey('data')) {
      // WAQI API format
      final data = json['data'];
      final aqi = data['aqi']?.toDouble() ?? 0.0;

      return AirQualityData(
        aqi: aqi,
        category: getCategory(aqi),
        color: getColor(aqi),
        description: getDescription(aqi),
        pollutants: {
          'pm25': data['iaqi']?['pm25']?['v']?.toDouble() ?? 0.0,
          'pm10': data['iaqi']?['pm10']?['v']?.toDouble() ?? 0.0,
          'o3': data['iaqi']?['o3']?['v']?.toDouble() ?? 0.0,
          'no2': data['iaqi']?['no2']?['v']?.toDouble() ?? 0.0,
          'so2': data['iaqi']?['so2']?['v']?.toDouble() ?? 0.0,
          'co': data['iaqi']?['co']?['v']?.toDouble() ?? 0.0,
        },
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(data['time']['v'] * 1000),
        latitude: data['city']['geo'][0].toDouble(),
        longitude: data['city']['geo'][1].toDouble(),
        city: data['city']['name'] ?? 'Unknown',
        dataSource: 'WAQI',
        aqiMethod: 'Ground Monitoring Stations',
      );
    } else if (json.containsKey('list')) {
      // OpenWeatherMap API format
      final data = json['list'][0];
      final components = data['components'];

      // Get PM2.5 value from OpenWeatherMap (in μg/m³)
      final pm25 = components['pm2_5']?.toDouble() ?? 0.0;

      // Calculate AQI using US EPA formula based on PM2.5
      final aqi = _calculateAQIFromPM25(pm25);

      return AirQualityData(
        aqi: aqi,
        category: getCategory(aqi),
        color: getColor(aqi),
        description: getDescription(aqi),
        pollutants: {
          'pm25': pm25,
          'pm10': components['pm10']?.toDouble() ?? 0.0,
          'o3': components['o3']?.toDouble() ?? 0.0,
          'no2': components['no2']?.toDouble() ?? 0.0,
          'so2': components['so2']?.toDouble() ?? 0.0,
          'co': components['co']?.toDouble() ?? 0.0,
        },
        timestamp: DateTime.fromMillisecondsSinceEpoch(data['dt'] * 1000),
        latitude: json['coord']['lat'].toDouble(),
        longitude: json['coord']['lon'].toDouble(),
        city: json['name'] ?? 'Unknown',
        dataSource: 'OpenWeatherMap',
        aqiMethod: 'Satellite & Ground Data',
      );
    } else {
      // Fallback for unknown format
      return AirQualityData(
        aqi: 0.0,
        category: 'Unknown',
        color: '#808080',
        description: 'No data available',
        pollutants: {},
        timestamp: DateTime.now(),
        latitude: 0.0,
        longitude: 0.0,
        city: 'Unknown',
        dataSource: 'Unknown',
        aqiMethod: 'Unknown',
      );
    }
  }

  static String getCategory(double aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  static String getColor(double aqi) {
    if (aqi <= 50) return '#00E400';
    if (aqi <= 100) return '#FFFF00';
    if (aqi <= 150) return '#FF7E00';
    if (aqi <= 200) return '#FF0000';
    if (aqi <= 300) return '#8F3F97';
    return '#7E0023';
  }

  static String getDescription(double aqi) {
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

  /// Calculate AQI from PM2.5 using US EPA formula
  /// PM2.5 is in μg/m³
  static double _calculateAQIFromPM25(double pm25) {
    // US EPA PM2.5 breakpoints and corresponding AQI values
    // https://www.airnow.gov/sites/default/files/2020-05/aqi-technical-assistance-document-sept2018.pdf

    if (pm25 <= 0.0) return 0.0;

    // Good (0-50)
    if (pm25 <= 12.0) {
      return _linearInterpolation(pm25, 0.0, 12.0, 0.0, 50.0);
    }
    // Moderate (51-100)
    else if (pm25 <= 35.4) {
      return _linearInterpolation(pm25, 12.1, 35.4, 51.0, 100.0);
    }
    // Unhealthy for Sensitive Groups (101-150)
    else if (pm25 <= 55.4) {
      return _linearInterpolation(pm25, 35.5, 55.4, 101.0, 150.0);
    }
    // Unhealthy (151-200)
    else if (pm25 <= 150.4) {
      return _linearInterpolation(pm25, 55.5, 150.4, 151.0, 200.0);
    }
    // Very Unhealthy (201-300)
    else if (pm25 <= 250.4) {
      return _linearInterpolation(pm25, 150.5, 250.4, 201.0, 300.0);
    }
    // Hazardous (301-500)
    else if (pm25 <= 500.4) {
      return _linearInterpolation(pm25, 250.5, 500.4, 301.0, 500.0);
    }
    // Beyond Hazardous
    else {
      return _linearInterpolation(pm25, 500.5, 999.9, 501.0, 999.0);
    }
  }

  /// Linear interpolation helper for AQI calculation
  static double _linearInterpolation(double value, double lowValue,
      double highValue, double lowAQI, double highAQI) {
    return ((highAQI - lowAQI) / (highValue - lowValue)) * (value - lowValue) +
        lowAQI;
  }

  Map<String, dynamic> toJson() {
    return {
      'aqi': aqi,
      'category': category,
      'color': color,
      'description': description,
      'pollutants': pollutants,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'dataSource': dataSource,
      'aqiMethod': aqiMethod,
    };
  }
}
