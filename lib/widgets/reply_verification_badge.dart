import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReplyVerificationBadge extends StatefulWidget {
  final String userId;
  final bool Function(dynamic) isPaymentExpired;

  const ReplyVerificationBadge({
    super.key,
    required this.userId,
    required this.isPaymentExpired,
  });

  @override
  State<ReplyVerificationBadge> createState() => _ReplyVerificationBadgeState();
}

class _ReplyVerificationBadgeState extends State<ReplyVerificationBadge> {
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
    if (isLoading) {
      return const SizedBox(width: 20, height: 20); // Placeholder space
    }

    if (userData == null) {
      return const SizedBox.shrink();
    }

    final isVerified = userData!['isVerified'] ?? false;
    final verificationStatus = userData!['verificationStatus'] ?? 'pending';
    final verificationPaid = userData!['verificationPaid'] ?? false;
    final verificationPaidAt = userData!['verificationPaidAt'];

    // Only show verification badge (no follow button)
    if (isVerified == true &&
        verificationStatus == 'approved' &&
        verificationPaid == true &&
        !widget.isPaymentExpired(verificationPaidAt)) {
      return Image.asset(
        'assets/icon/verification_tick.png',
        width: 16,
        height: 16,
      );
    }

    return const SizedBox.shrink();
  }
}
