import 'package:flutter/material.dart';
import 'package:agribased/models/user_profile.dart';
import 'package:agribased/models/marketplace/seller_badge.dart';
import 'package:agribased/services/marketplace/badge_service.dart';
import 'package:agribased/screens/profile/farmer_model.dart';
import 'package:agribased/screens/profile/farmer_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/widgets/user_info_display.dart';

class SellerProfilePage extends StatefulWidget {
  final UserProfile profile;
  final IBadgeService? badgeService;

  const SellerProfilePage({
    super.key,
    required this.profile,
    this.badgeService,
  });

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  SellerBadge? badge;
  bool loading = false;
  FarmerModel? farmerProfile;
  String? badgeLevel;

  @override
  void initState() {
    super.initState();
    _loadBadge();
    _loadFarmerProfile();
  }

  Future<void> _loadBadge() async {
    if (widget.badgeService == null) return;
    setState(() => loading = true);
    try {
      final badgeId = await widget.badgeService!.computeBadgeForSeller(
        widget.profile.id,
      );
      badgeLevel = badgeId;
    } catch (_) {}
    setState(() => loading = false);
  }

  Future<void> _loadFarmerProfile() async {
    try {
      // Load actual farmer data from Firestore to get verification info
      final farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.profile.id)
          .get();

      if (farmerDoc.exists) {
        farmerProfile = FarmerModel.fromMap(
          farmerDoc.data()!,
          widget.profile.id,
        );
      } else {
        // Fallback to creating basic model if no farmer doc exists
        farmerProfile = FarmerModel(
          id: widget.profile.id,
          name: widget.profile.userName,
          bio: widget.profile.bio ?? '',
          location: widget.profile.location ?? '',
          crops: widget.profile.crops,
          profilePic: widget.profile.profilePic ?? '',
        );
      }
    } catch (e) {
      // Fallback to creating basic model on error
      farmerProfile = FarmerModel(
        id: widget.profile.id,
        name: widget.profile.userName,
        bio: widget.profile.bio ?? '',
        location: widget.profile.location ?? '',
        crops: widget.profile.crops,
        profilePic: widget.profile.profilePic ?? '',
      );
    }
    setState(() {});
  }

  void _viewFullProfile() {
    if (farmerProfile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FarmerProfileScreen(
            userId: farmerProfile!.id,
            currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Farmer profile not found')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = farmerProfile?.name ?? widget.profile.userName;
    final bio = farmerProfile?.bio ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            UserProfileImage(
              userId: widget.profile.id,
              radius: 36,
              initialImageUrl: (farmerProfile?.profilePic ?? widget.profile.profilePic)
                          ?.isNotEmpty ==
                      true
                  ? (farmerProfile?.profilePic ?? widget.profile.profilePic!)
                  : '',
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                if (farmerProfile?.showTick == true)
                  Image.asset(
                    'assets/icon/verification_tick.png',
                    width: 18,
                    height: 18,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(bio),
            const SizedBox(height: 12),
            if (loading) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _viewFullProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              child: const Text('View Full Profile'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              child: const Text('Message Seller'),
            ),
          ],
        ),
      ),
    );
  }
}
