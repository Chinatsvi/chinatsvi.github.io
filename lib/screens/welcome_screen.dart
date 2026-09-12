import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app/routes/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If a user is already authenticated, don't show Welcome — redirect.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.community);
      }
    });
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Warm gradient overlay for soft lighting
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.45),
                  ],
                ),
              ),
            ),
          ),

          // Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 18),

                  // Top tractor icon (clean, no heavy card)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.agriculture,
                      color: Colors.green[300],
                      size: 56,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title and subtitle
                  Text(
                    'Welcome to AgriBase',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Connect, learn and grow your farm community',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Central feature buttons placed directly on the image (no heavy cards)
                  Expanded(
                    child: Center(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _featureButton(context, Icons.storefront, 'Marketplace'),
                          _featureButton(context, Icons.book, 'Guidebooks'),
                          _featureButton(context, Icons.people, 'Community'),
                          _featureButton(context, Icons.support_agent, 'Advisory'),
                        ],
                      ),
                    ),
                  ),

                  // Bottom action buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _glowButton(
                            context,
                            label: 'Log In',
                            colors: [Color(0xFF7C4DFF), Color(0xFF5E2BFF)],
                            onTap: () {
                              Navigator.of(context).pushNamed('/login');
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _glowButton(
                            context,
                            label: 'Create Account',
                            colors: [Color(0xFF34D399), Color(0xFF10B981)],
                            onTap: () {
                              Navigator.of(context).pushNamed('/signup');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(BuildContext context, IconData icon, String label) {
    // Deprecated: kept for reference. Use _featureButton instead.
    return const SizedBox.shrink();
  }

  Widget _featureButton(BuildContext context, IconData icon, String label) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white.withOpacity(0.06),
        foregroundColor: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.85),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _glowButton(BuildContext context,
      {required String label,
      required List<Color> colors,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.28),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
