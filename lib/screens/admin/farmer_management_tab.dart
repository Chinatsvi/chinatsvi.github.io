import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/widgets/safe_network_image.dart';
import '../profile/farmer_model.dart';
import '../profile/farmer_profile_screen.dart';
import '../../services/user_purge_service.dart';

class FarmerManagementTab extends StatefulWidget {
  const FarmerManagementTab({super.key});

  @override
  State<FarmerManagementTab> createState() => _FarmerManagementTabState();
}

class _FarmerManagementTabState extends State<FarmerManagementTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'verified', 'unverified', 'deactivated', 'following_admin', 'not_following_admin'
  String _sortBy = 'newest'; // 'newest', 'oldest', 'name_asc', 'name_desc', 'most_followers', 'most_posts'
  bool _isBulkSyncing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _currentAdminId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ===========================================================================
  // BULK ACTION: MAKE ALL FARMERS FOLLOW ADMIN
  // ===========================================================================
  Future<void> _makeAllFarmersFollowAdmin() async {
    final adminId = _currentAdminId;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (adminId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Admin account not found. Please log in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync, color: Colors.green),
            SizedBox(width: 8),
            Text('Sync All Farmers as Followers'),
          ],
        ),
        content: const Text(
          'This will update all registered farmer accounts so they follow your admin account.\n\n'
          'After syncing, you can simply view your admin profile followers count to know the exact total number of users in the app.\n\n'
          'Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Sync Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isBulkSyncing = true);

    // Show Progress Dialog
    final ValueNotifier<String> progressText = ValueNotifier('Fetching all farmers...');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: progressText,
                  builder: (ctx, text, child) => Text(text, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final farmersSnapshot = await FirebaseFirestore.instance.collection('farmers').get();
      final allFarmerDocs = farmersSnapshot.docs.where((doc) => doc.id != adminId).toList();
      final totalFarmers = allFarmerDocs.length;

      if (totalFarmers == 0) {
        if (mounted) navigator.pop(); // close progress dialog
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No other farmer accounts found to sync.'),
            backgroundColor: Colors.orange,
          ),
        );
        if (mounted) setState(() => _isBulkSyncing = false);
        return;
      }

      final List<String> allFarmerIds = [];
      int processedCount = 0;

      // Process in batches of 200 to stay well within Firestore limits (max 500)
      const int batchSize = 200;
      for (int i = 0; i < allFarmerDocs.length; i += batchSize) {
        final end = (i + batchSize < allFarmerDocs.length) ? i + batchSize : allFarmerDocs.length;
        final chunk = allFarmerDocs.sublist(i, end);

        final batch = FirebaseFirestore.instance.batch();

        for (final doc in chunk) {
          final farmerId = doc.id;
          allFarmerIds.add(farmerId);

          // 1. Update farmer's following array
          final farmerRef = FirebaseFirestore.instance.collection('farmers').doc(farmerId);
          batch.update(farmerRef, {
            'following': FieldValue.arrayUnion([adminId]),
            'updated_at': FieldValue.serverTimestamp(),
          });

          // 2. Set subcollection records for complete compatibility
          final farmerFollowingSubRef = farmerRef.collection('following').doc(adminId);
          batch.set(farmerFollowingSubRef, {
            'followedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          final adminFollowerSubRef = FirebaseFirestore.instance
              .collection('farmers')
              .doc(adminId)
              .collection('followers')
              .doc(farmerId);
          batch.set(adminFollowerSubRef, {
            'followedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Also update users / followers / following root collections if used
          final rootFollowerRef = FirebaseFirestore.instance
              .collection('followers')
              .doc(adminId)
              .collection('followers')
              .doc(farmerId);
          batch.set(rootFollowerRef, {
            'followerId': farmerId,
            'followingId': adminId,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          final rootFollowingRef = FirebaseFirestore.instance
              .collection('following')
              .doc(farmerId)
              .collection('following')
              .doc(adminId);
          batch.set(rootFollowingRef, {
            'followerId': farmerId,
            'followingId': adminId,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        await batch.commit();
        processedCount += chunk.length;
        progressText.value = 'Updating farmers ($processedCount / $totalFarmers)...';
      }

      // 3. Update Admin's own profile followers list and count
      progressText.value = 'Updating admin profile followers...';
      final adminDocRef = FirebaseFirestore.instance.collection('farmers').doc(adminId);
      await adminDocRef.set({
        'followers': FieldValue.arrayUnion(allFarmerIds),
        'followerCount': allFarmerIds.length,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also ensure root users collection has it if present
      final adminUserRef = FirebaseFirestore.instance.collection('users').doc(adminId);
      final adminUserDoc = await adminUserRef.get();
      if (adminUserDoc.exists) {
        await adminUserRef.set({
          'followerCount': allFarmerIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        navigator.pop(); // dismiss progress dialog
        messenger.showSnackBar(
          SnackBar(
            content: Text('✅ Successfully synced! $totalFarmers farmers now follow your admin account.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // dismiss progress dialog
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBulkSyncing = false);
    }
  }

  // ===========================================================================
  // INDIVIDUAL ADMIN ACTIONS
  // ===========================================================================

  /// Delete / Remove Account Completely (Zero Ghost Data)
  Future<void> _deleteFarmerAccount(String farmerId, String farmerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Remove Farmer Account'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$farmerName" (ID: $farmerId)?\n\n'
          'This will execute a complete data purge across Firestore and Storage, removing their profile, posts, comments, likes, follower links, chats, and marketplace listings to ensure ZERO ghost data remains in the app.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Show Progress Dialog during purge
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(
                child: Text('Purging all user data (zero ghost data)...', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Execute complete data purge across all collections and storage
      await UserPurgeService().purgeUserData(farmerId);

      if (mounted) {
        navigator.pop(); // close progress dialog
        messenger.showSnackBar(
          SnackBar(
            content: Text('Farmer "$farmerName" and all associated data completely deleted ✅'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // close progress dialog
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error deleting farmer account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Toggle Deactivate / Reactivate Account
  Future<void> _toggleAccountStatus(String farmerId, String farmerName, bool currentIsDeactivated) async {
    final newDeactivated = !currentIsDeactivated;
    final actionName = newDeactivated ? 'Deactivate' : 'Reactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName Account'),
        content: Text(
          newDeactivated
              ? 'Are you sure you want to deactivate "$farmerName"? Their account will be suspended and their posts hidden.'
              : 'Reactivate "$farmerName"? Their account and posts will be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newDeactivated ? Colors.orange : Colors.green,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionName, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection('farmers').doc(farmerId).update({
        'isDeactivated': newDeactivated,
        'active': !newDeactivated,
        'deactivatedAt': newDeactivated ? FieldValue.serverTimestamp() : null,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Also update their posts active state
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: farmerId)
          .get();

      for (final postDoc in postsSnapshot.docs) {
        await postDoc.reference.update({'active': !newDeactivated});
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Account "$farmerName" ${newDeactivated ? "deactivated" : "reactivated"} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Toggle Green Verification Badge
  Future<void> _toggleVerification(String farmerId, String farmerName, bool currentIsVerified) async {
    final newVerification = !currentIsVerified;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance.collection('farmers').doc(farmerId).update({
        'isVerified': newVerification,
        'verificationStatus': newVerification ? 'approved' : 'none',
        'verificationPaid': newVerification,
        'verificationPaidAt': newVerification ? FieldValue.serverTimestamp() : null,
        'updated_at': FieldValue.serverTimestamp(),
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            newVerification
                ? 'Granted green tick verification to $farmerName ✅'
                : 'Revoked verification from $farmerName',
          ),
          backgroundColor: newVerification ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error updating verification: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Send In-App Admin Notification to Farmer
  Future<void> _sendAdminMessage(String farmerId, String farmerName) async {
    final textController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Send Admin Message to $farmerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter your official message to this farmer...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send, color: Colors.white, size: 18),
            label: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != true || textController.text.trim().isEmpty) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(farmerId)
          .collection('items')
          .add({
        'userId': farmerId,
        'title': 'Message from AgriBase Admin Team',
        'body': textController.text.trim(),
        'type': 'admin_message',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'fromAdmin': true,
        'adminId': _currentAdminId,
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Admin message sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Make a Single Farmer Follow Admin
  Future<void> _makeFarmerFollowAdmin(String farmerId, String farmerName) async {
    final adminId = _currentAdminId;
    if (adminId.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final batch = FirebaseFirestore.instance.batch();

      final farmerRef = FirebaseFirestore.instance.collection('farmers').doc(farmerId);
      batch.update(farmerRef, {
        'following': FieldValue.arrayUnion([adminId]),
      });

      final adminRef = FirebaseFirestore.instance.collection('farmers').doc(adminId);
      batch.update(adminRef, {
        'followers': FieldValue.arrayUnion([farmerId]),
      });

      await batch.commit();

      messenger.showSnackBar(
        SnackBar(
          content: Text('$farmerName is now following your admin account!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ===========================================================================
  // FILTER & SORT LOGIC
  // ===========================================================================
  List<FarmerModel> _filterAndSortFarmers(List<FarmerModel> rawFarmers, Map<String, int> postCounts) {
    final adminId = _currentAdminId;

    return rawFarmers.where((farmer) {
      // 1. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final nameMatches = farmer.name.toLowerCase().contains(_searchQuery);
        final emailMatches = (farmer.email ?? '').toLowerCase().contains(_searchQuery);
        final phoneMatches = (farmer.phone ?? '').toLowerCase().contains(_searchQuery);
        final locationMatches = (farmer.location ?? '').toLowerCase().contains(_searchQuery);
        final farmTypeMatches = (farmer.farmType ?? '').toLowerCase().contains(_searchQuery);
        final idMatches = farmer.id.toLowerCase().contains(_searchQuery);

        if (!nameMatches && !emailMatches && !phoneMatches && !locationMatches && !farmTypeMatches && !idMatches) {
          return false;
        }
      }

      // 2. Tab / Category Filter
      final isVerified = farmer.isVerified || farmer.verificationStatus == 'approved';
      final followsAdmin = farmer.following.contains(adminId);

      switch (_filterType) {
        case 'verified':
          if (!isVerified) return false;
          break;
        case 'unverified':
          if (isVerified) return false;
          break;
        case 'deactivated':
          // Check if deactivated
          if (farmer.status != 'deactivated' && farmer.bio?.contains('[DEACTIVATED]') != true) {
            // Check raw status if needed, handled in UI
          }
          break;
        case 'following_admin':
          if (!followsAdmin) return false;
          break;
        case 'not_following_admin':
          if (followsAdmin || farmer.id == adminId) return false;
          break;
        case 'all':
        default:
          break;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        switch (_sortBy) {
          case 'name_asc':
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case 'name_desc':
            return b.name.toLowerCase().compareTo(a.name.toLowerCase());
          case 'most_followers':
            return b.followers.length.compareTo(a.followers.length);
          case 'most_posts':
            final aPosts = postCounts[a.id] ?? a.posts;
            final bPosts = postCounts[b.id] ?? b.posts;
            return bPosts.compareTo(aPosts);
          case 'oldest':
            final aDate = a.createdAt ?? DateTime(2020);
            final bDate = b.createdAt ?? DateTime(2020);
            return aDate.compareTo(bDate);
          case 'newest':
          default:
            final aDate = a.createdAt ?? DateTime(2020);
            final bDate = b.createdAt ?? DateTime(2020);
            return bDate.compareTo(aDate);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('farmers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading farmers: ${snapshot.error}'));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').snapshots(),
          builder: (context, postsSnapshot) {
            final docs = snapshot.data?.docs ?? [];
            final farmerData = docs.map((d) => d.data() as Map<String, dynamic>).toList();
            final activeFarmerCount = farmerData.where((data) {
              return data['active'] != false && data['isDeactivated'] != true;
            }).length;
            final allFarmers = docs.map((d) => FarmerModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
            final adminFarmer = allFarmers.cast<FarmerModel?>().firstWhere(
                  (f) => f?.id == _currentAdminId,
                  orElse: () => null,
                );

            // Compute real post counts per farmer/author
            final Map<String, int> postCounts = {};
            final postDocs = postsSnapshot.data?.docs ?? [];
            for (final p in postDocs) {
              final data = p.data() as Map<String, dynamic>?;
              if (data == null) continue;
              final authorId = (data['authorId'] ?? data['userId'] ?? data['author_id'] ?? data['uid'])?.toString();
              if (authorId != null && authorId.isNotEmpty) {
                postCounts[authorId] = (postCounts[authorId] ?? 0) + 1;
              }
            }

            final filteredFarmers = _filterAndSortFarmers(allFarmers, postCounts);

            return Column(
              children: [
                // =================================================================
                // ADMIN FOLLOWER SYNC & STATS BANNER
                // =================================================================
                _buildAdminFollowerBanner(activeFarmerCount, adminFarmer),

                // =================================================================
                // SEARCH & FILTER CONTROLS
                // =================================================================
                _buildSearchAndFilterControls(allFarmers.length, filteredFarmers.length),

                // =================================================================
                // FARMER LIST
                // =================================================================
                Expanded(
                  child: filteredFarmers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No farmers match "$_searchQuery"'
                                    : 'No farmer accounts found',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: filteredFarmers.length,
                          itemBuilder: (context, index) {
                            final farmer = filteredFarmers[index];
                            final rawDoc = docs.firstWhere((d) => d.id == farmer.id);
                            final rawData = rawDoc.data() as Map<String, dynamic>;
                            final isDeactivated = rawData['isDeactivated'] == true || rawData['active'] == false;
                            final followsAdmin = farmer.following.contains(_currentAdminId);
                            final isAdmin = farmer.id == _currentAdminId;
                            final postCount = postCounts[farmer.id] ?? farmer.posts;

                            return _buildFarmerCard(farmer, rawData, isDeactivated, followsAdmin, isAdmin, postCount);
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // WIDGET HELPERS
  // ===========================================================================

  Widget _buildAdminFollowerBanner(int totalFarmers, FarmerModel? adminFarmer) {
    final adminFollowersCount = adminFarmer?.followers.length ?? 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Admin User Monitor & Follower Sync',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalFarmers Users Total',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    children: [
                      const TextSpan(text: 'Admin Followers: '),
                      TextSpan(
                        text: '$adminFollowersCount',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const TextSpan(text: '  •  Track total app users directly via profile followers.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade800,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isBulkSyncing ? null : _makeAllFarmersFollowAdmin,
              icon: _isBulkSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1, size: 20),
              label: Text(
                _isBulkSyncing ? 'Syncing Followers...' : 'Make All Farmers Follow Admin',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterControls(int totalCount, int filteredCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          // Search Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, phone, location...',
                    prefixIcon: const Icon(Icons.search, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort Menu
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.sort, color: Colors.black87),
                ),
                tooltip: 'Sort Farmers',
                initialValue: _sortBy,
                onSelected: (val) => setState(() => _sortBy = val),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'newest', child: Text('Newest First')),
                  PopupMenuItem(value: 'oldest', child: Text('Oldest First')),
                  PopupMenuItem(value: 'name_asc', child: Text('Name (A → Z)')),
                  PopupMenuItem(value: 'name_desc', child: Text('Name (Z → A)')),
                  PopupMenuItem(value: 'most_followers', child: Text('Most Followers')),
                  PopupMenuItem(value: 'most_posts', child: Text('Most Posts')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All ($totalCount)'),
                const SizedBox(width: 6),
                _buildFilterChip('verified', 'Verified ✅'),
                const SizedBox(width: 6),
                _buildFilterChip('unverified', 'Unverified'),
                const SizedBox(width: 6),
                _buildFilterChip('following_admin', 'Follows Admin'),
                const SizedBox(width: 6),
                _buildFilterChip('not_following_admin', 'Not Following Admin'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing $filteredCount of $totalCount farmers',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (_searchQuery.isNotEmpty || _filterType != 'all')
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchController.clear();
                      _filterType = 'all';
                    });
                  },
                  child: const Text(
                    'Reset Filters',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.green[700],
      backgroundColor: Colors.grey.shade200,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onSelected: (_) => setState(() => _filterType = type),
    );
  }

  Widget _buildFarmerCard(
    FarmerModel farmer,
    Map<String, dynamic> rawData,
    bool isDeactivated,
    bool followsAdmin,
    bool isAdmin,
    int postCount,
  ) {
    final hasProfilePic = farmer.profilePic != null && farmer.profilePic!.trim().isNotEmpty;
    final isVerified = farmer.isVerified || farmer.verificationStatus == 'approved';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDeactivated
              ? Colors.red.shade300
              : isAdmin
                  ? Colors.green.shade400
                  : Colors.grey.shade200,
          width: isDeactivated || isAdmin ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name, Verification, Action Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FarmerProfileScreen(
                          userId: farmer.id,
                          currentUserId: _currentAdminId,
                          initialFarmer: farmer,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: hasProfilePic && farmer.profilePic!.startsWith('http')
                        ? SafeNetworkImage(
                            imageUrl: farmer.profilePic!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              width: 50,
                              height: 50,
                              color: Colors.green.shade100,
                              child: const Icon(Icons.person, color: Colors.green),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.green.shade100,
                            child: const Icon(Icons.person, color: Colors.green),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              farmer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            Image.asset(
                              'assets/icon/verification_tick.png',
                              width: 16,
                              height: 16,
                              errorBuilder: (ctx, err, stack) =>
                                  const Icon(Icons.verified, color: Colors.green, size: 16),
                            ),
                          ],
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADMIN (YOU)',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${farmer.id}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      if (farmer.email != null && farmer.email!.isNotEmpty)
                        Text(
                          farmer.email!,
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // Action Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    if (action == 'view_profile') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FarmerProfileScreen(
                            userId: farmer.id,
                            currentUserId: _currentAdminId,
                            initialFarmer: farmer,
                          ),
                        ),
                      );
                    } else if (action == 'toggle_verify') {
                      _toggleVerification(farmer.id, farmer.name, isVerified);
                    } else if (action == 'toggle_status') {
                      _toggleAccountStatus(farmer.id, farmer.name, isDeactivated);
                    } else if (action == 'send_message') {
                      _sendAdminMessage(farmer.id, farmer.name);
                    } else if (action == 'follow_admin') {
                      _makeFarmerFollowAdmin(farmer.id, farmer.name);
                    } else if (action == 'delete') {
                      _deleteFarmerAccount(farmer.id, farmer.name);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'view_profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 18),
                          SizedBox(width: 8),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_verify',
                      child: Row(
                        children: [
                          Icon(
                            isVerified ? Icons.cancel_outlined : Icons.verified,
                            color: isVerified ? Colors.orange : Colors.green,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(isVerified ? 'Revoke Verification' : 'Grant Verification'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'send_message',
                      child: Row(
                        children: [
                          Icon(Icons.message_outlined, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text('Send Admin Message'),
                        ],
                      ),
                    ),
                    if (!followsAdmin && !isAdmin)
                      const PopupMenuItem(
                        value: 'follow_admin',
                        child: Row(
                          children: [
                            Icon(Icons.person_add_alt_1, color: Colors.teal, size: 18),
                            SizedBox(width: 8),
                            Text('Make Follow Admin'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            isDeactivated ? Icons.check_circle_outline : Icons.block,
                            color: isDeactivated ? Colors.green : Colors.orange,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(isDeactivated ? 'Reactivate Account' : 'Deactivate / Suspend'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Middle: Contact details & badges
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (farmer.phone != null && farmer.phone!.isNotEmpty)
                  _buildIconText(Icons.phone, farmer.phone!),
                if (farmer.location != null && farmer.location!.isNotEmpty)
                  _buildIconText(Icons.location_on, farmer.location!),
                if (farmer.farmType != null && farmer.farmType!.isNotEmpty)
                  _buildIconText(Icons.agriculture, farmer.farmType!),
                if (isDeactivated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: const Text(
                      'SUSPENDED / DEACTIVATED',
                      style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (!isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: followsAdmin ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: followsAdmin ? Colors.green.shade300 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          followsAdmin ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 11,
                          color: followsAdmin ? Colors.green.shade700 : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          followsAdmin ? 'Follows Admin' : 'Does not follow Admin',
                          style: TextStyle(
                            color: followsAdmin ? Colors.green.shade800 : Colors.grey.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),

            // Bottom: Stats & Quick Action Buttons
            Row(
              children: [
                Text(
                  '${farmer.followers.length} Followers  •  ${farmer.following.length} Following  •  $postCount Posts',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                // Quick View Profile Button
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FarmerProfileScreen(
                          userId: farmer.id,
                          currentUserId: _currentAdminId,
                          initialFarmer: farmer,
                        ),
                      ),
                    );
                  },
                  child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(color: Colors.grey[700], fontSize: 11),
        ),
      ],
    );
  }
}
