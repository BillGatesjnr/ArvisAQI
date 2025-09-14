import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';
import '../services/air_quality_location_cache.dart';
import '../models/air_quality_data.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  AirQualityData? _cachedData;
  DateTime? _cacheTimestamp;
  bool _loadingCache = true;
  static const Duration _cacheDuration = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _loadCachedLocationAQI();
  }

  Future<void> _loadCachedLocationAQI() async {
    final cache = AirQualityLocationCache();
    final data = await cache.loadCurrentLocationAQI();
    print('DEBUG: _loadCachedLocationAQI got: ' +
        (data != null ? data.toString() : 'null'));
    final now = DateTime.now();
    final ts = await cache.getCacheTimestamp('current_location');
    if (ts != null) {
      print('DEBUG: Location cache timestamp: ' + ts.toIso8601String());
      print('DEBUG: Location cache age (seconds): ' +
          now.difference(ts).inSeconds.toString());
    } else {
      print('DEBUG: No location cache timestamp found');
    }
    if (data != null && ts != null && now.difference(ts) < _cacheDuration) {
      print(
          'DEBUG: Using cached location AQI data (timestamp: ${ts.toIso8601String()}, age: ${now.difference(ts).inSeconds}s)');
      setState(() {
        _cachedData = data;
        _cacheTimestamp = ts;
        _loadingCache = false;
      });
    } else {
      if (data == null) print('DEBUG: No cached location AQI data found');
      if (ts == null || now.difference(ts) >= _cacheDuration)
        print('DEBUG: Location cache is stale or missing');
      setState(() {
        _loadingCache = false;
      });
    }
  }

  Future<void> _updateCache(AirQualityData data) async {
    final cache = AirQualityLocationCache();
    final now = DateTime.now();
    print(
        'DEBUG: Caching new location AQI data (timestamp: ${now.toIso8601String()})');
    await cache.saveCurrentLocationAQI(data);
    print('DEBUG: _updateCache just called saveCurrentLocationAQI');
    await cache.setCacheTimestamp('current_location', now);
    setState(() {
      _cachedData = data;
      _cacheTimestamp = now;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;
    return Consumer<AirQualityProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();
        final isCacheFresh = _cacheTimestamp != null &&
            now.difference(_cacheTimestamp!) < _cacheDuration;
        if (_loadingCache) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }
        // If cache is fresh, use it and do NOT fetch new data
        if (_cachedData != null && isCacheFresh) {
          print('DEBUG: Using fresh cached location AQI data (no API call)');
          return ListView(
            padding: EdgeInsets.all(horizontalPadding),
            children: [
              _buildLocationCard(_cachedData!, isStale: false),
              const SizedBox(height: 16),
              Text('Data updated less than 15 minutes ago.',
                  style: TextStyle(color: Colors.greenAccent)),
            ],
          );
        }
        // If provider is loading, show loading
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }
        if (provider.error != null && provider.currentData == null) {
          // Show cached data if available
          if (_cachedData != null) {
            return ListView(
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                _buildLocationCard(_cachedData!, isStale: true),
                const SizedBox(height: 16),
                Text('Showing cached data due to error.',
                    style: TextStyle(color: Colors.redAccent)),
              ],
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text('Error',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(provider.error!,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchCurrentLocationData(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        final currentData = provider.currentData;
        if (currentData == null) {
          // Show cached data if available
          if (_cachedData != null) {
            return ListView(
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                _buildLocationCard(_cachedData!, isStale: true),
                const SizedBox(height: 16),
                Text('Showing cached data.',
                    style: TextStyle(color: Colors.orangeAccent)),
              ],
            );
          }
          return const Center(
            child: Text('No data available',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          );
        }
        // Only update cache if cache is missing or stale
        if (!isCacheFresh) {
          _updateCache(currentData);
        }
        return ListView(
          padding: EdgeInsets.all(horizontalPadding),
          children: [
            _buildLocationCard(currentData, isStale: false),
            // ... other dashboard content ...
          ],
        );
      },
    );
  }

  Widget _buildLocationCard(AirQualityData data, {required bool isStale}) {
    // Replace with your actual location card UI
    return Card(
      color: isStale ? Colors.grey[800] : Colors.blue[800],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Location AQI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('AQI: ${data.aqi.toStringAsFixed(0)}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Category: ${data.category}',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            if (isStale)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Stale data',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
