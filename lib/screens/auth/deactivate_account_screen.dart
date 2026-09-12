import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/auth_controller.dart';
import '../../services/auth_state_storage.dart';
import '../../services/google_sign_in_service.dart';
import 'package:agribased/app/routes/app_routes.dart';

class DeactivateAccountScreen extends StatelessWidget {
  const DeactivateAccountScreen({super.key});

  Future<void> _deactivateAccount(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) return;

    // =======================
    // CONFIRMATION
    // =======================
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Deactivation'),
        content: const Text(
          'Are you sure you want to deactivate your account?\n'
          'You can reactivate it by logging in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // =======================
      // REAUTHENTICATION
      // =======================
      if (user.providerData.any((p) => p.providerId == 'password')) {
        final passwordController = TextEditingController();

        final reauth = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Re-authenticate'),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );

        if (reauth != true) return;

        final email = user.email;
        if (email == null || email.isEmpty) {
          throw Exception('User email not available');
        }
        final cred = EmailAuthProvider.credential(
          email: email,
          password: passwordController.text.trim(),
        );
        await user.reauthenticateWithCredential(cred);
      }
      // GOOGLE
      else if (user.providerData.any((p) => p.providerId == 'google.com')) {
        final googleCred = await AuthController.getGoogleCredential();
        if (googleCred == null) {
          throw Exception('Google re-authentication failed');
        }
        await user.reauthenticateWithCredential(googleCred);
      }
      // PHONE (no longer supported)
      else if (user.providerData.any((p) => p.providerId == 'phone')) {
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Re-authentication required'),
            content: const Text(
              'Phone re-authentication is no longer supported.\n\n'
              'Please re-authenticate using your email & password or Google sign-in, then try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        return;
      }

      // =======================
      // MARK ACCOUNT INACTIVE & HIDE POSTS
      // =======================

      // First, hide all posts by this user
      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: user.uid)
          .get();

      // Hide each post by setting active flag to false
      for (final postDoc in postsQuery.docs) {
        await postDoc.reference.update({'active': false});
      }

      // Mark account as inactive
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .update({'active': false});

      // =======================
      // FULL LOGOUT + CLEANUP
      // =======================
      await auth.signOut();
      await GoogleSignInService.instance.signOut();
      await GoogleSignInService.instance.disconnect();

      // Clear auth state for bulletproof navigation
      await AuthStateStorage().clearLoginState();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // =======================
      // NAVIGATION RESET
      // =======================
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deactivated. Log in again to reactivate.'),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deactivate account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deactivate Account'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _deactivateAccount(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Deactivate My Account'),
        ),
      ),
    );
  }
}
