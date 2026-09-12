import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../profile/farmer_profile_edit_screen.dart';
import '../auth/logout_screen.dart';
import '../auth/delete_account_screen.dart';
import '../auth/deactivate_account_screen.dart';
import '../badge/verification_intro_screen.dart';
import '../badge/admin_verification_screen.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  static final Uri _helpFaqUri = Uri.parse(
    'https://chinatsvi.github.io/farmer-community-Help-FAQ/',
  );

  Future<void> _openHelpFaq(BuildContext context) async {
    if (await canLaunchUrl(_helpFaqUri)) {
      await launchUrl(_helpFaqUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Help & FAQ')),
      );
    }
  }

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .get();

    return doc.exists && doc.data()?['role'] == 'admin';
  }

  /// ✅ REAL VERIFICATION LOGIC (MATCHES YOUR FIRESTORE)
  Future<bool> _showVerificationButton() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .get();

    if (!doc.exists) return false;

    final data = doc.data()!;

    final bool isVerified = data['isVerified'] ?? false;
    final String status = data['verificationStatus'] ?? '';
    final bool paid = data['verificationPaid'] ?? false;

    return !isVerified && status != 'approved' && paid != true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Settings'),
        backgroundColor: Colors.green[700],
      ),
      body: FutureBuilder<Map<String, bool>>(
        future: () async {
          return {
            'isAdmin': await _isAdmin(),
            'showVerify': await _showVerificationButton(),
          };
        }(),
        builder: (context, snapshot) {
          final isAdmin = snapshot.data?['isAdmin'] ?? false;
          final showVerify = snapshot.data?['showVerify'] ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section('👤 Profile'),
              _item(
                context,
                Icons.edit,
                'Edit Profile',
                'Update your personal details',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FarmerProfileEditScreen(),
                  ),
                ),
              ),

              /// ✅ VERIFICATION INTRO (LOGIC-BASED)
              if (showVerify)
                _item(
                  context,
                  Icons.verified_outlined,
                  'Get Verified',
                  'Apply for a green verification badge',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VerificationIntroScreen(),
                    ),
                  ),
                ),

              if (isAdmin)
                _item(
                  context,
                  Icons.admin_panel_settings,
                  'Admin Verification',
                  'Approve or reject farmers',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminVerificationScreen(),
                    ),
                  ),
                ),

              _section('❓ Help'),
              _item(
                context,
                Icons.help_outline,
                'Help & FAQ',
                'Find quick answers about using Farmer Community',
                () => _openHelpFaq(context),
              ),

              _section('🔐 Privacy'),
              _item(
                context,
                Icons.person_off,
                'Deactivate Account',
                'Temporarily disable your account',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeactivateAccountScreen(),
                  ),
                ),
              ),
              _item(
                context,
                Icons.delete_forever,
                'Delete Account',
                'Permanently remove your account',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                ),
              ),

              _section('🔓 Security'),
              _item(
                context,
                Icons.logout,
                'Log Out',
                'Sign out of your account',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogoutScreen()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    ),
  );

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[700]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
