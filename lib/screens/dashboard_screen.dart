import 'package:flutter/material.dart';
import 'dart:math';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04; // 4% of screen width

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A3D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () {
            // Implement edit action
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: () {
              // Implement add action
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          _buildLocationCard(
            context,
            location: 'SAMPA',
            quality: 'Moderate',
            aqi: 50,
            time: 'Mar 29 19:30, local time',
            color: Colors.yellow,
            graphColor: Colors.green,
          ),
          SizedBox(height: horizontalPadding),
          _buildLocationCard(
            context,
            location: 'SUNYANI',
            quality: 'High',
            aqi: 68,
            time: 'Mar 29 19:30, local time',
            color: Colors.orange,
            graphColor: Colors.orange,
          ),
          SizedBox(height: horizontalPadding),
          _buildLocationCard(
            context,
            location: 'PARIS',
            quality: 'High',
            aqi: 56,
            time: 'Mar 29 20:30, local time',
            color: Colors.orange,
            graphColor: Colors.yellow,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Handle home tap
              break;
            case 1:
              // Handle discover tap
              break;
            case 2:
              // Handle location tap
              break;
            case 3:
              // Handle settings tap
              break;
          }
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

  Widget _buildLocationCard(
    BuildContext context, {
    required String location,
    required String quality,
    required int aqi,
    required String time,
    required Color color,
    required Color graphColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final cardPadding = screenWidth * 0.04;
    final fontSize = isSmallScreen ? 0.9 : 1.0;

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
                      location,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14 * fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      quality == 'High'
                          ? Icons.notifications
                          : Icons.location_on,
                      color: Colors.white70,
                      size: 14 * fontSize,
                    ),
                  ],
                ),
              ),
              _buildAQIIndicator(context, aqi: aqi, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            quality,
            style: TextStyle(
              color: color,
              fontSize: 28 * fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12 * fontSize,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40 * fontSize,
            child: CustomPaint(
              painter: HourlyGraphPainter(color: graphColor),
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
                      'Daily Average',
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
                      day: 'SUN',
                      color: color,
                      fontSize: fontSize,
                    ),
                    _DayIndicator(
                      day: 'MON',
                      color: color,
                      fontSize: fontSize,
                    ),
                    _DayIndicator(
                      day: 'TUE',
                      color: color,
                      fontSize: fontSize,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAQIIndicator(
    BuildContext context, {
    required int aqi,
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
                    aqi.toString(),
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
}

class _DayIndicator extends StatelessWidget {
  final String day;
  final Color color;
  final double fontSize;

  const _DayIndicator({
    required this.day,
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
            fontSize: 12 * fontSize,
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

  HourlyGraphPainter({required this.color});

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

    // Create data points for the graph
    List<Offset> points = [];
    for (var i = 0; i <= size.width; i++) {
      final x = i.toDouble();
      final progress = i / size.width;

      // Create a more natural curve that matches the image
      final y = size.height *
          (0.8 - 0.5 * sin(progress * pi) * sin(progress * 2 * pi));
      points.add(Offset(x, y));
    }

    // Draw the curve
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      }

      path.lineTo(p2.dx, p2.dy);
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
