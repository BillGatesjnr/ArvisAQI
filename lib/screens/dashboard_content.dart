import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;
    return Consumer<AirQualityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }
        if (provider.error != null && provider.currentData == null) {
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
          return const Center(
            child: Text('No data available',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          );
        }
        return ListView(
          padding: EdgeInsets.all(horizontalPadding),
          children: [
            // You can use your _buildLocationCard and favorite city cards here
            // For brevity, just show a placeholder
            // Replace this with your actual dashboard content logic
            Text('Dashboard Home Content',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ],
        );
      },
    );
  }
}
