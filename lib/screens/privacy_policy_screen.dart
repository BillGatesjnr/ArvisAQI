import 'package:flutter/material.dart';
import 'location_permission_screen.dart';
import '../utils/page_transitions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static void showPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Terms of Use & Privacy Policy',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Last updated: 16th July, 2025\n\n'
                        'ArvisAQI is committed to protecting your privacy. This policy explains how we collect, use, and safeguard your information when you use our mobile application.\n\n'
                        '1. Information We Collect\n\n'
                        '- Location Data: We may collect your device\'s location (with permission) to provide location-specific air quality alerts.\n\n'
                        '- Sensor Data: When connected to local sensors, the app may collect air quality measurements (e.g., PM2.5, CO, VOCs) for display and prediction.\n\n'
                        '- External API Data: We use publicly available air quality data from trusted external APIs to provide forecasts and current conditions.\n\n'
                        '2. How We Use Your Information\n\n'
                        '- To deliver real-time air quality information and forecasts tailored to your location.\n\n'
                        '- To send you alerts about local air quality conditions.\n\n'
                        '- To improve and test our prediction models and app functionality.\n\n'
                        '3. Data Storage and Security\n\n'
                        '- Location and sensor data is stored locally on your device.\n\n'
                        '- We do not transmit or store your personal information on external servers.\n\n'
                        '- We take reasonable steps to protect data stored on your device.\n\n'
                        '4. Third-Party Services\n\n'
                        'Our app fetches air quality data from external APIs (e.g., OpenAQ). We do not control or store data collected by those services.\n\n'
                        'These services have their own privacy policies.\n\n'
                        '5. Your Choices\n\n'
                        '- You can enable or disable location permissions in your device settings at any time.\n\n'
                        '- Without location permissions, some features (like local alerts) may not function.\n\n'
                        '6. Changes to This Policy\n\n'
                        'We may update this policy to reflect improvements to the app or changes in regulations. We will notify users of significant changes.\n\n'
                        '7. Contact Us\n'
                        'For questions about this policy, please contact: support@arvisaqi.com',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black87, height: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('Privacy Policy',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: colorScheme.secondary)),
        backgroundColor: Color(0xFFF8F9FB),
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.secondary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: AnimatedOpacity(
                            opacity: 1.0,
                            duration: Duration(milliseconds: 900),
                            curve: Curves.easeIn,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(18),
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/arvislogo.png',
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF181A20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'ArvisAQI',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: colorScheme.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'We follow high privacy standards',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please agree to Arvis AQI terms of service.',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => showPolicyDialog(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: Text(
                              'Terms of use and privacy policy',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.secondary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  12, 0, 12, MediaQuery.of(context).viewPadding.bottom + 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: colorScheme.secondary),
                      label: Text('Decline',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: colorScheme.secondary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                            color: colorScheme.secondary.withAlpha(102)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          SlidePageRouteWithReverse(
                            page: const LocationPermissionScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.check_circle, color: Colors.white),
                      label: Text('Agree',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
