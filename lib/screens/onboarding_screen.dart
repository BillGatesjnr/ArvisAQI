import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:arvisaqi/screens/signup_screen.dart';
import 'package:arvisaqi/screens/privacy_policy_screen.dart';
import 'package:arvisaqi/utils/page_transitions.dart';
import 'package:flutter/services.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _progressValue = 0.0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _autoSwipeTimer;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Breathe Easier with ArvisAQI',
      description:
          'Track air quality in real-time with the most comprehensive global coverage',
      imageUrl: 'https://cdn-icons-png.flaticon.com/128/12294/12294746.png',
      color: Color(0xFF6A8EAE),
      secondaryColor: Color(0xFFE1F0F7),
      particles: 15,
    ),
    OnboardingContent(
      title: 'Hyperlocal Air Insights',
      description:
          'Precise, street-level air quality data updated every 15 minutes',
      imageUrl: 'https://cdn-icons-png.flaticon.com/512/4144/4144775.png',
      color: Color(0xFF57A773),
      secondaryColor: Color(0xFFE8F5EB),
      particles: 20,
    ),
    OnboardingContent(
      title: 'AI-Powered Health Guidance',
      description:
          'Personalized recommendations based on your location and health profile',
      imageUrl: 'https://cdn-icons-png.flaticon.com/512/4144/4144767.png',
      color: Color(0xFF484D6D),
      secondaryColor: Color(0xFFEAEAF2),
      particles: 25,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _progressValue = (_pageController.page ?? 0) / (_contents.length - 1);
        });
      }
    });
    _animationController.forward();

    _autoSwipeTimer = Timer.periodic(Duration(seconds: 6), (timer) {
      if (!mounted) return;
      int nextPage = _currentPage + 1;
      if (nextPage >= _contents.length) {
        nextPage = 0;
      }
      _animateToPage(nextPage);
    });
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    if (!mounted) return;
    _animationController.reset();
    _pageController
        .animateToPage(
      page,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    )
        .then((_) {
      if (mounted) _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        final shouldExit = await _onWillPop(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Animated gradient background
            AnimatedContainer(
              duration: Duration(milliseconds: 1000),
              decoration: BoxDecoration(
                gradient: SweepGradient(
                  center: Alignment.topRight,
                  startAngle: 0,
                  endAngle: 3.14 * 2,
                  colors: [
                    _contents[_currentPage].secondaryColor,
                    _contents[_currentPage].secondaryColor.withAlpha(200),
                    Colors.white,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Floating particles
            ...List.generate(_contents[_currentPage].particles, (i) {
              final top = Random().nextDouble() * screenSize.height;
              final left = Random().nextDouble() * screenSize.width;
              final size = Random().nextDouble() * 6 + 2;
              return Positioned(
                top: top,
                left: left,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: _contents[_currentPage].color.withAlpha(77),
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  .animate(
                    delay: (i * 100).ms,
                  )
                  .fadeIn(duration: 800.ms)
                  .move(
                    begin: Offset(0, 20),
                    end: Offset(0, 0),
                    duration: 800.ms,
                  );
            }),

            SafeArea(
              child: Column(
                children: [
                  // Progress bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        minHeight: 6,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _contents[_currentPage].color,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _contents.length,
                      itemBuilder: (context, index) {
                        return ScaleTransition(
                          scale: _scaleAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: OnboardingPage(content: _contents[index]),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom controls
                  Padding(
                    padding: EdgeInsets.fromLTRB(32, 0, 32, 40),
                    child: Column(
                      children: [
                        // Animated dots
                        Wrap(
                          spacing: 8,
                          children: List.generate(
                            _contents.length,
                            (index) => GestureDetector(
                              onTap: () => _animateToPage(index),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: _currentPage == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _currentPage == index
                                      ? _contents[_currentPage].color
                                      : Colors.grey.withValues(alpha: 0.3),
                                  boxShadow: _currentPage == index
                                      ? [
                                          BoxShadow(
                                            color: _contents[_currentPage]
                                                .color
                                                .withAlpha(77),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 32),

                        // Sign Up button
                        AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _contents[_currentPage].color,
                                Color.lerp(_contents[_currentPage].color,
                                    Colors.black, 0.1)!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _contents[_currentPage]
                                    .color
                                    .withAlpha(102),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SlidePageRouteWithReverse(
                                    page: const SignUpScreen(),
                                  ),
                                );
                              },
                              child: Center(
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ).animate().scale(
                              delay: 300.ms,
                              duration: 500.ms,
                            ),

                        SizedBox(height: 16),

                        // Guest button
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.transparent,
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SlidePageRouteWithReverse(
                                    page: PrivacyPolicyScreen(),
                                  ),
                                );
                              },
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Continue as ',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Guest',
                                      style: TextStyle(
                                        color: _contents[_currentPage].color,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(
                                            color: _contents[_currentPage]
                                                .color
                                                .withAlpha(51),
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
          ],
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

class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const OnboardingPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final maxTextScale = 1.0; // No scaling for onboarding
    final constrainedMediaQuery = MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(maxTextScale),
    );
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.32; // 32% for image
    final textHeight = screenHeight * 0.22; // 22% for text
    final spacerHeight = screenHeight * 0.04; // 4% for spacer

    return MediaQuery(
      data: constrainedMediaQuery,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: imageHeight,
              child: Container(
                padding: EdgeInsets.all(24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background glow
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: content.color.withValues(alpha: 0.1),
                      ),
                    ),
                    // Network image with loading and error handling
                    Image.network(
                      content.imageUrl,
                      width: 280,
                      fit: BoxFit.contain,
                      loadingBuilder:
                          (context, child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.grey.shade400,
                        );
                      },
                    ).animate().scale(
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ],
                ),
              ),
            ),
            SizedBox(height: spacerHeight),
            SizedBox(
              height: textHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    content.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: content.color,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 500.ms,
                      ),
                  SizedBox(height: 8),
                  Text(
                    content.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 500.ms,
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

class OnboardingContent {
  final String title;
  final String description;
  final String imageUrl;
  final Color color;
  final Color secondaryColor;
  final int particles;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.color,
    required this.secondaryColor,
    this.particles = 15,
  });
}
