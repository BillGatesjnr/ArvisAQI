import 'package:flutter/material.dart';
import 'package:arvisaqi/screens/welcome_screen.dart';
import 'package:arvisaqi/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arvis AQI',
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold();
}
