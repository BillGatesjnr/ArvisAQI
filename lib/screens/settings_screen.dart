import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import '../main.dart' as main;
import '../providers/air_quality_provider.dart'; // Added for AirQualityProvider
import '../screens/privacy_policy_screen.dart'; // Added for PrivacyPolicyScreen
import 'package:shared_preferences/shared_preferences.dart'; // Added for SharedPreferences

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showDeveloperTools = false;

  void _toggleDeveloperTools() {
    setState(() {
      _showDeveloperTools = !_showDeveloperTools;
    });
  }

  Future<void> _onAqiAlertsChanged(BuildContext context, bool enabled) async {
    if (enabled) {
      // Get current location
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            // position = await Geolocator.getCurrentPosition(); // Removed unused variable
          }
        }
      } catch (e) {
        debugPrint(
            'DEBUG: Failed to get current position for notification: $e');
      }
      // Use current location if available, else fallback to Ghana center
      // Send instant AQI alert
      final provider = Provider.of<AirQualityProvider>(context, listen: false);
      final data = provider.currentData;
      if (data != null) {
        await main.showNotification(
          'Air Quality Update',
          'Current AQI in ${data.city}: ${data.aqi.toStringAsFixed(0)} (${data.category})',
          notificationId: 1,
        );
        debugPrint('DEBUG: Sent INSTANT AQI update notification');
        if (data.aqi > 50) {
          final rec = main.getHealthRecommendation(data.aqi);
          await main.showNotification(
            'Health Recommendation',
            'In ${data.city}: $rec',
            notificationId: 2,
          );
          debugPrint(
              'DEBUG: Sent INSTANT health recommendation notification (AQI=${data.aqi})');
        } else {
          debugPrint(
              'DEBUG: AQI is good, no INSTANT health recommendation sent (AQI=${data.aqi})');
        }
      } else {
        debugPrint(
            'DEBUG: No current AQI data available for INSTANT notification');
      }
      // Schedule 30-min AQI alert
      await Workmanager().registerPeriodicTask(
        'aqiAlertTask',
        'aqiAlertTask',
        frequency: const Duration(minutes: 30),
        initialDelay: const Duration(seconds: 10), // optional, for debug
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      // Schedule 10-min health rec alert
      await Workmanager().registerPeriodicTask(
        'healthRecTask',
        'healthRecTask',
        frequency: const Duration(minutes: 10),
        initialDelay: const Duration(seconds: 20), // optional, for debug
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      debugPrint('DEBUG: Scheduled AQI and health recommendation alerts');
    } else {
      await Workmanager().cancelByUniqueName('aqiAlertTask');
      await Workmanager().cancelByUniqueName('healthRecTask');
      debugPrint('DEBUG: Cancelled AQI and health recommendation alerts');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _SectionHeader(title: 'Account'),
          Card(
            color: Colors.black.withOpacity(0.55),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.white70),
                title: Text(auth.userEmail,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                subtitle: const Text('Signed in',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  color: Theme.of(context).colorScheme.surface,
                  onSelected: (String value) {
                    if (value == 'signout') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          title: const Text('Sign out',
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                              'Are you sure you want to sign out?',
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            TextButton(
                              onPressed: () async {
                                auth.signOut();
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool(
                                    'onboardingComplete', false);
                                Navigator.of(ctx).pop();
                                if (mounted) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/onboarding', (route) => false);
                                }
                              },
                              child: const Text('Sign out',
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                    } else if (value == 'manage') {
                      auth.manageAccount();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          title: const Text('Manage Account',
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                              'Account management is not implemented yet.',
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('OK',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'manage',
                      child: Text('Manage Account',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 'signout',
                      child: Text('Sign Out',
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Notifications Section
          _SectionHeader(title: 'Notifications'),
          Card(
            color: Colors.black.withOpacity(0.55),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                children: [
                  SwitchListTile(
                    value: settings.notificationsEnabled,
                    onChanged: (v) {
                      settings.setNotificationsEnabled(v);
                      _onAqiAlertsChanged(context, v);
                    },
                    title: const Text('Air Quality Alerts',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    activeColor: Colors.blue,
                    inactiveThumbColor: Colors.grey,
                    tileColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  SwitchListTile(
                    value: settings.dailySummaryEnabled,
                    onChanged: (v) => settings.setDailySummaryEnabled(v),
                    title: const Text('Daily Summary',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    activeColor: Colors.blue,
                    inactiveThumbColor: Colors.grey,
                    tileColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ],
              ),
            ),
          ),
          // Theme Section
          _SectionHeader(title: 'Appearance'),
          Card(
            color: Colors.black.withOpacity(0.55),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: const Icon(Icons.brightness_6, color: Colors.white70),
                title: const Text('Theme',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                trailing: DropdownButton<AppThemeMode>(
                  value: settings.themeMode,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  underline: Container(),
                  onChanged: (mode) {
                    if (mode != null) settings.setThemeMode(mode);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: AppThemeMode.dark,
                      child: Text('Dark'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.blueBlack,
                      child: Text('Blue Black'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.blueAccent,
                      child: Text('Blue Accent'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.midnight,
                      child: Text('Midnight'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.slate,
                      child: Text('Slate'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.deepPurple,
                      child: Text('Deep Purple'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.emerald,
                      child: Text('Emerald'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.sunset,
                      child: Text('Sunset'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.ocean,
                      child: Text('Ocean'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.ruby,
                      child: Text('Ruby'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.glass,
                      child: Text('Glassmorphism'),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.pureDark,
                      child: Text('Pure Dark'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Location Section
          _SectionHeader(title: 'Location'),
          Card(
            color: Colors.black.withOpacity(0.55),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 20),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: LocationPermissionManager(),
            ),
          ),
          // Data Section
          _SectionHeader(title: 'Data Preferences'),
          Card(
            color: Colors.black.withOpacity(0.55),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud, color: Colors.white70),
                    title: const Text('Preferred AQI Source',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    trailing: DropdownButton<AQISource>(
                      value: settings.aqiSource,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      underline: Container(),
                      onChanged: (src) {
                        if (src != null) settings.setAQISource(src);
                      },
                      items: const [
                        DropdownMenuItem(
                          value: AQISource.waqi,
                          child: Text('WAQI'),
                        ),
                        DropdownMenuItem(
                          value: AQISource.openWeatherMap,
                          child: Text('OpenWeatherMap'),
                        ),
                        DropdownMenuItem(
                          value: AQISource.airVisual,
                          child: Text('AirVisual'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer, color: Colors.white70),
                    title: const Text('Data Refresh Interval',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    trailing: DropdownButton<int>(
                      value: settings.refreshInterval,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      underline: Container(),
                      onChanged: (v) {
                        if (v != null) settings.setRefreshInterval(v);
                      },
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 min')),
                        DropdownMenuItem(value: 30, child: Text('30 min')),
                        DropdownMenuItem(value: 60, child: Text('1 hour')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Privacy Policy
          _SectionHeader(title: 'Privacy'),
          Card(
            color: Colors.black.withOpacity(0.55),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 20),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.white70),
              title: const Text('Privacy Policy',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                PrivacyPolicyScreen.showPolicyDialog(context);
              },
            ),
          ),
          // About
          _SectionHeader(title: 'About'),
          Card(
            color: Colors.black.withOpacity(0.55),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 20),
            child: GestureDetector(
              onLongPress: _toggleDeveloperTools,
              child: ListTile(
                leading: const Icon(Icons.info, color: Colors.white70),
                title: const Text('About ARVISAQI',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                trailing:
                    const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'ArvisAQI',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.cloud, size: 40),
                    children: [
                      const Text('A modern air quality monitoring app.'),
                      const SizedBox(height: 8),
                      const Text('Contact: support@arvisaqi.com'),
                    ],
                  );
                },
              ),
            ),
          ),
          if (_showDeveloperTools) ...[
            _SectionHeader(title: 'Developer Tools'),
            Card(
              color: Colors.red.withOpacity(0.55),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: const Icon(Icons.restart_alt, color: Colors.white),
                title: const Text('Reset Onboarding',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                trailing:
                    const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      title: const Text('Reset Onboarding',
                          style: TextStyle(color: Colors.white)),
                      content: const Text(
                          'Are you sure you want to reset onboarding? This will restart the onboarding flow.',
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.white)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Reset',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboardingComplete', false);
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/onboarding', (route) => false);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class LocationPermissionManager extends StatefulWidget {
  const LocationPermissionManager({Key? key}) : super(key: key);

  @override
  State<LocationPermissionManager> createState() =>
      _LocationPermissionManagerState();
}

class _LocationPermissionManagerState extends State<LocationPermissionManager> {
  LocationPermission? _permission;
  bool _isLoading = false;
  String? _error;
  bool _serviceEnabled = false;
  late final Duration _pollInterval;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollInterval = const Duration(seconds: 2);
    _checkStatus();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      if (mounted) {
        setState(() {
          _serviceEnabled = serviceEnabled;
          _permission = permission;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error checking status: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Widget build(BuildContext context) {
    String statusText = 'Enabled';
    Color statusColor = Colors.grey;

    if (!_serviceEnabled) {
      // Use a Row for icon and status, and place the button below
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_off,
                    color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Status: Disabled',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withAlpha(51),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _openLocationSettings,
                child: const Text(
                  'Enable Location',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    }
    // When enabled, use the normal ListTile UI
    return ListTile(
      leading: const Icon(Icons.location_on, color: Colors.white70),
      title: const Text('Location Settings',
          style: TextStyle(color: Colors.white, fontSize: 12)),
      subtitle: _isLoading
          ? const Padding(
              padding: EdgeInsets.only(top: 4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white70),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Status: ',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      TextSpan(
                        text: statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 10)),
                  ),
                if (_serviceEnabled &&
                    (_permission == LocationPermission.always ||
                        _permission == LocationPermission.whileInUse))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Location is fully enabled.',
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 10)),
                  ),
              ],
            ),
      trailing: null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
