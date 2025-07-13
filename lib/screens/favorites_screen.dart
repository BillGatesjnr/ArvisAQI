import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/air_quality_provider.dart';
import '../utils/color_utils.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String? _selectedCity;
  String _searchQuery = '';

  List<String> get _ghanaCities => [
        'Accra',
        'Kumasi',
        'Tamale',
        'Sekondi-Takoradi',
        'Ashaiman',
        'Tema',
        'Cape Coast',
        'Obuasi',
        'Teshie',
        'Madina',
        'Koforidua',
        'Wa',
        'Ho',
        'Sunyani',
        'Bolgatanga',
        'Techiman',
        'Nkawkaw',
        'Hohoe',
        'Yendi',
        'Aflao'
      ];

  List<String> _getFilteredCities() {
    if (_searchQuery.isEmpty) {
      return _ghanaCities;
    }
    return _ghanaCities
        .where((city) => city.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _addToFavorites(
      BuildContext context, AirQualityProvider provider, String city) {
    if (!provider.favoriteCities.contains(city)) {
      provider.addFavoriteCity(city);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $city to favorites!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$city is already in favorites.')),
      );
    }
  }

  void _refreshAllFavorites(BuildContext context, AirQualityProvider provider) {
    provider.fetchAllFavoriteCitiesData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Refreshing all favorite cities...')),
    );
  }

  Widget _buildFavoriteCitySubtitle(AirQualityProvider provider, String city) {
    final cityData = provider.getFavoriteCityData(city);
    if (cityData != null) {
      final aqiColor = ColorUtils.getAqiColor(cityData.aqi);
      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: aqiColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'AQI: ${cityData.aqi.toStringAsFixed(0)} - ${cityData.category}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      );
    } else {
      return Text(
        'Loading AQI data...',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A3D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Favorites',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildFavoritesBody(),
    );
  }

  Widget _buildFavoritesBody() {
    return Consumer<AirQualityProvider>(
      builder: (context, provider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = screenWidth * 0.04;
        return ListView(
          padding: EdgeInsets.all(horizontalPadding),
          children: [
            // Only show the favorite city section (add/remove), not AQI data
            _buildFavoriteCitySection(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildFavoriteCitySection(
      BuildContext context, AirQualityProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E2454),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'FAVORITE CITIES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (provider.favoriteCities.isNotEmpty)
                IconButton(
                  onPressed: () => _refreshAllFavorites(context, provider),
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F5A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for a city...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // Ghanaian Cities Dropdown
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F5A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A2F5A),
                style: TextStyle(color: Colors.white, fontSize: 14),
                hint: Text(
                  'Select a Ghanaian city',
                  style: TextStyle(color: Colors.white70),
                ),
                items: _getFilteredCities().map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        city,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCity = newValue;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Add to Favorites Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedCity != null
                  ? () {
                      _addToFavorites(context, provider, _selectedCity!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Add ${_selectedCity ?? "City"} to Favorites',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Current Favorites List
          if (provider.favoriteCities.isNotEmpty) ...[
            Text(
              'Your Favorites (${provider.favoriteCities.length}):',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: provider.favoriteCities.map((city) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(
                      Icons.location_city,
                      color: Colors.blue,
                      size: 20,
                    ),
                    title: Text(
                      city,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: _buildFavoriteCitySubtitle(provider, city),
                    // Removed trailing delete icon
                    // trailing: ...
                    // onTap: ...
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
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
        : List.generate(24, (i) => 50.0 + 20.0 * sin(i * 3.14159 / 12));

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
