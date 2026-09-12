import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../controllers/auth_controller.dart';
import '../../services/auth_state_storage.dart';
import '../../services/user_purge_service.dart';
import 'package:agribased/app/routes/app_routes.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController smsController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    passwordController.dispose();
    smsController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final googleSignIn = GoogleSignIn.instance;

    if (user == null) return;

    // =======================
    // CONFIRM DELETE
    // =======================
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to permanently delete your account? This action will completely purge all your data and cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      // =======================
      // REAUTHENTICATION
      // =======================
      if (user.providerData.any((p) => p.providerId == "password")) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Re-authenticate"),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Enter your password",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

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
      else if (user.providerData.any((p) => p.providerId == "google.com")) {
        final googleCred = await AuthController.getGoogleCredential();
        if (googleCred == null) {
          throw Exception("Google re-authentication failed");
        }
        await user.reauthenticateWithCredential(googleCred);
      }
      // PHONE (no longer supported)
      else if (user.providerData.any((p) => p.providerId == "phone")) {
        if (!mounted) return;
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Re-authentication required"),
            content: const Text(
              'Phone re-authentication is no longer supported.\n\n'
              'Please re-authenticate using your email & password or Google sign-in, then try again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("OK"),
              ),
            ],
          ),
        );

        return;
      }

      // =======================
      // DELETE ALL DATA (PURGE EVERYTHING)
      // =======================
      await UserPurgeService().purgeUserData(user.uid);
      await user.delete();

      // =======================
      // FULL SIGN-OUT & CLEANUP
      // =======================
      await auth.signOut();
      await googleSignIn.signOut();
      await googleSignIn.disconnect();

      // Clear auth state for bulletproof navigation
      await AuthStateStorage().clearLoginState();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // =======================
      // NAVIGATION RESET
      // =======================
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account and all data deleted successfully")),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signup,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete account: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete Account"),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _deleteAccount,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Delete My Account"),
              ),
      ),
    );
  }
}
