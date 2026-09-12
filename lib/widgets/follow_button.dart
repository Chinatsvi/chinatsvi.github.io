import 'package:flutter/material.dart';
import 'dart:async';
import 'package:agribased/services/firestore_service.dart';
import 'package:agribased/services/follow_state_manager.dart';

class FollowButton extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;

  const FollowButton({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isLoading = false;
  StreamSubscription? _followStateSubscription;
  final FollowStateManager _stateManager = FollowStateManager();
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _initializeFollowState();
    _listenToFollowStateChanges();
  }

  @override
  void dispose() {
    _followStateSubscription?.cancel();
    super.dispose();
  }

  void _listenToFollowStateChanges() {
    final cacheKey = _stateManager.getCacheKey(
      widget.currentUserId,
      widget.targetUserId,
    );
    _followStateSubscription = _stateManager.followStateStream.listen((
      stateChanges,
    ) {
      if (stateChanges.containsKey(cacheKey) && mounted) {
        setState(() {
          _isFollowing = stateChanges[cacheKey]!;
        });
      }
    });
  }

  Future<void> _initializeFollowState() async {
    await _stateManager.initializeFollowState(
      widget.currentUserId,
      widget.targetUserId,
    );
    if (mounted) {
      final isFollowing =
          _stateManager.getFollowState(
            widget.currentUserId,
            widget.targetUserId,
          ) ??
          false;
      setState(() {
        _isFollowing = isFollowing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 60,
        height: 20,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_isFollowing) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _toggleFollow(_isFollowing),
      child: const Text(
        'Follow',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Future<void> _toggleFollow(bool isFollowing) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirestoreService();
      await firestore.toggleFollow(widget.currentUserId, widget.targetUserId);

      // Update global state
      _stateManager.updateFollowState(
        widget.currentUserId,
        widget.targetUserId,
        !isFollowing,
      );

      if (mounted) {
        // Show message based on the action taken (opposite of current state)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing ? 'Unfollowed' : 'Following!'),
            backgroundColor: isFollowing ? Colors.grey : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
