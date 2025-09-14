import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/air_quality_location_cache.dart';
import '../providers/air_quality_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _favoritesList = [];
  bool _loadingCache = true;

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

  @override
  void initState() {
    super.initState();
    _loadFavoritesCache();
  }

  Future<void> _loadFavoritesCache() async {
    final cache = AirQualityLocationCache();
    final favList = await cache.loadFavoritesList();
    print('DEBUG: Loaded favorites list from cache');
    if (!mounted) return;
    setState(() {
      _favoritesList = favList;
      _loadingCache = false;
    });
  }

  Future<void> _updateFavoritesList(List<Map<String, dynamic>> newList) async {
    final cache = AirQualityLocationCache();
    print('DEBUG: Caching new favorites list');
    await cache.saveFavoritesList(newList);
    if (!mounted) return;
    setState(() {
      _favoritesList = newList;
    });
  }

  List<String> _getFilteredCities() {
    if (_searchQuery.isEmpty) {
      return _ghanaCities;
    }
    return _ghanaCities
        .where((city) => city.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _addToFavorites(
      BuildContext context, AirQualityProvider provider, String city) async {
    if (!provider.favoriteCities.contains(city)) {
      provider.addFavoriteCity(city);
      // Add to persistent favorites list
      final newList = List<Map<String, dynamic>>.from(_favoritesList)
        ..add({
          'id': city,
          'name': city,
          'lat': null,
          'lon': null,
        });
      await _updateFavoritesList(newList);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Added $city to favorites!'),
            duration: Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$city is already in favorites.'),
            duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Favorites',
            onPressed: () {
              Navigator.pushNamed(context, '/edit-favorites').then((_) {
                _loadFavoritesCache();
              });
            },
          ),
        ],
      ),
      body: _loadingCache
          ? Center(child: CircularProgressIndicator())
          : _buildAddFavoriteCityMap(context),
    );
  }

  Widget _buildAddFavoriteCityMap(BuildContext context) {
    return Consumer<AirQualityProvider>(
      builder: (context, provider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = screenWidth * 0.04;
        return ListView(
          padding: EdgeInsets.all(horizontalPadding),
          children: [
            const SizedBox(height: 24),
            Text('Add a city to favorites:',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _getFilteredCities().map((city) {
                final isFav = provider.favoriteCities.contains(city);
                return FilterChip(
                  label: Text(city),
                  selected: isFav,
                  onSelected: isFav
                      ? null
                      : (selected) => _addToFavorites(context, provider, city),
                );
              }).toList(),
            ),
          ],
        );
      },
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
