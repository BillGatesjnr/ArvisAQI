import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/air_quality_provider.dart';
import '../utils/color_utils.dart';
import '../models/air_quality_data.dart';

import 'discover_screen.dart';
import 'favorites_screen.dart';
import 'edit_favorites_screen.dart';

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
// 4% of screen width

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A3D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _getScreenTitle(),
          style: TextStyle(
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
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0E2454),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return const DiscoverScreen();
      case 2:
        return _buildLocationScreen();
      case 3:
        return _buildSettingsScreen();
      default:
        return _buildHomeScreen();
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
                  // Show only current AQI and category for favorite cities
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isSmallScreen = screenWidth < 360;
                  final cardPadding = screenWidth * 0.04;
                  final fontSize = isSmallScreen ? 0.9 : 1.0;
                  final aqiColor = ColorUtils.getAqiColor(cityData.aqi);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E2454),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: cardPadding,
                        vertical: cardPadding * 0.8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      cityData.city.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14 * fontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.location_city,
                                      color: Colors.white70,
                                      size: 14 * fontSize,
                                    ),
                                  ],
                                ),
                              ),
                              _buildAQIIndicator(context,
                                  aqi: cityData.aqi, color: aqiColor),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cityData.category,
                            style: TextStyle(
                              color: aqiColor,
                              fontSize: 28 * fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatTimestamp(cityData.timestamp),
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12 * fontSize,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                        color: const Color(0xFF0E2454),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Location Features',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            color: Colors.blue,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E2454),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: cardPadding,
        vertical: cardPadding * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      data.city.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14 * fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 14 * fontSize,
                    ),
                  ],
                ),
              ),
              _buildAQIIndicator(context, aqi: data.aqi, color: aqiColor),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            data.category,
            style: TextStyle(
              color: aqiColor,
              fontSize: 28 * fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _formatTimestamp(data.timestamp),
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12 * fontSize,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40 * fontSize,
            child: CustomPaint(
              painter: HourlyGraphPainter(
                color: aqiColor,
                data: provider.aqiTrend,
              ),
              size: Size(double.infinity, 40 * fontSize),
            ),
          ),
          const SizedBox(height: 12),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daily Average: ${provider.averageAqi.toStringAsFixed(0)}',
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
          const SizedBox(height: 16),
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
        'value': data.pollutants['pm25'] ?? 0.0,
        'unit': 'μg/m³'
      },
      {
        'name': 'PM10',
        'value': data.pollutants['pm10'] ?? 0.0,
        'unit': 'μg/m³'
      },
      {'name': 'O₃', 'value': data.pollutants['o3'] ?? 0.0, 'unit': 'ppb'},
      {'name': 'NO₂', 'value': data.pollutants['no2'] ?? 0.0, 'unit': 'ppb'},
      {'name': 'SO₂', 'value': data.pollutants['so2'] ?? 0.0, 'unit': 'ppb'},
      {'name': 'CO', 'value': data.pollutants['co'] ?? 0.0, 'unit': 'ppb'},
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

  Widget _buildAQIIndicator(
    BuildContext context, {
    required double aqi,
    required Color color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final scale = isSmallScreen ? 0.8 : 1.0;
    final size = 80.0 * scale;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.red,
                  Colors.purple,
                  Colors.green,
                ],
                stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                startAngle: 3 * pi / 2,
                endAngle: 7 * pi / 2,
              ),
            ),
          ),
          Center(
            child: Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: const BoxDecoration(
                color: Color(0xFF0E2454),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    aqi.toStringAsFixed(0),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'AQI',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10 * scale,
                    ),
                  ),
                ],
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

    final path = Path();
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
