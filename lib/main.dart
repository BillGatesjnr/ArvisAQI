import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:arvisaqi/theme/app_theme.dart';
import 'package:arvisaqi/screens/dashboard_screen.dart'
    show DashboardScreen, RouteObserverProvider;
import 'package:arvisaqi/screens/splash_screen.dart';
import 'package:arvisaqi/screens/onboarding_screen.dart';
import 'package:arvisaqi/screens/privacy_policy_screen.dart';
import 'package:arvisaqi/screens/location_permission_screen.dart';
import 'package:arvisaqi/screens/notification_permission_screen.dart';
import 'package:provider/provider.dart';
import 'providers/air_quality_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/air_quality_data.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> showNotification(String title, String body,
    {int notificationId = 0}) async {
  final String channelId =
      title == 'Air Quality Update' ? 'aqi_alerts_new' : 'health_alerts_new';
  final String channelName =
      title == 'Air Quality Update' ? 'AQI Alerts New' : 'Health Alerts New';

  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: 'Notifications for $channelName',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    styleInformation: BigTextStyleInformation(body),
  );
  final NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
      notificationId, title, body, platformChannelSpecifics);
}

String getHealthRecommendation(double aqi) {
  if (aqi <= 50)
    return 'Great news! Air quality is excellent today. Enjoy outdoor activities freely, no mask needed. Have a wonderful day!';
  if (aqi <= 100)
    return 'Heads up! Air quality is moderate. Most people can be active outside without concern, but if you have asthma or other sensitivities, consider lighter outdoor activity. No mask is needed for most.';
  if (aqi <= 150)
    return 'Please take care! Air quality may affect sensitive groups. If you have respiratory or heart conditions, limit long outdoor activities. Consider wearing a well-fitted mask (like an N95) if you\'re outside for extended periods.';
  if (aqi <= 200)
    return 'Important alert: Air quality is unhealthy for everyone. Reduce outdoor time if you can. If you must go out, wearing a certified protective mask (N95 or equivalent) is recommended. Take care of yourself and your loved ones.';
  if (aqi <= 300)
    return ' Serious warning! Air quality is very unhealthy today. Stay indoors as much as possible. If going outside is unavoidable, wear a well-fitted, certified protective mask. Your health is our priority.';
  return 'Urgent alert! Air quality is hazardous. Everyone should stay indoors and avoid all outdoor activity. Even with a mask, outdoor air is dangerous. Please prioritize your safety today.';
}

// Workmanager task names
const String aqiAlertTask = 'aqiAlertTask';
const String healthRecTask = 'healthRecTask';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await dotenv.load(fileName: ".env");
    // Read cached AQI data
    final cachedJson = await SharedPreferences.getInstance()
        .then((prefs) => prefs.getString('cached_current_aqi'));
    if (cachedJson == null) {
      debugPrint('DEBUG: No cached AQI data available for notification');
      return Future.value(true);
    }
    final data = AirQualityData.fromJson(jsonDecode(cachedJson));
    if (task == aqiAlertTask) {
      final locationName = data.city;
      await showNotification('Air Quality Update',
          'Current AQI in $locationName: ${data.aqi.toStringAsFixed(0)} (${data.category})',
          notificationId: 1);
      debugPrint('DEBUG: Sent AQI update notification');
      // Add a delay before sending health recommendation if needed
      if (data.aqi > 50) {
        await Future.delayed(const Duration(seconds: 10));
        final rec = getHealthRecommendation(data.aqi);
        await showNotification(
            'Health Recommendation', 'In $locationName: $rec',
            notificationId: 2);
        debugPrint(
            'DEBUG: Sent health recommendation notification (AQI=${data.aqi})');
      } else {
        debugPrint(
            'DEBUG: AQI is good, no health recommendation sent (AQI=${data.aqi})');
      }
    } else if (task == healthRecTask) {
      if (data.aqi > 50) {
        final rec = getHealthRecommendation(data.aqi);
        final locationName = data.city;
        await showNotification(
            'Health Recommendation', 'In $locationName: $rec',
            notificationId: 2);
        debugPrint(
            'DEBUG: Sent health recommendation notification (AQI=${data.aqi})');
      } else {
        debugPrint(
            'DEBUG: AQI is good, no health recommendation sent (AQI=${data.aqi})');
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  debugPrint('DEBUG: Notifications and Workmanager initialized');
  runApp(
    RouteObserverProvider(
      observer: RouteObserver<PageRoute>(),
      child: MyApp(initialRoute: '/'),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AirQualityProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          ThemeData theme;
          switch (settings.themeMode) {
            case AppThemeMode.dark:
              theme = AppTheme.darkTheme;
              break;
            case AppThemeMode.blueBlack:
              theme = AppTheme.blueBlackTheme;
              break;
            case AppThemeMode.blueAccent:
              theme = AppTheme.blueAccentTheme;
              break;
            case AppThemeMode.midnight:
              theme = AppTheme.midnightTheme;
              break;
            case AppThemeMode.slate:
              theme = AppTheme.slateTheme;
              break;
            case AppThemeMode.deepPurple:
              theme = AppTheme.deepPurpleTheme;
              break;
            case AppThemeMode.emerald:
              theme = AppTheme.emeraldTheme;
              break;
            case AppThemeMode.sunset:
              theme = AppTheme.sunsetTheme;
              break;
            case AppThemeMode.ocean:
              theme = AppTheme.oceanTheme;
              break;
            case AppThemeMode.ruby:
              theme = AppTheme.rubyTheme;
              break;
            case AppThemeMode.glass:
              theme = AppTheme.glassTheme;
              break;
            case AppThemeMode.pureDark:
              theme = AppTheme.pureDarkTheme;
              break;
          }
          return MaterialApp(
            title: 'ArvisAQI',
            debugShowCheckedModeBanner: false,
            theme: theme,
            initialRoute: initialRoute,
            routes: {
              '/': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/privacy_policy': (context) => const PrivacyPolicyScreen(),
              '/location-permission': (context) =>
                  const LocationPermissionScreen(),
              '/notification-permission': (context) =>
                  NotificationPermissionScreen(),
              '/dashboard': (context) => const DashboardScreen(),
            },
          );
        },
      ),
    );
  }
}
