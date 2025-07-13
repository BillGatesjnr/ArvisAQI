import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/air_quality_data.dart';

class AirQualityProvider with ChangeNotifier {
  // Current location data
  AirQualityData? _currentData;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  Position? _currentPosition;
  String? _resolvedLocality;
  List<String> _favoriteCities = [];
  AirQualityData? _selectedFavoriteCityData;
  Map<String, AirQualityData> _favoriteCitiesData = {};


  // Getters
  AirQualityData? get currentData => _currentData;
  List<String> get favoriteCities => _favoriteCities;
  List<double> get historicalData => _currentData?.historicalAqi ?? [];
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;

  Position? get currentPosition => _currentPosition;
  String? get resolvedLocality => _resolvedLocality;
  List<String> get favoriteCities => _favoriteCities;
  AirQualityData? get selectedFavoriteCityData => _selectedFavoriteCityData;
  Map<String, AirQualityData> get favoriteCitiesData => _favoriteCitiesData;

  /// Reverse geocode current position to get human-readable location
  Future<void> reverseGeocodeCurrentPosition() async {
    if (_currentPosition == null) return;

    try {
      print(
          'DEBUG: Reverse geocoding position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      final placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        // Build a human-readable address from available components
        final List<String> addressComponents = [];

        if (placemark.subLocality?.isNotEmpty == true) {
          addressComponents.add(placemark.subLocality!);
        }
        if (placemark.locality?.isNotEmpty == true) {
          addressComponents.add(placemark.locality!);
        }
        if (placemark.administrativeArea?.isNotEmpty == true) {
          addressComponents.add(placemark.administrativeArea!);
        }
        if (placemark.country?.isNotEmpty == true) {
          addressComponents.add(placemark.country!);
        }

        if (addressComponents.isNotEmpty) {
          _resolvedLocality = addressComponents.join(', ');
          print('DEBUG: Resolved locality: $_resolvedLocality');
        } else {
          _resolvedLocality = 'Unknown Location';
          print('DEBUG: Could not resolve locality, using fallback');
        }
      } else {
        _resolvedLocality = 'Unknown Location';
        print('DEBUG: No placemarks found for reverse geocoding');
      }

      notifyListeners();
    } catch (e) {
      print('DEBUG: Error in reverse geocoding: $e');
      _resolvedLocality = 'Unknown Location';
      notifyListeners();
    }
  }

  /// Fetch air quality data for current location

  Future<void> fetchCurrentLocationData() async {
    _isLoading = true;
    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );


      // Reverse geocode the position to get human-readable location
      await reverseGeocodeCurrentPosition();

      // Fetch air quality data using multiple APIs
      final data = await AirQualityService.fetchAirQualityByCoordinates(

        position.latitude,
        position.longitude,
      );


      if (data != null) {
        print('DEBUG: API returned data for city: ${data.city}');
        print(
            'DEBUG: API coordinates - Lat: ${data.latitude}, Lon: ${data.longitude}');
        print('DEBUG: API AQI: ${data.aqi}');

        _currentData = data;
        await _loadHistoricalData();
      } else {
        print('DEBUG: API returned null, using mock data');
        // Use mock data if API fails
        _currentData = AirQualityService.getMockData();
        _historicalData = AirQualityService.getHistoricalData();
        _error = 'Using demo data - API unavailable';
      }
    } catch (e) {
      print('DEBUG: Exception occurred: $e');
      _error = 'Failed to fetch air quality data: $e';
      // Use mock data as fallback
      _currentData = AirQualityService.getMockData();
      _historicalData = AirQualityService.getHistoricalData();
    }

    _setLoading(false);
  }

  /// Refresh current data
  Future<void> refreshData() async {
    if (_currentPosition != null) {
      await fetchCurrentLocationData();
    }
  }

  /// Get current position with permission handling
  Future<Position?> _getCurrentPosition() async {
    print('DEBUG: Checking location services...');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('DEBUG: Location services are disabled');
      _error = 'Location services are disabled';
      return null;
    }
    print('DEBUG: Location services are enabled');

    print('DEBUG: Checking location permission...');
    LocationPermission permission = await Geolocator.checkPermission();
    print('DEBUG: Current permission status: $permission');

    if (permission == LocationPermission.denied) {
      print('DEBUG: Requesting location permission...');
      permission = await Geolocator.requestPermission();
      print('DEBUG: Permission after request: $permission');
      if (permission == LocationPermission.denied) {
        print('DEBUG: Location permissions are denied');
        _error = 'Location permissions are denied';
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('DEBUG: Location permissions are permanently denied');
      _error = 'Location permissions are permanently denied';
      return null;
    }

    try {
      print('DEBUG: Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,

      );
    } catch (e) {
      _error = 'Failed to fetch air quality data: ${e.toString()}';
      // Fallback to mock data if geocoding fails
      if (_currentData == null) {
        _createFallbackData();
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void _createFallbackData() {
    final now = DateTime.now();
    int aqiValue = 50 + (now.second % 150);
    _currentData = AirQualityData(
      aqi: aqiValue.toDouble(),
      category: _getAqiCategory(aqiValue),
      city: 'Current Location',
      description: _getAqiDescription(aqiValue),
      pollutants: {
        'pm25': 10 + (now.second % 30).toDouble(),
        'pm10': 20 + (now.second % 40).toDouble(),
        'o3': 30 + (now.second % 50).toDouble(),
        'no2': 5 + (now.second % 20).toDouble(),
        'so2': 2 + (now.second % 10).toDouble(),
        'co': 0.5 + (now.second % 2).toDouble(),
      },
      historicalAqi: List.generate(24, (i) => 30 + (now.minute + i) % 120),
      timestamp: now,
      color: _getAqiColor(aqiValue),
      longitude: 0.0,
      latitude: 0.0,
    );
  }

  Future<void> refreshData() async {
    await fetchCurrentLocationData();
  }

  // Favorite cities methods
  void addFavoriteCity(String city) {
    if (!_favoriteCities.contains(city)) {
      _favoriteCities.add(city);
      _fetchFavoriteCityData(city);
      notifyListeners();
    }
  }

  void removeFavoriteCity(String city) {
    _favoriteCities.remove(city);
    _favoriteCityData.remove(city);
    notifyListeners();
  }

  AirQualityData? getFavoriteCityData(String city) {
    return _favoriteCityData[city];
  }

  Future<void> fetchAllFavoriteCitiesData() async {
    for (final city in _favoriteCities) {
      await _fetchFavoriteCityData(city);
    }
  }

  Future<void> _fetchFavoriteCityData(String city) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data - replace with actual API call
      final now = DateTime.now();
      final aqiValue = 30 + (city.hashCode % 170);
      _favoriteCityData[city] = AirQualityData(
        aqi: aqiValue.toDouble(),
        category: _getAqiCategory(aqiValue),
        city: city,
        description: _getAqiDescription(aqiValue),
        pollutants: {
          'pm25': 5 + (city.hashCode % 25).toDouble(),
          'pm10': 15 + (city.hashCode % 35).toDouble(),
          'o3': 25 + (city.hashCode % 45).toDouble(),
          'no2': 3 + (city.hashCode % 15).toDouble(),
          'so2': 1 + (city.hashCode % 8).toDouble(),
          'co': 0.3 + (city.hashCode % 1.7),
        },
        historicalAqi: List.generate(24, (i) => 20 + (city.hashCode + i) % 180),
        timestamp: now,
        color: _getAqiColor(aqiValue),
        longitude: 0.0,
        latitude: 0.0,
      );
      notifyListeners();
    } catch (e) {
      // Handle error for specific city
      debugPrint('Failed to fetch data for $city: ${e.toString()}');
    }
  }

  // Helper methods
  String _getAqiCategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String _getAqiDescription(int aqi) {
    if (aqi <= 50) return 'Air quality is satisfactory';
    if (aqi <= 100) return 'Air quality is acceptable';
    if (aqi <= 150) return 'Sensitive groups may experience health effects';
    if (aqi <= 200) return 'Everyone may begin to experience health effects';
    if (aqi <= 300) return 'Health warnings of emergency conditions';
    return 'Health alert: everyone may experience serious health effects';
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF009966); // Green
    if (aqi <= 100) return const Color(0xFFFFDE33); // Yellow
    if (aqi <= 150) return const Color(0xFFFF9933); // Orange
    if (aqi <= 200) return const Color(0xFFCC0033); // Red
    if (aqi <= 300) return const Color(0xFF660099); // Purple
    return const Color(0xFF7E0023); // Maroon
  }
}
