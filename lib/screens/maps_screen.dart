import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(37.7749, -122.4194);
  bool _loadingLocation = true;
  double _currentZoom = 13.0;
  final List<Marker> _markers = [];
  bool _showHeatmap = false;
  bool _showTraffic = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await _determinePosition();
      _loadAirQualityData();
      setState(() => _loadingLocation = false);
    } catch (e) {
      debugPrint("Map Error: $e");
      setState(() => _loadingLocation = false);
    }
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
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _mapController.move(_currentPosition, _currentZoom);
    });
  }

  void _loadAirQualityData() {
    // Example data - replace with real API calls
    final locations = [
      {'lat': 37.7749, 'lng': -122.4194, 'aqi': 75, 'city': 'San Francisco'},
      {'lat': 34.0522, 'lng': -118.2437, 'aqi': 120, 'city': 'Los Angeles'},
      {'lat': 40.7128, 'lng': -74.0060, 'aqi': 45, 'city': 'New York'},
      {'lat': 41.8781, 'lng': -87.6298, 'aqi': 85, 'city': 'Chicago'},
      {'lat': 29.7604, 'lng': -95.3698, 'aqi': 65, 'city': 'Houston'},
    ];

    // Add user location marker
    _markers.add(
      Marker(
        width: 60,
        height: 60,
        point: _currentPosition,
        builder: (ctx) => Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.person_pin_circle, color: Colors.white),
        ),
      ),
    );

    // Add city markers
    for (var location in locations) {
      final aqi = location['aqi'] as int;
      final point =
          LatLng(location['lat'] as double, location['lng'] as double);

      _markers.add(
        Marker(
          width: 50,
          height: 50,
          point: point,
          builder: (ctx) => GestureDetector(
            onTap: () => _showLocationDetails(
              context,
              location['city'] as String,
              aqi,
              point,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: _getAqiColor(aqi),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: _currentZoom > 10 ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$aqi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _currentZoom > 10 ? 14 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
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
            color: const Color(0xFF0E1F3D),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // City name
              Text(
                city,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // AQI indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getAqiColor(aqi).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getAqiColor(aqi)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AQI: $aqi',
                      style: TextStyle(
                        color: _getAqiColor(aqi),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getAqiCategory(aqi),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Health recommendations
              _buildHealthRecommendation(aqi),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    Icons.directions,
                    'Directions',
                    () => _showDirections(position),
                  ),
                  _buildActionButton(
                    Icons.history,
                    'History',
                    () => _showHistoricalData(city),
                  ),
                  _buildActionButton(
                    Icons.share,
                    'Share',
                    () => _shareLocation(city, aqi),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthRecommendation(int aqi) {
    String recommendation;
    Color color;

    if (aqi <= 50) {
      recommendation = 'Air quality is satisfactory. Enjoy outdoor activities!';
      color = Colors.green;
    } else if (aqi <= 100) {
      recommendation =
          'Moderate air quality. Unusually sensitive people should consider reducing prolonged outdoor exertion.';
      color = Colors.yellow;
    } else if (aqi <= 150) {
      recommendation =
          'Unhealthy for sensitive groups. Children and people with respiratory diseases should limit outdoor exertion.';
      color = Colors.orange;
    } else if (aqi <= 200) {
      recommendation =
          'Unhealthy air quality. Everyone may begin to experience health effects. Limit outdoor activities.';
      color = Colors.red;
    } else {
      recommendation =
          'Very unhealthy or hazardous air quality. Avoid all outdoor exertion. Stay indoors with air purifiers if possible.';
      color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.2),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  void _showDirections(LatLng destination) {
    // Implement directions functionality
    debugPrint('Showing directions to $destination');
  }

  void _showHistoricalData(String city) {
    // Implement historical data view
    debugPrint('Showing historical data for $city');
  }

  void _shareLocation(String city, int aqi) {
    // Implement share functionality
    debugPrint('Sharing $city AQI: $aqi');
  }

  void _toggleHeatmap() {
    setState(() => _showHeatmap = !_showHeatmap);
  }

  void _toggleTraffic() {
    setState(() => _showTraffic = !_showTraffic);
  }

  void _goToUserLocation() {
    _mapController.move(_currentPosition, _currentZoom);
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.pink;
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
      backgroundColor: const Color(0xFF0A1A3D),
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
            onPressed: _initializeMap,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          _loadingLocation
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _currentPosition,
                    zoom: _currentZoom,
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
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.airqualityapp',
                    ),

                    // Optional traffic layer
                    if (_showTraffic)
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),

                    // Markers
                    MarkerLayer(markers: _markers),

                    // Optional heatmap overlay
                    if (_showHeatmap)
                      TileLayer(
                        urlTemplate:
                            'https://tiles.aqicn.org/tiles/usepa-aqi/{z}/{x}/{y}.png?token=YOUR_TOKEN',
                        additionalOptions: const {
                          'token': '9de100a0ae35eedd0d4a6e57088544427796f472',
                        },
                      ),
                  ],
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
                    _mapController.center,
                    _mapController.zoom + 1,
                  ),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () => _mapController.move(
                    _mapController.center,
                    _mapController.zoom - 1,
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
                  Icons.layers,
                  _showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
                  _toggleHeatmap,
                  _showHeatmap ? Colors.blue : Colors.white30,
                ),
                const SizedBox(height: 8),
                _buildMapControlButton(
                  Icons.traffic,
                  _showTraffic ? 'Hide Traffic' : 'Show Traffic',
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AQI SCALE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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

      // Location button
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                range,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
