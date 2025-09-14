import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/air_quality_service.dart';
import '../models/air_quality_data.dart';
import 'dart:ui' as ui;
import 'dart:async';
import '../services/air_quality_marker_cache.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({Key? key}) : super(key: key);

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(7.9465, -1.0232); // Ghana center
  bool _loadingLocation = true;
  bool _loadingMarkers = false;
  double _currentZoom = 7.0;
  List<Marker> _markers = [];
  bool _showHeatmap = false;
  bool _showTraffic = false;
  Map<String, AirQualityData?> _markerCache = {};
  DateTime? _markerCacheTimestamp;
  Timer? _progressiveLoader;
  static const int _initialBatchSize = 2;
  static const int _progressiveBatchSize = 2;
  static const Duration _progressiveDelay = Duration(seconds: 1);
  static const Duration _cacheDuration = Duration(hours: 1);
  final AirQualityMarkerCache _persistentCache = AirQualityMarkerCache();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _progressiveLoader?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (mounted) {
      setState(() {
        _loadingLocation = true;
      });
    }
    try {
      await _determinePosition();
      if (mounted) {
        setState(() => _loadingLocation = false);
        _goToUserLocation();
        _loadMarkersWithCache();
      }
    } catch (e) {
      debugPrint("Map Error: $e");
      if (mounted) {
        setState(() => _loadingLocation = false);
        _loadMarkersWithCache();
      }
    }
  }

  void _loadMarkersWithCache() async {
    final now = DateTime.now();
    DateTime? dbTimestamp = await _persistentCache.getCacheTimestamp();
    Map<String, AirQualityData> dbMarkers =
        await _persistentCache.loadAllMarkers();
    _markerCache = dbMarkers;
    final allCities = List<String>.from(AirQualityService.ghanaCities);
    final missingCities =
        allCities.where((city) => !_markerCache.containsKey(city)).toList();
    if (dbTimestamp != null &&
        now.difference(dbTimestamp) < _cacheDuration &&
        missingCities.isEmpty) {
      // Use persistent cache, all markers present
      print('DEBUG: Loaded all markers from cache');
      _setMarkersFromCache();
    } else {
      // If cache expired, clear everything and start over
      if (dbTimestamp == null ||
          now.difference(dbTimestamp) >= _cacheDuration) {
        await _persistentCache.clearCache();
        _markerCache.clear();
        _markerCacheTimestamp = null;
        _loadMarkersProgressively();
      } else {
        // Progressive-load only missing cities
        _progressiveLoadMissingMarkers(missingCities);
        _setMarkersFromCache();
      }
    }
  }

  void _progressiveLoadMissingMarkers(List<String> missingCities) async {
    if (missingCities.isEmpty) {
      _markerCacheTimestamp = DateTime.now();
      await _persistentCache.setCacheTimestamp(_markerCacheTimestamp!);
      print('DEBUG: Updated marker cache timestamp');
      setState(() {
        _loadingMarkers = false;
      });
      return;
    }
    setState(() {
      _loadingMarkers = true;
    });
    int index = 0;
    _progressiveLoader?.cancel();
    _progressiveLoader = Timer.periodic(_progressiveDelay, (timer) async {
      if (index >= missingCities.length) {
        timer.cancel();
        _markerCacheTimestamp = DateTime.now();
        await _persistentCache.setCacheTimestamp(_markerCacheTimestamp!);
        print('DEBUG: Updated marker cache timestamp');
        if (!mounted) return;
        setState(() {
          _loadingMarkers = false;
        });
        return;
      }
      final batch =
          missingCities.skip(index).take(_progressiveBatchSize).toList();
      await _fetchAndAddMarkers(batch, replace: false);
      if (!mounted) return;
      index += _progressiveBatchSize;
      if (index >= missingCities.length) {
        timer.cancel();
        _markerCacheTimestamp = DateTime.now();
        await _persistentCache.setCacheTimestamp(_markerCacheTimestamp!);
        print('DEBUG: Updated marker cache timestamp');
        if (!mounted) return;
        setState(() {
          _loadingMarkers = false;
        });
      }
    });
  }

  void _setMarkersFromCache() {
    final List<Marker> cityMarkers = [];
    for (final city in AirQualityService.ghanaCities) {
      final coords = AirQualityService.getCityCoordinates(city);
      final data = _markerCache[city];
      if (coords != null && data != null) {
        print('DEBUG: Using cached marker data for $city');
        cityMarkers.add(_createCityMarker(city, data, coords));
      }
    }
    cityMarkers.add(_createUserMarker());
    setState(() {
      _markers = cityMarkers;
    });
  }

  void _loadMarkersProgressively() async {
    setState(() {
      _loadingMarkers = true;
    });
    final List<String> allCities = List.from(AirQualityService.ghanaCities);
    final List<String> initialBatch =
        allCities.take(_initialBatchSize).toList();
    final List<String> remaining = allCities.skip(_initialBatchSize).toList();
    // Load initial batch
    await _fetchAndAddMarkers(initialBatch, replace: true);
    if (!mounted) return;
    // Progressive loading for the rest
    int index = 0;
    _progressiveLoader?.cancel();
    _progressiveLoader = Timer.periodic(_progressiveDelay, (timer) async {
      if (index >= remaining.length) {
        timer.cancel();
        _markerCacheTimestamp = DateTime.now();
        await _persistentCache.setCacheTimestamp(_markerCacheTimestamp!);
        if (!mounted) return;
        setState(() {
          _loadingMarkers = false;
        });
        return;
      }
      final batch = remaining.skip(index).take(_progressiveBatchSize).toList();
      await _fetchAndAddMarkers(batch, replace: false);
      if (!mounted) return;
      index += _progressiveBatchSize;
      if (index >= remaining.length) {
        timer.cancel();
        _markerCacheTimestamp = DateTime.now();
        await _persistentCache.setCacheTimestamp(_markerCacheTimestamp!);
        if (!mounted) return;
        setState(() {
          _loadingMarkers = false;
        });
      }
    });
  }

  Future<void> _fetchAndAddMarkers(List<String> cities,
      {bool replace = false}) async {
    final List<Marker> cityMarkers = replace
        ? []
        : List.from(_markers.where((m) => m.point != _currentPosition));
    for (final city in cities) {
      final coords = AirQualityService.getCityCoordinates(city);
      if (coords != null) {
        AirQualityData? data = _markerCache[city];
        if (data == null) {
          data = await AirQualityService.fetchAirQualityByCity(city);
          _markerCache[city] = data;
          if (data != null) {
            print('DEBUG: Caching new marker data for $city');
            await _persistentCache.saveMarker(city, data);
          }
        }
        if (data != null) {
          cityMarkers.add(_createCityMarker(city, data, coords));
        }
      }
    }
    // Always add user marker last
    cityMarkers.add(_createUserMarker());
    if (!mounted) return;
    setState(() {
      _markers = cityMarkers;
    });
  }

  Marker _createCityMarker(
      String city, AirQualityData data, List<double> coords) {
    return Marker(
      width: 50,
      height: 50,
      point: LatLng(coords[0], coords[1]),
      child: GestureDetector(
        onTap: () => _showLocationDetails(
          context,
          city,
          data.aqi.toInt(),
          LatLng(coords[0], coords[1]),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: _getAqiColor(data.aqi.toInt()),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: _currentZoom > 10 ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(77),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${data.aqi.toInt()}',
              style: TextStyle(
                color: Colors.white,
                fontSize: _currentZoom > 10 ? 14 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Marker _createUserMarker() {
    return Marker(
      width: 60,
      height: 60,
      point: _currentPosition,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(204),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withAlpha(128),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.person_pin_circle, color: Colors.white),
      ),
    );
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    }
  }

  void _goToUserLocation() {
    try {
      _mapController.move(_currentPosition, _currentZoom);
    } catch (e) {
      debugPrint('Map controller not ready: $e');
    }
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.pink;
  }

  void _showLocationDetails(
    BuildContext context,
    String city,
    int aqi,
    LatLng position,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(89),
                blurRadius: 24,
                spreadRadius: 6,
              ),
            ],
            border: Border.all(color: Colors.white.withAlpha(26)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modern Drag handle
                    Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(72),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // City icon and name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.withAlpha(46),
                          radius: 18,
                          child: Icon(Icons.location_city,
                              color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            city,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // AQI badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _getAqiColor(aqi).withAlpha(46),
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: _getAqiColor(aqi), width: 1.5),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.eco, color: _getAqiColor(aqi), size: 15),
                            const SizedBox(width: 6),
                            Text(
                              'AQI: $aqi',
                              style: TextStyle(
                                color: _getAqiColor(aqi),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                _getAqiCategory(aqi),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withAlpha(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getAqiCategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for SG';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Air Quality Map',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _markerCache.clear();
              _loadMarkersWithCache();
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: _currentZoom,
              maxZoom: 18,
              minZoom: 3,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _currentZoom = position.zoom ?? 13.0);
                }
              },
            ),
            children: [
              // Base map layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.airqualityapp',
                retinaMode: true,
                maxZoom: 19,
                minZoom: 0,
              ),
              if (_showTraffic)
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.airqualityapp',
                  retinaMode: true,
                ),
              if (!_showHeatmap) MarkerLayer(markers: _markers),
              if (_showHeatmap)
                TileLayer(
                  urlTemplate:
                      'https://tiles.aqicn.org/tiles/usepa-aqi/{z}/{x}/{y}.png?token=9de100a0ae35eedd0d4a6e57088544427796f472',
                  retinaMode: true,
                ),
            ],
          ),

          // Loading overlay
          if (_loadingLocation)
            Container(
              color: Colors.black.withAlpha(77),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading map...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Marker loading indicator
          if (_loadingMarkers && !_loadingLocation)
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(179),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading data...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Map controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          // Map type controls
          Positioned(
            left: 16,
            top: 100,
            child: Column(
              children: [
                _buildMapControlButton(
                  _showHeatmap ? Icons.location_off : Icons.location_on,
                  _showHeatmap ? 'Hide Markers' : 'Show Markers',
                  _toggleHeatmap,
                  _showHeatmap ? Colors.blue : Colors.white30,
                ),
                const SizedBox(height: 8),
                _buildMapControlButton(
                  Icons.satellite,
                  _showTraffic ? 'Hide Satellite' : 'Show Satellite',
                  _toggleTraffic,
                  _showTraffic ? Colors.blue : Colors.white30,
                ),
              ],
            ),
          ),
          // AQI Legend
          Positioned(
            left: 16,
            bottom: 100,
            child: Container(
              width: 140,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withAlpha(141), // Dark transparent background
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'AQI SCALE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildLegendItem(Colors.green, '0-50', 'Good'),
                  _buildLegendItem(Colors.yellow, '51-100', 'Moderate'),
                  _buildLegendItem(Colors.orange, '101-150', 'Unhealthy SG'),
                  _buildLegendItem(Colors.red, '151-200', 'Unhealthy'),
                  _buildLegendItem(Colors.purple, '201-300', 'Very Unhealthy'),
                  _buildLegendItem(Colors.pink, '300+', 'Hazardous'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToUserLocation,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildMapControlButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    Color color,
  ) {
    return FloatingActionButton.small(
      heroTag: tooltip,
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _buildLegendItem(Color color, String range, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                range,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 2),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleHeatmap() {
    setState(() => _showHeatmap = !_showHeatmap);
  }

  void _toggleTraffic() {
    setState(() => _showTraffic = !_showTraffic);
  }
}
