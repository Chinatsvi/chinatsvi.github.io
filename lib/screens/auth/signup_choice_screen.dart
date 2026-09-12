import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/auth_controller.dart';
import 'package:agribased/app/routes/app_routes.dart';
import '../profile/farmer_profile_edit_screen.dart';
import 'signup_screen.dart';

class SignUpButtons extends StatelessWidget {
  final VoidCallback onEmail;
  final Future<void> Function()? onGoogle;

  const SignUpButtons({super.key, required this.onEmail, this.onGoogle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.email),
          label: const Text('Sign up with email and password'),
          onPressed: onEmail,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const FaIcon(FontAwesomeIcons.google, color: Colors.red),
          label: const Text('Sign up with your Google account'),
          onPressed: () async {
            if (onGoogle != null) await onGoogle!();
          },
        ),
      ],
    );
  }
}

class SignUpChoiceScreen extends StatefulWidget {
  const SignUpChoiceScreen({super.key});

  @override
  State<SignUpChoiceScreen> createState() => _SignUpChoiceScreenState();
}

class _SignUpChoiceScreenState extends State<SignUpChoiceScreen> {
  final AuthController _authController = AuthController();
  bool _loading = false;

  Future<bool> _farmerProfileExists(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking farmer profile: $e');
      return false;
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _loading = true);
    try {
      final user = await _authController.signUpWithGoogle();
      if (user == null) throw Exception('Google sign up returned null');

      final hasProfile = await _farmerProfileExists(user.uid);

      if (!mounted) return;
      if (hasProfile) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FarmerProfileEditScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FarmerProfileEditScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign up failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SignUpButtons(
                            onEmail: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignUpScreen(showAuthButtons: false),
                                ),
                              );
                            },
                            onGoogle: _handleGoogleSignUp,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
