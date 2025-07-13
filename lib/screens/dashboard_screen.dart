import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/air_quality_provider.dart';
import '../utils/color_utils.dart';
import '../models/air_quality_data.dart';
import 'discover_screen.dart';

import 'favorites_screen.dart';
import 'edit_favorites_screen.dart';
import 'maps_screen.dart';
import 'dashboard_content.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardContent(),
    const DiscoverScreen(),
    const MapsScreen(),
    const SettingsScreen(),
  ];

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


  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF142A5E).withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
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
    return const MapsScreen();
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
        ),
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
    return data.pollutants.values.any((value) => value > 0);
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
