import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const offWhite = Color(0xFFF8F9FB);
    return Scaffold(
      backgroundColor: offWhite,
      body: Stack(
        children: [
          // Deep space background
          Container(
            color: offWhite,
          ),

          // Removed the animated particles CustomPaint here

          // Gradient blobs
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: 100 + 50 * sin(_animation.value),
                    left: -100 + 50 * cos(_animation.value * 0.7),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF3949AB)
                                .withAlpha((0.3 * 255).toInt()),
                            Colors.transparent,
                          ],
                          stops: const [0.1, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150 + 50 * cos(_animation.value * 1.2),
                    right: -100 + 50 * sin(_animation.value * 0.5),
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF1A237E)
                                .withAlpha((0.3 * 255).toInt()),
                            Colors.transparent,
                          ],
                          stops: const [0.1, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.of(context).size.width < 500 ? 24.0 : 0.0,
                    vertical:
                        MediaQuery.of(context).size.height < 700 ? 24.0 : 0.0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha((0.08 * 255).toInt()),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.black.withAlpha((0.10 * 255).toInt()),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha((0.10 * 255).toInt()),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(36.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Sign up to Arvis AQI',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            _buildSignInButton(
                              context,
                              text: 'Continue with email',
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              textColor: Colors.white,
                              icon: Icons.email_outlined,
                              onPressed: () {
                                // Implement email sign up
                              },
                            ),
                            const SizedBox(height: 18),
                            _buildSignInButton(
                              context,
                              text: 'Continue with Google',
                              backgroundColor: Colors.white,
                              textColor:
                                  Theme.of(context).colorScheme.secondary,
                              iconAsset: 'assets/images/google_icon.png',
                              onPressed: () {
                                // Implement Google sign in
                              },
                            ),
                            const SizedBox(height: 32),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account?",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Navigate to sign in
                                  },
                                  child: Text(
                                    "Sign in",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: offWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
    );
  }

  Widget _buildSignInButton(
    BuildContext context, {
    required String text,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black87,
    IconData? icon,
    String? iconAsset,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: backgroundColor == Colors.white
                ? const BorderSide(color: Colors.black12)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
            ] else if (iconAsset != null) ...[
              Image.asset(
                iconAsset,
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(width: 24, height: 24);
                },
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
