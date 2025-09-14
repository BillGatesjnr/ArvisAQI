import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LocalSensorScreen extends StatefulWidget {
  const LocalSensorScreen({super.key});

  @override
  State<LocalSensorScreen> createState() => _LocalSensorScreenState();
}

class _LocalSensorScreenState extends State<LocalSensorScreen> {
  Timer? _timer;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _sensorData;
  String _lastUpdateTime = '';

  @override
  void initState() {
    super.initState();
    _startPeriodicFetch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPeriodicFetch() {
    // Fetch immediately
    _fetchSensorData();
    
    // Then fetch every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchSensorData();
    });
  }

  Future<void> _fetchSensorData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the correct /json endpoint from your Arduino code
      final response = await http.get(
        Uri.parse('http://192.168.43.228/json'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          // Parse the JSON response: {"haveReading":true,"pm1_0":10,"pm2_5":22,"pm10":21}
          final data = json.decode(response.body);
          
          // Check if sensor has valid reading
          if (data['haveReading'] == true) {
            if (mounted) {
              setState(() {
                _sensorData = {
                  'pm1.0': data['pm1_0'],
                  'pm2_5': data['pm2_5'],
                  'pm10': data['pm10'],
                };
                _isLoading = false;
                _error = null;
                _lastUpdateTime = DateTime.now().toString().substring(11, 19);
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _error = 'Sensor is not ready. No valid reading available.';
                _isLoading = false;
              });
            }
          }
        } catch (jsonError) {
          if (mounted) {
            setState(() {
              _error = 'Invalid JSON response: ${jsonError.toString()}';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSensorCard(String title, String value, String unit, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Connecting to sensor...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 64,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchSensorData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataState() {
    if (_sensorData == null) return _buildLoadingState();

    final pm25 = _sensorData!['pm2_5']?.toString() ?? 'N/A';
    final pm10 = _sensorData!['pm10']?.toString() ?? 'N/A';
    final pm1 = _sensorData!['pm1.0']?.toString() ?? 'N/A';

    return Column(
      children: [
        // Header with last update time
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Local Air Quality Sensor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_lastUpdateTime.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Last updated: $_lastUpdateTime',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Loading indicator overlay
        if (_isLoading)
          Container(
            height: 4,
            child: const LinearProgressIndicator(
              color: Colors.blue,
              backgroundColor: Colors.transparent,
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Sensor data cards
        _buildSensorCard(
          'PM2.5',
          pm25,
          'μg/m³',
          _getPM25Color(double.tryParse(pm25) ?? 0),
        ),
        _buildSensorCard(
          'PM10',
          pm10,
          'μg/m³',
          _getPM10Color(double.tryParse(pm10) ?? 0),
        ),
        _buildSensorCard(
          'PM1.0',
          pm1,
          'μg/m³',
          _getPM1Color(double.tryParse(pm1) ?? 0),
        ),
        
        const SizedBox(height: 24),
        
        // Refresh button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchSensorData,
              icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Updating...' : 'Refresh Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getPM25Color(double value) {
    if (value <= 12) return Colors.green;
    if (value <= 35) return Colors.yellow;
    if (value <= 55) return Colors.orange;
    if (value <= 150) return Colors.red;
    return Colors.purple;
  }

  Color _getPM10Color(double value) {
    if (value <= 20) return Colors.green;
    if (value <= 50) return Colors.yellow;
    if (value <= 100) return Colors.orange;
    if (value <= 200) return Colors.red;
    return Colors.purple;
  }

  Color _getPM1Color(double value) {
    if (value <= 10) return Colors.green;
    if (value <= 25) return Colors.yellow;
    if (value <= 50) return Colors.orange;
    if (value <= 100) return Colors.red;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Sensor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchSensorData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _error != null && _sensorData == null 
        ? _buildErrorState()
        : _buildDataState(),
    );
  }
}
