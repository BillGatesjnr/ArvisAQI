import 'package:flutter/material.dart';
//import 'onboarding_screen.dart';
import '../utils/page_transitions.dart';
import 'location_permission_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class NotificationPermissionScreen extends StatelessWidget {
  NotificationPermissionScreen({super.key});

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<bool> requestNotificationPermission(BuildContext context) async {
    // Use permission_handler for Android 13+ and iOS
    final status = await Permission.notification.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Notification permission permanently denied. Please enable it in system settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return false;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        final shouldExit = await _onWillPop(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF8F9FB),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: colorScheme.secondary,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                SlidePageRouteWithReverse(
                  page: LocationPermissionScreen(),
                ),
              );
            },
          ),
          backgroundColor: Color(0xFFF8F9FB),
          elevation: 0,
        ),
        body: Container(
          width: double.infinity,
          color: Color(0xFFF8F9FB),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedOpacity(
                            opacity: 1.0,
                            duration: Duration(milliseconds: 900),
                            curve: Curves.easeIn,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.secondary.withAlpha(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.secondary.withAlpha(30),
                                    blurRadius: 18,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Icon(
                                Icons.notifications_active,
                                size: isSmallScreen ? 56 : 72,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                          Text(
                            'Stay Informed Instantly',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Receive alerts when the air quality is deteriorating around you and get recommendations.',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 32 : 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final granted =
                              await requestNotificationPermission(context);
                          if (granted) {
                            // Set onboardingComplete flag
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('onboardingComplete', true);
                            // Navigate to dashboard and clear stack
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/dashboard',
                              (route) => false,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Notification permission denied')),
                            );
                          }
                        },
                        icon: Icon(Icons.notifications, color: Colors.white),
                        label: Text(
                          'Allow Notifications',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        // Set notificationsEnabled to false
                        final settings = Provider.of<SettingsProvider>(context,
                            listen: false);
                        await settings.setNotificationsEnabled(false);
                        // Set onboardingComplete flag
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboardingComplete', true);
                        // Show SnackBar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'You can enable notifications later in Settings.')),
                        );
                        // Navigate to dashboard and clear stack
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/dashboard',
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Not Now',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exit',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        content: const Text('Close the app?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No', style: TextStyle(fontSize: 14)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes', style: TextStyle(fontSize: 14)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      ),
    );
    return shouldExit == true;
  }
}
