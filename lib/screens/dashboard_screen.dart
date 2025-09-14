import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/air_quality_provider.dart';
import '../utils/color_utils.dart';
import '../models/air_quality_data.dart';
import '../services/air_quality_service.dart';
import 'package:flutter/services.dart';

import 'discover_screen.dart';
import 'favorites_screen.dart';
import 'edit_favorites_screen.dart';
import 'maps_screen.dart';
import 'settings_screen.dart';
import 'local_sensor_screen.dart';

export 'dashboard_screen.dart' show RouteObserverProvider;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  int _currentIndex = 0;
  bool _showFavoritesHint = false;
  int _lastFavoritesCount = 0;
  bool _pendingShowHint = false;

  RouteObserver<PageRoute>? _routeObserver;
  PageRoute? _myRoute;

  // List of major Ghanaian cities

  @override
  void initState() {
    super.initState();
    // Fetch data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AirQualityProvider>().fetchCurrentLocationData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register this widget as a route observer
    ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute) {
      _routeObserver = RouteObserverProvider.of(context);
      _routeObserver?.subscribe(this, route);
      _myRoute = route;
    }
    final provider = context.watch<AirQualityProvider>();
    final favCount = provider.favoriteCities.length;
    debugPrint(
        '[DASHBOARD] didChangeDependencies: favCount=$_lastFavoritesCount -> $favCount, _pendingShowHint=$_pendingShowHint, _showFavoritesHint=$_showFavoritesHint');
    // Only set pending flag if we are not on dashboard
    if (_lastFavoritesCount == 0 && favCount > 0 && !_pendingShowHint) {
      _pendingShowHint = true;
      debugPrint('[DASHBOARD] Set _pendingShowHint=true (favorites added)');
    }
    _lastFavoritesCount = favCount;
  }

  @override
  void dispose() {
    if (_myRoute != null) {
      _routeObserver?.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint(
        '[DASHBOARD] didPopNext: _pendingShowHint=$_pendingShowHint, _showFavoritesHint=$_showFavoritesHint');
    // Called when coming back to this screen
    if (_pendingShowHint) {
      setState(() {
        _showFavoritesHint = true;
        _pendingShowHint = false;
      });
      debugPrint('[DASHBOARD] Showing animated hint after pop');
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showFavoritesHint = false;
          });
          debugPrint('[DASHBOARD] Hiding animated hint after delay');
        }
      });
    }
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirm Exit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        content: const Text(
          'Close the app?',
          style: TextStyle(fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No', style: TextStyle(fontSize: 14)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes', style: TextStyle(fontSize: 14)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Build the screens list here to pass context
    final screens = [
      _HomeTab(
        getScreenTitle: _getScreenTitle,
        buildHomeScreen: _buildHomeScreen,
      ),
      const DiscoverScreen(),
      _buildLocationScreen(),
      const LocalSensorScreen(),
      _buildSettingsScreen(),
    ];

    // Use a longer duration for the hint
    const hintDuration = Duration(seconds: 7);

    // Robust: Show hint after build if pending
    if (_pendingShowHint && !_showFavoritesHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pendingShowHint) {
          setState(() {
            _showFavoritesHint = true;
            _pendingShowHint = false;
          });
          debugPrint('[DASHBOARD] Showing animated hint after build');
          Future.delayed(hintDuration, () {
            if (mounted) {
              setState(() {
                _showFavoritesHint = false;
              });
              debugPrint(
                  '[DASHBOARD] Hiding animated hint after delay (build)');
            }
          });
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          Navigator.of(context).maybePop();
        }
      },
      child: RouteObserverProvider(
        observer: RouteObserver<PageRoute>(),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              screens[_currentIndex],
              if (_showFavoritesHint)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _showFavoritesHint ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(221),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(33),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swipe,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Swipe to see favorites',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _FloatingNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              if (index == 0 && _pendingShowHint) {
                setState(() {
                  _showFavoritesHint = true;
                  _pendingShowHint = false;
                });
                debugPrint(
                    '[DASHBOARD] Showing animated hint after tab switch');
                Future.delayed(hintDuration, () {
                  if (mounted) {
                    setState(() {
                      _showFavoritesHint = false;
                    });
                    debugPrint(
                        '[DASHBOARD] Hiding animated hint after delay (tab switch)');
                  }
                });
              }
            },
          ),
        ),
      ),
    );
  }

  String _getScreenTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Discover';
      case 2:
        return 'AQI Map';
      case 3:
        return 'Local Sensor';
      case 4:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildHomeScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;

    return Consumer<AirQualityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.blue,
            ),
          );
        }

        if (provider.error != null && provider.currentData == null) {
          // Make error message clickable
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        title: const Text('Location Required',
                            style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Location access is required for air quality data.\n\nPlease enable location services and grant permission in your device settings.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await Geolocator.openLocationSettings();
                            },
                            child: const Text('Open Location Settings',
                                style: TextStyle(color: Colors.blueAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(33),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withAlpha(46)),
                      ),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.fetchCurrentLocationData();
                    provider.fetchAllFavoriteCitiesData();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final currentData = provider.currentData;
        if (currentData == null) {
          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.all(horizontalPadding),
          children: [
            _buildLocationCard(
              context,
              data: currentData,
              provider: provider,
            ),
            if (provider.error != null) ...[
              SizedBox(height: horizontalPadding),
              _buildErrorCard(context, provider.error!),
            ],
            // Show all favorite city AQI cards
            if (provider.favoriteCities.isNotEmpty) ...[
              SizedBox(height: horizontalPadding),
              Text(
                'Your Favorites:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...provider.favoriteCities.map((city) {
                final cityData = provider.getFavoriteCityData(city);
                if (cityData != null) {
                  // Modern favorite city card UI
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isSmallScreen = screenWidth < 360;
                  final cardPadding = screenWidth * 0.04;
                  final fontSize = isSmallScreen ? 0.9 : 1.0;
                  final aqiColor = ColorUtils.getAqiColor(cityData.aqi);
                  final circleSize = screenWidth * 0.32;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          width: 1.5,
                          color: aqiColor.withAlpha(56),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: cardPadding * 1.5,
                        vertical: cardPadding * 1.5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            color: Colors.blue,
                                            size: 16 * fontSize),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            city, // Always show the favorite city name
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16 * fontSize,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.location_city,
                                            color: Colors.white70,
                                            size: 16 * fontSize),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'AQI data from: ${cityData.city}',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13 * fontSize,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  color: aqiColor.withAlpha(46),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    cityData.aqi.toStringAsFixed(0),
                                    style: TextStyle(
                                      color: aqiColor,
                                      fontSize: (cityData.aqi > 99 ? 40 : 54) *
                                          fontSize,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cityData.category,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18 * fontSize,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(cityData.timestamp),
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12 * fontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_hasValidPollutantData(cityData)) ...[
                            _buildPollutantsSection(cityData, fontSize),
                            const SizedBox(height: 12),
                          ],
                          _buildAttributionSection(cityData, fontSize),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(color: Colors.blue),
                          const SizedBox(width: 16),
                          Text(
                            'Loading data for $city...',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }).toList(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLocationScreen() {
    return const MapsScreen();
  }

  Widget _buildSettingsScreen() {
    return const SettingsScreen();
  }

  Widget _buildLocationCard(
    BuildContext context, {
    required AirQualityData data,
    required AirQualityProvider provider,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final cardPadding = screenWidth * 0.04;
    final fontSize = isSmallScreen ? 0.9 : 1.0;
    final aqiColor = ColorUtils.getAqiColor(data.aqi);
    final circleSize = screenWidth * 0.32;

    return FutureBuilder<AirQualityData?>(
      future: AirQualityService.fetchAirQualityByCoordinates(
        data.latitude,
        data.longitude,
      ),
      builder: (context, snapshot) {
        final altData = snapshot.data;
        // Always use altData for pollutants if available
        final pollutantsData = altData ?? data;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: 1.5,
              color: aqiColor.withAlpha(56),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: cardPadding * 1.5,
            vertical: cardPadding * 1.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Location info, AQI, etc. (from main data)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.resolvedLocality != null) ...[
                          Row(
                            children: [
                              Icon(Icons.my_location,
                                  color: Colors.blue, size: 18 * fontSize),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  provider.resolvedLocality!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16 * fontSize,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.white70, size: 16 * fontSize),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'AQI Source: ${data.city}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13 * fontSize,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: aqiColor.withAlpha(46),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        data.aqi.toStringAsFixed(0),
                        style: TextStyle(
                          color: aqiColor,
                          fontSize: (data.aqi > 99 ? 40 : 54) * fontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.category,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18 * fontSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(data.timestamp),
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12 * fontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Forecast Row (from main data)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FORECAST',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12 * fontSize,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daily Avg: ${provider.averageAqi.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11 * fontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DayIndicator(
                          day: 'MIN',
                          value: provider.bestAqi.toStringAsFixed(0),
                          color: Colors.green,
                          fontSize: fontSize,
                        ),
                        _DayIndicator(
                          day: 'AVG',
                          value: provider.averageAqi.toStringAsFixed(0),
                          color: aqiColor,
                          fontSize: fontSize,
                        ),
                        _DayIndicator(
                          day: 'MAX',
                          value: provider.worstAqi.toStringAsFixed(0),
                          color: Colors.red,
                          fontSize: fontSize,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Pollutants section always from altData (WAQI/OpenWeatherMap)
              ...[
                _buildPollutantsSection(pollutantsData, fontSize),
                const SizedBox(height: 12),
              ],
              _buildAttributionSection(data, fontSize),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPollutantsSection(AirQualityData data, double fontSize) {
    final pollutants = [
      {
        'name': 'PM2.5',
        'value': data.pollutants?['pm25'] ?? 0.0,
        'unit': 'μg/m³'
      },
      {
        'name': 'PM10',
        'value': data.pollutants?['pm10'] ?? 0.0,
        'unit': 'μg/m³'
      },
      {'name': 'O₃', 'value': data.pollutants?['o3'] ?? 0.0, 'unit': 'ppb'},
      {'name': 'NO₂', 'value': data.pollutants?['no2'] ?? 0.0, 'unit': 'ppb'},
      {'name': 'SO₂', 'value': data.pollutants?['so2'] ?? 0.0, 'unit': 'ppb'},
      {'name': 'CO', 'value': data.pollutants?['co'] ?? 0.0, 'unit': 'ppb'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Text(
            'POLLUTANTS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12 * fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.3,
            ),
            itemCount: pollutants.length,
            itemBuilder: (context, index) {
              final pollutant = pollutants[index];
              return Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(15, 14, 14, 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      pollutant['name'] as String,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5 * fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(pollutant['value'] as double).toStringAsFixed(1)} ${pollutant['unit']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10 * fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttributionSection(AirQualityData data, double fontSize) {
    // Determine pollutant source for attribution
    String pollutantSource = 'Unknown';
    if (data.dataSource == 'AirVisual (IQAir)') {
      // Try to infer pollutant source from the pollutants map keys
      if (data.pollutants != null && data.pollutants!.isNotEmpty) {
        // OpenWeatherMap pollutants have 'pm25' and 'pm10' keys, but so do others; check for typical OWM values
        // If all values are integers, likely WAQI; if some are decimals, likely OWM
        final values = data.pollutants!.values;
        if (values.any((v) => v > 0 && v < 1)) {
          pollutantSource = 'OpenWeatherMap';
        } else if (values.any((v) => v > 100)) {
          pollutantSource = 'WAQI';
        } else {
          pollutantSource = 'OpenWeatherMap or WAQI';
        }
      } else {
        pollutantSource = 'AirVisual (IQAir)';
      }
    } else if (data.dataSource == 'WAQI') {
      if (data.pollutants != null &&
          data.pollutants!.values.any((v) => v > 0)) {
        pollutantSource = 'WAQI';
      } else {
        pollutantSource = 'OpenWeatherMap';
      }
    } else if (data.dataSource == 'OpenWeatherMap') {
      pollutantSource = 'OpenWeatherMap';
    }

    return Container(
      padding: EdgeInsets.all(8 * fontSize),
      decoration: BoxDecoration(
        color: Color.fromRGBO(15, 14, 14, 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white70,
                size: 14 * fontSize,
              ),
              const SizedBox(width: 6),
              Text(
                'DATA SOURCE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10 * fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'AQI: ${data.dataSource}',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11 * fontSize,
            ),
          ),
          Text(
            'Pollutants: $pollutantSource',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11 * fontSize,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'AQI data from: ${data.aqiMethod}',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11 * fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(250, 58, 58, 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromRGBO(250, 58, 58, 0.09)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  bool _hasValidPollutantData(AirQualityData data) {
    // Check if any pollutant has a value greater than 0
    return data.pollutants?.values.any((value) => value > 0) ?? false;
  }
}

class _HomeTab extends StatelessWidget {
  final String Function() getScreenTitle;
  final Widget Function() buildHomeScreen;
  const _HomeTab({required this.getScreenTitle, required this.buildHomeScreen});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            getScreenTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditFavoritesScreen()),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavoritesScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: () {
                context.read<AirQualityProvider>().refreshData();
              },
            ),
          ],
        ),
        Expanded(child: buildHomeScreen()),
      ],
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      //borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            //borderRadius: BorderRadius.circular(24),
            // Fully transparent background like iOS WhatsApp
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavBarItem(
                icon: Icons.explore_rounded,
                label: 'Discover',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavBarItem(
                icon: Icons.location_on,
                label: 'AQI Map',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavBarItem(
                icon: Icons.sensors_rounded,
                label: 'Sensor',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavBarItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                selected: currentIndex == 4,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? Colors.blue.withAlpha(51) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.white.withAlpha(179),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white.withAlpha(179),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayIndicator extends StatelessWidget {
  final String day;
  final String value;
  final Color color;
  final double fontSize;

  const _DayIndicator({
    required this.day,
    required this.value,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10 * fontSize,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12 * fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 6 * fontSize,
          height: 6 * fontSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class HourlyGraphPainter extends CustomPainter {
  final Color color;
  final List<double> data;

  HourlyGraphPainter({required this.color, this.data = const []});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(128)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = ui.Path();
    path.moveTo(0, size.height);

    // Use real data if available, otherwise generate mock data
    List<Offset> points = [];
    final dataPoints = data.isNotEmpty
        ? data
        : List.generate(24, (i) => 50.0 + 20.0 * sin(i * pi / 12));

    for (var i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final normalizedValue =
          (dataPoints[i] - 0) / 300; // Normalize to 0-300 range
      final y =
          size.height * (1 - normalizedValue * 0.8); // Keep some margin at top
      points.add(Offset(x, y));
    }

    // Draw the curve
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    // Close the path for filling
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw filled area
    canvas.drawPath(path, paint);

    // Draw the line on top
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RouteObserverProvider extends InheritedWidget {
  final RouteObserver<PageRoute> observer;
  const RouteObserverProvider(
      {Key? key, required this.observer, required Widget child})
      : super(key: key, child: child);
  static RouteObserver<PageRoute> of(BuildContext context) {
    final RouteObserverProvider? result =
        context.dependOnInheritedWidgetOfExactType<RouteObserverProvider>();
    assert(result != null, 'No RouteObserverProvider found in context');
    return result!.observer;
  }

  @override
  bool updateShouldNotify(RouteObserverProvider oldWidget) =>
      observer != oldWidget.observer;
}



