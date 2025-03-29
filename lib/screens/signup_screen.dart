import 'package:flutter/material.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Sign up to Arvis AQI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              _buildSignInButton(
                context,
                text: 'Continue with email',
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                onPressed: () {
                  // Implement email sign up
                },
              ),
              const SizedBox(height: 16),
              _buildSignInButton(
                context,
                text: 'Continue with Google',
                icon: 'assets/images/google_icon.png',
                onPressed: () {
                  // Implement Google sign in
                },
              ),
              const SizedBox(height: 16),
              _buildSignInButton(
                context,
                text: 'Continue with Facebook',
                icon: 'assets/images/facebook_icon.png',
                onPressed: () {
                  // Implement Facebook sign in
                },
              ),
              const SizedBox(height: 16),
              _buildSignInButton(
                context,
                text: 'Continue with Apple',
                icon: 'assets/images/apple_icon.png',
                onPressed: () {
                  // Implement Apple sign in
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(
    BuildContext context, {
    required String text,
    String? icon,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black87,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: backgroundColor == Colors.white
                ? const BorderSide(color: Colors.black12)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Image.asset(
                icon,
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(width: 24, height: 24);
                },
              ),
              const SizedBox(width: 12),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
