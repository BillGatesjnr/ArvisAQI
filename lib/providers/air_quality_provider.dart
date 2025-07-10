import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/air_quality_data.dart';
import '../services/air_quality_service.dart';

class AirQualityProvider with ChangeNotifier {
  AirQualityData? _currentData;
  List<AirQualityData> _historicalData = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;
  List<String> _favoriteCities = [];
  AirQualityData? _selectedFavoriteCityData;
  Map<String, AirQualityData> _favoriteCitiesData = {};

  // Getters
  AirQualityData? get currentData => _currentData;
  List<AirQualityData> get historicalData => _historicalData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get currentPosition => _currentPosition;
  List<String> get favoriteCities => _favoriteCities;
  AirQualityData? get selectedFavoriteCityData => _selectedFavoriteCityData;
  Map<String, AirQualityData> get favoriteCitiesData => _favoriteCitiesData;

  /// Fetch air quality data for current location
  Future<void> fetchCurrentLocationData() async {
    _setLoading(true);
    _error = null;

    try {
      // Get current position
      final position = await _getCurrentPosition();
      if (position == null) {
        _error = 'Unable to get current location';
        _setLoading(false);
        return;
      }

      _currentPosition = position;

      // Debug logging
      print(
          'DEBUG: Current position - Lat: ${position.latitude}, Lon: ${position.longitude}');
      print('DEBUG: Position accuracy: ${position.accuracy} meters');
      print('DEBUG: Position timestamp: ${position.timestamp}');
      print('DEBUG: Position altitude: ${position.altitude}');
      print('DEBUG: Position speed: ${position.speed}');
      print('DEBUG: Position heading: ${position.heading}');

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
        desiredAccuracy: LocationAccuracy.high,
      );
      print('DEBUG: Position obtained successfully');
      return position;
    } catch (e) {
      print('DEBUG: Failed to get current position: $e');
      _error = 'Failed to get current position: $e';
      return null;
    }
  }

  /// Load historical data
  Future<void> _loadHistoricalData() async {
    try {
      _historicalData = AirQualityService.getHistoricalData();
    } catch (e) {
      print('Error loading historical data: $e');
      _historicalData = [];
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get AQI trend (last 24 hours)
  List<double> get aqiTrend {
    if (_historicalData.isEmpty) return [];
    return _historicalData.map((data) => data.aqi).toList();
  }

  /// Get average AQI for the last 24 hours
  double get averageAqi {
    if (_historicalData.isEmpty) return 0.0;
    final sum = _historicalData.fold(0.0, (sum, data) => sum + data.aqi);
    return sum / _historicalData.length;
  }

  /// Get the worst AQI in the last 24 hours
  double get worstAqi {
    if (_historicalData.isEmpty) return 0.0;
    return _historicalData
        .map((data) => data.aqi)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Get the best AQI in the last 24 hours
  double get bestAqi {
    if (_historicalData.isEmpty) return 0.0;
    return _historicalData
        .map((data) => data.aqi)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Get list of available cities (global)
  List<String> get availableCities => [
        'Accra',
        'Kumasi',
        'Tamale',
        'Lagos',
        'Cairo',
        'London',
        'New York',
        'Tokyo',
        'Beijing',
        'Mumbai',
        'Bangkok',
        'Singapore'
      ];

  /// Fetch air quality data for a specific city
  Future<void> fetchCityData(String city) async {
    _setLoading(true);
    _error = null;

    try {
      print('DEBUG: Fetching data for city: $city');
      final data = await AirQualityService.fetchAirQualityByCity(city);
      if (data != null) {
        print('DEBUG: Successfully fetched data for $city');
        _currentData = data;
        await _loadHistoricalData();
      } else {
        _error = 'Unable to fetch data for $city';
      }
    } catch (e) {
      print('DEBUG: Error fetching city data: $e');
      _error = 'Failed to fetch city data: $e';
    }

    _setLoading(false);
  }

  /// Add a city to favorites
  void addFavoriteCity(String city) {
    if (!_favoriteCities.contains(city)) {
      _favoriteCities.add(city);
      // Fetch data for the new favorite city
      fetchFavoriteCityData(city);
      notifyListeners();
    }
  }

  /// Remove a city from favorites
  void removeFavoriteCity(String city) {
    _favoriteCities.remove(city);
    _favoriteCitiesData.remove(city);
    notifyListeners();
  }

  /// Check if a city is in favorites
  bool isFavoriteCity(String city) {
    return _favoriteCities.contains(city);
  }

  /// Fetch and display data for a selected favorite city
  Future<void> fetchSelectedFavoriteCityData(String city) async {
    _setLoading(true);
    _error = null;

    try {
      print('DEBUG: Fetching data for favorite city: $city');
      final data = await AirQualityService.fetchAirQualityByCity(city);
      if (data != null) {
        print('DEBUG: Successfully fetched data for favorite city $city');
        _selectedFavoriteCityData = data;
      } else {
        print(
            'DEBUG: Failed to fetch data for favorite city $city, using mock data');
        // Use mock data if API fails
        final mockData = AirQualityService.getMockData();
        _selectedFavoriteCityData = AirQualityData(
          aqi: mockData.aqi,
          category: mockData.category,
          color: mockData.color,
          description: mockData.description,
          pollutants: mockData.pollutants,
          timestamp: mockData.timestamp,
          latitude: mockData.latitude,
          longitude: mockData.longitude,
          city: city,
        );
      }
    } catch (e) {
      print('DEBUG: Error fetching favorite city data: $e');
      _error = 'Failed to fetch data for $city: $e';
      // Use mock data as fallback
      final mockData = AirQualityService.getMockData();
      _selectedFavoriteCityData = AirQualityData(
        aqi: mockData.aqi,
        category: mockData.category,
        color: mockData.color,
        description: mockData.description,
        pollutants: mockData.pollutants,
        timestamp: mockData.timestamp,
        latitude: mockData.latitude,
        longitude: mockData.longitude,
        city: city,
      );
    }

    _setLoading(false);
  }

  /// Clear selected favorite city data
  void clearSelectedFavoriteCityData() {
    _selectedFavoriteCityData = null;
    notifyListeners();
  }

  /// Fetch AQI data for all favorite cities
  Future<void> fetchAllFavoriteCitiesData() async {
    for (String city in _favoriteCities) {
      if (!_favoriteCitiesData.containsKey(city)) {
        await fetchFavoriteCityData(city);
      }
    }
  }

  /// Fetch AQI data for a specific favorite city and store it
  Future<void> fetchFavoriteCityData(String city) async {
    try {
      final data = await AirQualityService.fetchAirQualityByCity(city);
      if (data != null) {
        _favoriteCitiesData[city] = data;
        notifyListeners();
      }
    } catch (e) {
      print('DEBUG: Error fetching data for favorite city $city: $e');
    }
  }

  /// Get AQI data for a specific favorite city
  AirQualityData? getFavoriteCityData(String city) {
    return _favoriteCitiesData[city];
  }
}
