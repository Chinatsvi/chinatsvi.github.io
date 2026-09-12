import 'package:flutter/material.dart';
import 'package:agribased/screens/profile/farmer_model.dart';
import 'package:agribased/screens/profile/follower_following_list_screen.dart';
import 'package:agribased/screens/chat/chat_screen.dart';
import 'package:agribased/screens/marketplace/farmer_sell_list_screen.dart';
import 'package:agribased/screens/marketplace/seller_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/widgets/follow_button.dart';
import 'package:agribased/services/marketplace/marketplace_service.dart';
import 'package:agribased/widgets/safe_network_image.dart' as safe;
import 'package:agribased/widgets/full_screen_image_viewer.dart';
import 'package:agribased/widgets/user_info_display.dart';

String _getChatId(String uid1, String uid2) {
  final ids = [uid1, uid2]..sort();
  return ids.join('_');
}

class FarmerProfileHeader extends StatelessWidget {
  final FarmerModel farmer;
  final String currentUserId;
  final VoidCallback onToggleFollow;
  final MarketplaceService marketplaceService;

  const FarmerProfileHeader({
    super.key,
    required this.farmer,
    required this.currentUserId,
    required this.onToggleFollow,
    required this.marketplaceService,
  });

  void _openFollowersList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersFollowingListScreen(
          userId: farmer.id,
          currentUserId: currentUserId,
          showFollowers: true,
        ),
      ),
    );
  }

  void _openFollowingList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersFollowingListScreen(
          userId: farmer.id,
          currentUserId: currentUserId,
          showFollowers: false,
        ),
      ),
    );
  }

  void _openSells(BuildContext context) {
    // Navigate to seller dashboard (not profile list) when others view profile
    if (farmer.id == currentUserId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerDashboardScreen(sellerId: farmer.id),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FarmerSellListScreen(
            farmerId: farmer.id,
            farmerName: farmer.name,
            marketplaceService: marketplaceService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCover = farmer.coverPhoto?.isNotEmpty == true;
    final hasProfilePic = farmer.profilePic?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover Photo + Profile Pic
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: farmer.coverPhoto != null && farmer.coverPhoto!.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imageUrls: [farmer.coverPhoto!],
                              initialIndex: 0,
                              heroTag: 'profile_cover_${farmer.id}',
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'profile_cover_${farmer.id}_0',
                        child: safe.SafeNetworkImage(
                          imageUrl: farmer.coverPhoto!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        // show default cover in full screen as well
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imageUrls: [
                                'assets/images/farmer_cover.jpg'
                              ],
                              initialIndex: 0,
                              heroTag: 'profile_cover_${farmer.id}',
                            ),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/farmer_cover.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            Positioned(
              bottom: -40,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  final img = (farmer.profilePic != null && farmer.profilePic!.isNotEmpty)
                      ? farmer.profilePic!
                      : 'assets/images/default_avatar.png';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imageUrls: [img],
                        initialIndex: 0,
                        heroTag: 'profile_pic_${farmer.id}',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'profile_pic_${farmer.id}_0',
                  child: UserProfileImage(
                    userId: farmer.id,
                    radius: 40,
                    initialImageUrl: hasProfilePic && farmer.profilePic!.startsWith('http')
                        ? farmer.profilePic!
                        : '',
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        // Name + Tick
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                farmer.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              // Use cached farmer data for better performance
              if (farmer.showTick)
                Image.asset(
                  'assets/icon/verification_tick.png',
                  width: 18,
                  height: 18,
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Stats Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _openFollowersList(context),
                child: Text(
                  '${farmer.followers.length} Followers',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _openFollowingList(context),
                child: Text(
                  '${farmer.following.length} Following',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('sellerId', isEqualTo: farmer.id)
                    .where('paymentStatus', isEqualTo: 'RELEASED')
                    .snapshots(),
                builder: (context, snapshot) {
                  final sellsCount = snapshot.data?.docs.length ?? 0;
                  return GestureDetector(
                    onTap: () => _openSells(context),
                    child: Text(
                      '$sellsCount Sells',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Bio + Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((farmer.bio ?? '').isNotEmpty)
                Text(
                  farmer.bio!,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              if ((farmer.bio ?? '').isNotEmpty) const SizedBox(height: 6),

              if (currentUserId != farmer.id)
                Row(
                  children: [
                    FollowButton(
                      currentUserId: currentUserId,
                      targetUserId: farmer.id,
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (context) {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null ||
                            currentUser.uid == farmer.id) {
                          return const SizedBox.shrink();
                        }
                        return ElevatedButton.icon(
                          onPressed: () {
                            final chatId = _getChatId(
                              currentUser.uid,
                              farmer.id,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chatId: chatId,
                                  otherUserId: farmer.id,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.message, size: 18),
                          label: const Text('Message'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        // ✅ Removed "View Farmer Info" link — your green "About Farmer's Info" button handles that.
      ],
    );
  }
}
