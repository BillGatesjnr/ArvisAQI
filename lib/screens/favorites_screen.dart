import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';
import '../utils/color_utils.dart';
import '../models/air_quality_data.dart';

class FavoritesScreen extends StatefulWidget {
  final bool showSearch;

  const FavoritesScreen({Key? key, required this.showSearch}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String? _selectedCity;
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _isSearchVisible = widget.showSearch;
  }

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
    return _searchQuery.isEmpty
        ? _ghanaCities
        : _ghanaCities
            .where((city) =>
                city.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
  }

  void _addToFavorites(BuildContext context, String city) {
    final provider = Provider.of<AirQualityProvider>(context, listen: false);
    provider.addFavoriteCity(city);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $city to favorites!')),
    );
  }

  void _refreshAllFavorites(BuildContext context) {
    final provider = Provider.of<AirQualityProvider>(context, listen: false);
    provider.fetchAllFavoriteCitiesData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Refreshing all favorite cities...')),
    );
  }

  Widget _buildFavoriteCitySubtitle(AirQualityData? cityData) {
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
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      );
    }
    return Text(
      'Loading AQI data...',
      style: TextStyle(color: Colors.white70, fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A3D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearchVisible
            ? TextField(
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search cities...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text(
                'Favorites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
        actions: [
          if (!_isSearchVisible)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => setState(() => _isSearchVisible = true),
            ),
          if (_isSearchVisible)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() {
                _isSearchVisible = false;
                _searchQuery = '';
              }),
            ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildFavoritesBody(),
    );
  }

  Widget _buildFavoritesBody() {
    return Consumer<AirQualityProvider>(
      builder: (context, provider, child) {
        return ListView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          children: [_buildFavoriteCitySection(context, provider)],
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
              Icon(Icons.favorite, color: Colors.red, size: 20),
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
                  onPressed: () => _refreshAllFavorites(context),
                  icon: Icon(Icons.refresh, color: Colors.white70, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F5A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withAlpha(77)),
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
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F5A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withAlpha(77)),
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
                items: _getFilteredCities()
                    .map((city) => DropdownMenuItem(
                          value: city,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(city,
                                style: TextStyle(color: Colors.white)),
                          ),
                        ))
                    .toList(),
                onChanged: (newValue) =>
                    setState(() => _selectedCity = newValue),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedCity != null
                  ? () => _addToFavorites(context, _selectedCity!)
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
                final cityData = provider.getFavoriteCityData(city);
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withAlpha(77)),
                  ),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading:
                        Icon(Icons.location_city, color: Colors.blue, size: 20),
                    title: Text(
                      city,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: _buildFavoriteCitySubtitle(cityData),
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
