import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';

class EditFavoritesScreen extends StatelessWidget {
  const EditFavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A3D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Edit Favorites',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<AirQualityProvider>(
        builder: (context, provider, child) {
          final favorites = provider.favoriteCities;
          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'No favorite cities to edit.',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final city = favorites[index];
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E2454),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.location_city, color: Colors.blue),
                  title: Text(
                    city,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Provider.of<AirQualityProvider>(context, listen: false)
                          .removeFavoriteCity(city);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Removed $city from favorites.')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
