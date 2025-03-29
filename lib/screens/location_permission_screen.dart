import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'notification_permission_screen.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  Future<void> _requestLocationPermission(BuildContext context) async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permission denied
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission denied forever
        return;
      }

      // Permission granted (either whileInUse or always), navigate to notification screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationPermissionScreen(),
          ),
        );
      }
    } catch (e) {
      // Handle errors
      debugPrint('Error requesting location permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/location_illustration.png',
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(33, 150, 243, 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 64,
                          color: Colors.blue[300],
                        ),
                        Icon(
                          Icons.wb_sunny,
                          size: 32,
                          color: Colors.orange[300],
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          height: 32,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 16,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ...List.generate(
                                4,
                                (index) => Container(
                                  margin: const EdgeInsets.only(left: 2),
                                  width: 8,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              const Text(
                'Get air quality nearby',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Allow the app to access your device\'s location to get air quality and weather information around you.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _requestLocationPermission(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
