import 'package:flutter/material.dart';
import 'dart:async';
import 'package:agribased/services/firestore_service.dart';
import 'package:agribased/services/follow_state_manager.dart';

class StableFollowButton extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;

  const StableFollowButton({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
  });

  @override
  State<StableFollowButton> createState() => _StableFollowButtonState();
}

class _StableFollowButtonState extends State<StableFollowButton> {
  bool _isFollowing = false;
  bool _isLoading = false;
  bool _isLoaded = false;
  StreamSubscription? _followStateSubscription;
  final FollowStateManager _stateManager = FollowStateManager();

  @override
  void initState() {
    super.initState();
    // Only load follow status if both IDs are valid
    if (widget.currentUserId.trim().isNotEmpty && widget.targetUserId.trim().isNotEmpty) {
      _loadFollowStatus();
      _listenToFollowStateChanges();
    }
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

  Future<void> _loadFollowStatus() async {
    if (_isLoaded) return; // Already loaded

    // Check cache first
    final cachedState = _stateManager.getFollowState(
      widget.currentUserId,
      widget.targetUserId,
    );
    if (cachedState != null) {
      if (mounted) {
        setState(() {
          _isFollowing = cachedState;
          _isLoaded = true;
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
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
          _isLoading = false;
          _isLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoaded = true;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    final previousState = _isFollowing;
    final newState = !previousState;
    setState(() => _isLoading = true);

    try {
      final firestore = FirestoreService();
      await firestore.toggleFollow(widget.currentUserId, widget.targetUserId);

      // Update global state
      _stateManager.updateFollowState(
        widget.currentUserId,
        widget.targetUserId,
        newState,
      );

      if (mounted) {
        setState(() {
          _isFollowing = newState;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newState ? 'Following!' : 'Unfollowed'),
            backgroundColor: newState ? Colors.green : Colors.grey,
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
    // Guard against empty IDs - don't render anything if invalid
    if (widget.currentUserId.trim().isEmpty || widget.targetUserId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Don't show anything while loading to prevent flickering
    if (_isLoading) {
      return const SizedBox(width: 60, height: 20);
    }

    if (_isFollowing) {
      return const SizedBox.shrink(); // Hide when following (for feed)
    }

    return GestureDetector(
      onTap: _toggleFollow,
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
}
