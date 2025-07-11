import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';
import 'favorites_screen.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Automatically refresh data when widget loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(context);
    });
  }

  Future<void> _refreshData(BuildContext context) async {
    setState(() => _isRefreshing = true);
    await Provider.of<AirQualityProvider>(context, listen: false)
        .fetchCurrentLocationData();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AirQualityProvider>(context);
    final currentData = provider.currentData;

    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A1A3D),
                Color(0xFF0A1A3D),
                Color(0xFF0A1A3D),
              ],
            ),
          ),
        ),

        // Content
        if (currentData != null)
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 100, bottom: 100),
            child: Column(
              children: [
                _AqiHeroCard(
                  aqi: currentData.aqi.round(),
                  category: currentData.category,
                  color: currentData.color,
                  city: currentData.city,
                  time: _formatDate(currentData.timestamp),
                ),
                const SizedBox(height: 24),
                _PollutantsGrid(pollutants: currentData.pollutants),
              ],
            ),
          ),

        if (provider.isLoading && currentData == null)
          const Center(
            child: CircularProgressIndicator(),
          ),

        // App Bar with actions
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Air Quality',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoritesScreen(showSearch: true),
                  ),
                ),
              ),
              _isRefreshing
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () => _refreshData(context),
                      tooltip: 'Refresh Data',
                    ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final month = _getMonthAbbreviation(date.month);
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour < 12 ? 'AM' : 'PM';
    return 'Updated $month ${date.day} at $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

class _AqiHeroCard extends StatelessWidget {
  final int aqi;
  final String category;
  final Color color;
  final String city;
  final String time;

  const _AqiHeroCard({
    required this.aqi,
    required this.category,
    required this.color,
    required this.city,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(51),
            color.withAlpha(26),
            Colors.transparent,
          ],
        ),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    city,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color.withAlpha(77), Colors.transparent],
                    stops: const [0.1, 1.0],
                  ),
                ),
              ),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(51),
                  border: Border.all(color: color.withAlpha(128), width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$aqi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'AQI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            category.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PollutantsGrid extends StatelessWidget {
  final Map<String, double>? pollutants;

  const _PollutantsGrid({required this.pollutants});

  @override
  Widget build(BuildContext context) {
    if (pollutants == null || pollutants!.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: pollutants!.length,
        itemBuilder: (context, index) {
          final item = pollutants!.entries.elementAt(index);
          return _PollutantCard(name: item.key, value: item.value);
        },
      ),
    );
  }
}

class _PollutantCard extends StatelessWidget {
  final String name;
  final double value;

  const _PollutantCard({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForPollutant(name, value);
    final level = _getLevelForPollutant(name, value);
    final unit = _getUnitForPollutant(name);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF142A5E).withOpacity(0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _getProgressValue(value, name),
            backgroundColor: Colors.white.withOpacity(0.1),
            color: color,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  double _getProgressValue(double value, String name) {
    switch (name.toLowerCase()) {
      case 'pm25':
        return (value / 250).clamp(0.0, 1.0);
      case 'pm10':
        return (value / 350).clamp(0.0, 1.0);
      case 'o3':
        return (value / 200).clamp(0.0, 1.0);
      case 'no2':
        return (value / 200).clamp(0.0, 1.0);
      case 'so2':
        return (value / 350).clamp(0.0, 1.0);
      case 'co':
        return (value / 30).clamp(0.0, 1.0);
      default:
        return (value / 100).clamp(0.0, 1.0);
    }
  }

  String _getLevelForPollutant(String name, double value) {
    if (value < 50) return 'Good';
    if (value < 100) return 'Moderate';
    if (value < 150) return 'Unhealthy';
    if (value < 200) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color _getColorForPollutant(String name, double value) {
    if (value < 50) return Colors.green;
    if (value < 100) return Colors.yellow;
    if (value < 150) return Colors.orange;
    if (value < 200) return Colors.red;
    return Colors.purple;
  }

  String _getUnitForPollutant(String name) {
    switch (name.toLowerCase()) {
      case 'pm25':
      case 'pm10':
        return 'µg/m³';
      case 'o3':
      case 'no2':
      case 'so2':
        return 'ppb';
      case 'co':
        return 'ppm';
      default:
        return '';
    }
  }
}
