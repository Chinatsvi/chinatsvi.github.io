import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/services/firestore_service.dart';

class FollowingListFollowButton extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;

  const FollowingListFollowButton({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
  });

  @override
  State<FollowingListFollowButton> createState() =>
      _FollowingListFollowButtonState();
}

class _FollowingListFollowButtonState extends State<FollowingListFollowButton> {
  bool _isLoading = false;

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    // Get current state before toggling
    final userSnapshot = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(widget.currentUserId)
        .get();

    final userData = userSnapshot.data() as Map<String, dynamic>?;
    final following = List<String>.from(userData?['following'] ?? []);
    final isCurrentlyFollowing = following.contains(widget.targetUserId);

    setState(() => _isLoading = true);

    try {
      final firestore = FirestoreService();
      await firestore.toggleFollow(widget.currentUserId, widget.targetUserId);

      if (mounted) {
        setState(() => _isLoading = false);

        // Show appropriate message based on action
        final wasFollowing = isCurrentlyFollowing;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasFollowing ? 'Unfollowed' : 'Following!'),
            backgroundColor: wasFollowing ? Colors.grey : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.currentUserId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox(width: 80, height: 32);
        }

        if (_isLoading) {
          return const SizedBox(width: 80, height: 32);
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final following = List<String>.from(userData['following'] ?? []);
        final isFollowing = following.contains(widget.targetUserId);

        return GestureDetector(
          onTap: _toggleFollow,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isFollowing ? Colors.grey[300] : Colors.green,
              borderRadius: BorderRadius.circular(20),
              border: isFollowing ? Border.all(color: Colors.grey[400]!) : null,
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: TextStyle(
                color: isFollowing ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }
}
