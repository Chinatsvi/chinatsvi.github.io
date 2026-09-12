import 'package:flutter/material.dart';
import 'dart:async';
import 'package:agribased/services/firestore_service.dart';
import 'package:agribased/services/follow_state_manager.dart';

class FollowButtonWithUnfollow extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;

  const FollowButtonWithUnfollow({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
  });

  @override
  State<FollowButtonWithUnfollow> createState() =>
      _FollowButtonWithUnfollowState();
}

class _FollowButtonWithUnfollowState extends State<FollowButtonWithUnfollow> {
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
        width: 80,
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return GestureDetector(
      onTap: () => _toggleFollow(_isFollowing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isFollowing ? Colors.grey[300] : Colors.green,
          borderRadius: BorderRadius.circular(20),
          border: _isFollowing ? Border.all(color: Colors.grey[400]!) : null,
        ),
        child: Text(
          _isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: _isFollowing ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
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
