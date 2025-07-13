import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/air_quality_provider.dart';
import '../utils/color_utils.dart';
import '../models/air_quality_data.dart';

import 'discover_screen.dart';
import 'edit_favorites_screen.dart' as edit_fav;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

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
  Widget build(BuildContext context) {
    // Build the screens list here to pass context
    final screens = [
      _HomeTab(
        getScreenTitle: _getScreenTitle,
        buildHomeScreen: _buildHomeScreen,
      ),
      const DiscoverScreen(),
      _buildLocationScreen(),
      _buildSettingsScreen(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A3D),
      body: screens[_currentIndex],
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
        return 'Location';
      case 3:
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
                Text(
                  provider.error!,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.fetchCurrentLocationData();
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
                        color: const Color(0xFF142A5E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          width: 1.5,
                          color: aqiColor.withValues(alpha: 0.22),
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
                                  color: aqiColor.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    cityData.aqi.toStringAsFixed(0),
                                    style: TextStyle(
                                      color: aqiColor,
                                      fontSize: 54 * fontSize,
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
                        color: const Color(0xFF0E245A),
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
    return _MapsScreen();
  }

  Widget _buildSettingsScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A3D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.location_on,
            title: 'Location Settings',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () {},
          ),
          _SettingsItem(
            icon: Icons.info,
            title: 'About ARVISAQI',
            onTap: () {},
          ),
        ],
      ),
    );
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF142A5E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          width: 1.5,
          color: aqiColor.withValues(alpha: 0.22),
        ),
        // No boxShadow for a flat, modern look
      ),
      padding: EdgeInsets.symmetric(
        horizontal: cardPadding * 1.5,
        vertical: cardPadding * 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location info
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
          // AQI indicator and value/category row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big AQI value in a transparent circle
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: aqiColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    data.aqi.toStringAsFixed(0),
                    style: TextStyle(
                      color: aqiColor,
                      fontSize: 54 * fontSize,
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
          // Forecast Row
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
          if (_hasValidPollutantData(data)) ...[
            _buildPollutantsSection(data, fontSize),
            const SizedBox(height: 12),
          ],
          _buildAttributionSection(data, fontSize),
        ],
      ),
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
        Text(
          'POLLUTANTS',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12 * fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: pollutants.length,
          itemBuilder: (context, index) {
            final pollutant = pollutants[index];
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0E2454),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pollutant['name'] as String,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10 * fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(pollutant['value'] as double).toStringAsFixed(1)} ${pollutant['unit']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12 * fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttributionSection(AirQualityData data, double fontSize) {
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
            'Provided by: ${data.dataSource}',
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
                    builder: (context) =>
                        const edit_fav.FavoritesScreen(showSearch: true)),
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
                      builder: (context) =>
                          const edit_fav.FavoritesScreen(showSearch: false)),
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
                label: 'Location',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavBarItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                selected: currentIndex == 3,
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
          color: selected
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
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

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF142A5E).withValues(alpha: 0.6),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}

class _MapsScreen extends StatefulWidget {
  const _MapsScreen();

  @override
  State<_MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<_MapsScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(37.7749, -122.4194);
  bool _loadingLocation = true;
  bool _mapReady = false;
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.5),
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
          child: GestureDetector(
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
                    color: Colors.black.withValues(alpha: 0.3),
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
                color: Colors.black.withValues(alpha: 0.5),
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
                  color: Colors.white.withValues(alpha: 0.3),
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
                  color: _getAqiColor(aqi).withValues(alpha: 0.2),
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
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
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
            backgroundColor: Colors.blue.withValues(alpha: 0.2),
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
    if (_mapReady) {
      try {
        _mapController.move(_currentPosition, _currentZoom);
      } catch (e) {
        debugPrint('Map controller error: $e');
      }
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
                    initialCenter: _currentPosition,
                    initialZoom: _currentZoom,
                    maxZoom: 18,
                    minZoom: 3,
                    onMapReady: () {
                      setState(() {
                        _mapReady = true;
                      });
                      // Move to user location once map is ready
                      _goToUserLocation();
                    },
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
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.airqualityapp',
                      retinaMode: true,
                      maxZoom: 19,
                      minZoom: 0,
                    ),

                    // Optional satellite layer
                    if (_showTraffic)
                      TileLayer(
                        urlTemplate:
                            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.example.airqualityapp',
                        retinaMode: true,
                      ),

                    // Markers
                    MarkerLayer(markers: _markers),

                    // Optional heatmap overlay
                    if (_showHeatmap)
                      TileLayer(
                        urlTemplate:
                            'https://tiles.aqicn.org/tiles/usepa-aqi/{z}/{x}/{y}.png?token=9de100a0ae35eedd0d4a6e57088544427796f472',
                        retinaMode: true,
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
                  onPressed: _mapReady
                      ? () {
                          try {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          } catch (e) {
                            debugPrint('Zoom in error: $e');
                          }
                        }
                      : null,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: _mapReady
                      ? () {
                          try {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          } catch (e) {
                            debugPrint('Zoom out error: $e');
                          }
                        }
                      : null,
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
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
