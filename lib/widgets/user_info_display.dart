import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agribased/services/optimized_user_service.dart';

/// A safe network image widget that handles loading errors gracefully
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the URL is invalid or a placeholder
    if (imageUrl.isEmpty ||
        imageUrl.contains('example.com') ||
        imageUrl.contains('placeholder_') ||
        imageUrl.contains('https://example.com/placeholder_0.png')) {
      return errorWidget ?? _buildDefaultErrorWidget();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) {
        debugPrint('NetworkImage error: Failed to load $imageUrl');
        return errorWidget ?? _buildDefaultErrorWidget();
      },
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    );
  }
}

class UserNameDisplay extends StatefulWidget {
  final String userId;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? initialName; // Add initial name

  const UserNameDisplay({
    super.key,
    required this.userId,
    this.style,
    this.maxLines,
    this.overflow,
    this.initialName, // Allow pre-setting the name
  });

  @override
  State<UserNameDisplay> createState() => _UserNameDisplayState();
}

class _UserNameDisplayState extends State<UserNameDisplay> {
  String? displayName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();
  }

  @override
  void didUpdateWidget(covariant UserNameDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      // User id changed (list reuse) — reset and fetch new user
      setState(() {
        displayName = widget.initialName;
        isLoading = true;
      });
      _setupRealtimeUpdates();
    }
  }

  void _setupRealtimeUpdates() {
    // Guard against empty userId
    if (widget.userId.trim().isEmpty) {
      setState(() {
        displayName = widget.initialName ?? 'Farmer';
        isLoading = false;
      });
      return;
    }

    // Use initial name for instant display
    if (widget.initialName != null) {
      setState(() {
        displayName = widget.initialName!;
        isLoading = false;
      });
    }

    // Use optimized service to get cached or fetch-once (cache-aware)
    OptimizedUserService.getUser(widget.userId).then((user) {
      if (!mounted) return;
      if (user != null && user.name.isNotEmpty && user.name != displayName) {
        setState(() {
          displayName = user.name;
          isLoading = false;
        });
      } else if (displayName == null) {
        setState(() {
          isLoading = false;
        });
      }
    }).catchError((e) {
      debugPrint('Error loading user name via OptimizedUserService: $e');
      if (mounted) setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && displayName == null) {
      return Text(
        '...',
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    return Text(
      displayName ?? 'Unknown',
      key: ValueKey('user-name-${widget.userId}-${displayName ?? ''}'),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class UserProfileImage extends StatefulWidget {
  final String userId;
  final double radius;
  final VoidCallback? onTap;
  final String? initialImageUrl; // Add initial image URL

  const UserProfileImage({
    super.key,
    required this.userId,
    this.radius = 18,
    this.onTap,
    this.initialImageUrl, // Allow pre-setting the image
  });

  @override
  State<UserProfileImage> createState() => _UserProfileImageState();
}

class _UserProfileImageState extends State<UserProfileImage> {
  String? profileImageUrl;
  bool isLoading = true;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _setupImageUpdates();
  }

  void _setupImageUpdates() {
    final loadGeneration = ++_loadGeneration;

    // Guard against empty userId
    if (widget.userId.trim().isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Use initial image for instant display
    if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      setState(() {
        profileImageUrl = widget.initialImageUrl!;
        isLoading = false;
      });
    }

    // Fetch cached/remote user once via optimized service
    OptimizedUserService.getUser(widget.userId).then((user) {
      if (!mounted || loadGeneration != _loadGeneration) return;
      if (user != null && user.profilePic != profileImageUrl) {
        setState(() {
          // Post/comment snapshots are only an offline fallback. The farmer
          // profile returned by OptimizedUserService is authoritative.
          profileImageUrl = user.profilePic;
          isLoading = false;
        });
      } else if (profileImageUrl == null) {
        setState(() {
          isLoading = false;
        });
      }
    }).catchError((e) {
      if (!mounted || loadGeneration != _loadGeneration) return;
      debugPrint('Error loading profile via OptimizedUserService: $e');
      setState(() => isLoading = false);
    });
  }

  @override
  void didUpdateWidget(covariant UserProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.initialImageUrl != widget.initialImageUrl) {
      // Reset image and reload when userId or fallback avatar changes.
      setState(() {
        profileImageUrl = widget.initialImageUrl;
        isLoading = true;
      });
      _setupImageUpdates();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && profileImageUrl == null) {
      // Show placeholder instead of spinner to avoid flickering
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: widget.radius * 0.8,
          color: Colors.grey[600],
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipOval(
        child: SizedBox(
          key: ValueKey('user-avatar-${widget.userId}-${profileImageUrl ?? ""}'),
          width: widget.radius * 2,
          height: widget.radius * 2,
          child: profileImageUrl == null || profileImageUrl!.isEmpty
              ? _buildFallbackAvatar()
              : CachedNetworkImage(
                  imageUrl: profileImageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildFallbackAvatar(),
                  errorWidget: (context, url, error) {
                    debugPrint('UserProfileImage: failed to load $url: $error');
                    return _buildFallbackAvatar();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: widget.radius * 0.8,
        color: Colors.grey[600],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
