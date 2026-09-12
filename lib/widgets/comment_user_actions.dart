import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/widgets/stable_follow_button.dart';

class CommentUserActions extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final bool Function(dynamic) isPaymentExpired;

  const CommentUserActions({
    super.key,
    required this.userId,
    required this.currentUserId,
    required this.isPaymentExpired,
  });

  @override
  State<CommentUserActions> createState() => _CommentUserActionsState();
}

class _CommentUserActionsState extends State<CommentUserActions> {
  Map<String, dynamic>? userData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (userData != null) return; // Already loaded

    setState(() => isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.userId)
          .get();

      if (mounted && doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show actions for own comments
    if (widget.userId == widget.currentUserId) {
      return const SizedBox.shrink();
    }

    if (isLoading) {
      return const SizedBox(width: 60, height: 32); // Placeholder space
    }

    if (userData == null) {
      return const SizedBox.shrink();
    }

    final isVerified = userData!['isVerified'] ?? false;
    final verificationStatus = userData!['verificationStatus'] ?? 'pending';
    final verificationPaid = userData!['verificationPaid'] ?? false;
    final verificationPaidAt = userData!['verificationPaidAt'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Verification badge
        if (isVerified == true &&
            verificationStatus == 'approved' &&
            verificationPaid == true &&
              !widget.isPaymentExpired(verificationPaidAt))
          Image.asset(
            'assets/icon/verification_tick.png',
            width: 20,
            height: 20,
          ),

        // Follow button
        const SizedBox(width: 8),
        StableFollowButton(
          currentUserId: widget.currentUserId,
          targetUserId: widget.userId,
        ),
      ],
    );
  }
}
