import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/air_quality_provider.dart';
import '../services/air_quality_marker_cache.dart';
import '../services/air_quality_location_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _mainController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late List<Animation<double>> _letterAnimations;
  final String appName = 'ArvisAQI';
  bool _logoAnimated = false;
  bool _taglineAnimated = false;
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A1A3D),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _mainController = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Create animations for each letter
    _letterAnimations = List.generate(
      appName.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: Interval(
            0.02 + (index * 0.01),
            0.10 + (index * 0.01),
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );

    _logoController.forward().then((_) {
      setState(() {
        _logoAnimated = true;
      });
      _mainController.repeat();
    });
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        setState(() {
          _taglineAnimated = true;
        });
      }
    });

    // Start preloading in background
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      preloadAppData();
      // Check onboardingComplete flag
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
      setState(() {
        _onboardingComplete = onboardingComplete;
      });
      // Navigate after splash duration
      Timer(const Duration(seconds: 12), () {
        if (!mounted) return;
        if (_onboardingComplete == true) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/dashboard', (route) => false);
        } else {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/onboarding', (route) => false);
        }
      });
    });
  }

  Future<void> preloadAppData() async {
    if (!mounted) return;
    print('DEBUG: Splash preloading started');
    final airQualityProvider =
        Provider.of<AirQualityProvider>(context, listen: false);
    // Preload location AQI (if permission granted)
    try {
      await airQualityProvider.fetchCurrentLocationData();
      if (!mounted) return;
      print('DEBUG: Preloaded location AQI');
    } catch (e) {
      if (!mounted) return;
      print('DEBUG: Preload location AQI failed: $e');
    }
    // Preload map markers (from cache or API)
    try {
      await AirQualityMarkerCache().loadAllMarkers();
      if (!mounted) return;
      print('DEBUG: Preloaded map markers');
    } catch (e) {
      if (!mounted) return;
      print('DEBUG: Preload map markers failed: $e');
    }
    // Preload favorites and their AQI
    try {
      await AirQualityLocationCache().loadFavoritesList();
      await AirQualityLocationCache().loadAllFavoriteAQI();
      if (!mounted) return;
      print('DEBUG: Preloaded favorites and their AQI');
    } catch (e) {
      if (!mounted) return;
      print('DEBUG: Preload favorites failed: $e');
    }
    print('DEBUG: Splash preloading finished');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withAlpha(200),
                ],
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with scale animation (only first play)
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimated ? 1.0 : _scaleAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/arvislogo.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                // App Name with letter-by-letter animation (loops)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    appName.length,
                    (index) => AnimatedBuilder(
                      animation: _letterAnimations[index],
                      builder: (context, child) {
                        final animationValue = _letterAnimations[index].value;
                        return Transform.translate(
                          offset: Offset(
                            0,
                            50 * (1 - animationValue.clamp(0.0, 1.0)),
                          ),
                          child: Opacity(
                            opacity: animationValue.clamp(0.0, 1.0),
                            child: Text(
                              appName[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tagline with fade animation (first play only)
                _taglineAnimated
                    ? const Text(
                        'Your Air Quality Companion',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Your Air Quality Companion',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                const SizedBox(height: 48),
                // Loading Indicator with fade animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.withAlpha(200),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
