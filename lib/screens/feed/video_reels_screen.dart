import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/post_model.dart';
import '../../../services/profile_picture_preloader.dart';
import '../../../services/video_streaming_service.dart';
import '../profile/farmer_profile_screen.dart';
import '../community/comments_bottom_sheet.dart';
import 'package:agribased/widgets/user_info_display.dart';

/// Video Reels Screen - Vertical swipe video experience
/// Users can swipe vertically to browse videos without returning to feed
class VideoReelsScreen extends StatefulWidget {
  final Post initialPost;
  final List<Post> posts;
  final String currentUserId;

  const VideoReelsScreen({
    super.key,
    required this.initialPost,
    required this.posts,
    required this.currentUserId,
  });

  @override
  State<VideoReelsScreen> createState() => _VideoReelsScreenState();
}

class _VideoReelsScreenState extends State<VideoReelsScreen> {
  late PageController _pageController;
  late List<Post> _posts;
  int _currentIndex = 0;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _isVideoInitialized = {};
  final Map<int, bool> _isLiked = {};
  final Map<int, int> _likeCounts = {};

  @override
  void initState() {
    super.initState();

    // Initialize posts list with initial post first
    _posts = [widget.initialPost];

    // Add other video posts from feed
    final otherPosts = widget.posts
        .where((p) => p.id != widget.initialPost.id && p.contentType == 'video')
        .toList();
    _posts.addAll(otherPosts);

    _pageController = PageController(initialPage: 0);
    _currentIndex = 0;

    // Initialize first video
    _initializeVideo(0);

    // Preload next video
    if (_posts.length > 1) {
      _preloadVideo(1);
    }

    // Load likes data
    _loadLikesData();

    // Fetch more video posts
    _fetchMoreVideoPosts();

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _loadLikesData() async {
    for (int i = 0; i < _posts.length; i++) {
      final post = _posts[i];
      _likeCounts[i] = post.likes.length;
      _isLiked[i] = post.likes.contains(widget.currentUserId);
    }
    if (mounted) setState(() {});
  }

  Future<void> _fetchMoreVideoPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('active', isEqualTo: true)
          .where('contentType', isEqualTo: 'video')
          .orderBy('created_at', descending: true)
          .limit(20)
          .get();

      final newPosts = snapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .where((post) => !_posts.any((p) => p.id == post.id))
          .toList();

      if (newPosts.isNotEmpty && mounted) {
        setState(() {
          _posts.addAll(newPosts);
        });

        // Preload profile pictures for new posts
        final userIds = newPosts.map((p) => p.userId).toSet().toList();
        ProfilePicturePreloader().preloadProfilePictures(userIds);
      }
    } catch (e) {
      debugPrint('Error fetching more videos: $e');
    }
  }

  void _initializeVideo(int index) {
    if (index < 0 || index >= _posts.length) return;

    final post = _posts[index];
    if (post.media.isEmpty) return;

    final videoUrl = post.media.first.url;

    _videoControllers[index] = VideoStreamingService()
        .createOptimizedController(
          videoUrl: videoUrl,
          autoPlay: true,
          loop: true,
          cacheKey: post.id,
        );

    _videoControllers[index]!
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized[index] = true;
            });
            _videoControllers[index]!.play();
          }
        })
        .catchError((error) {
          debugPrint('Video init error: $error');
        });
  }

  void _preloadVideo(int index) {
    if (index < 0 || index >= _posts.length) return;

    final post = _posts[index];
    if (post.media.isEmpty) return;

    VideoStreamingService().preloadVideo(
      post.media.first.url,
      cacheKey: post.id,
    );
  }

  void _onPageChanged(int index) {
    // Pause previous video
    if (_videoControllers.containsKey(_currentIndex)) {
      _videoControllers[_currentIndex]!.pause();
    }

    // Dispose videos that are far away
    _cleanupFarVideos(index);

    _currentIndex = index;

    // Play current video
    if (_videoControllers.containsKey(index)) {
      _videoControllers[index]!.play();
    } else {
      _initializeVideo(index);
    }

    // Preload next and previous videos
    _preloadVideo(index + 1);
    _preloadVideo(index - 1);

    // Fetch more posts if near end
    if (index >= _posts.length - 3) {
      _fetchMoreVideoPosts();
    }

    setState(() {});
  }

  void _cleanupFarVideos(int currentIndex) {
    final keysToRemove = <int>[];

    _videoControllers.forEach((index, controller) {
      if ((index - currentIndex).abs() > 2) {
        keysToRemove.add(index);
      }
    });

    for (final index in keysToRemove) {
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
      _isVideoInitialized.remove(index);
    }
  }

  void _toggleLike(int index) async {
    final post = _posts[index];
    final isCurrentlyLiked = _isLiked[index] ?? false;

    setState(() {
      _isLiked[index] = !isCurrentlyLiked;
      _likeCounts[index] =
          (_likeCounts[index] ?? 0) + (isCurrentlyLiked ? -1 : 1);
    });

    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      if (isCurrentlyLiked) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([widget.currentUserId]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([widget.currentUserId]),
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked[index] = isCurrentlyLiked;
        _likeCounts[index] =
            (_likeCounts[index] ?? 0) + (isCurrentlyLiked ? 1 : -1);
      });
    }
  }

  void _showComments(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentsBottomSheet(post: post, currentUserId: widget.currentUserId),
    );
  }

  void _showShareOptions(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text(
                'Share to Feed',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement share
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text(
                'Copy Link',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Copy link
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.white),
              title: const Text(
                'Report',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Report
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildVideoPage(index);
        },
      ),
    );
  }

  Widget _buildVideoPage(int index) {
    final post = _posts[index];
    final controller = _videoControllers[index];
    final isInitialized = _isVideoInitialized[index] ?? false;
    final isLiked = _isLiked[index] ?? false;
    final likeCount = _likeCounts[index] ?? 0;

    // Get profile data
    final preloader = ProfilePicturePreloader();
    final profileData = preloader.getCachedProfile(post.userId);
    final authorName = profileData?.userName ?? post.authorName;
    final authorAvatar = profileData?.profileUrl ?? post.authorAvatar;
    final isVerified = profileData?.isVerified ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player
        if (controller != null && isInitialized)
          GestureDetector(
            onTap: () {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
              setState(() {});
            },
            child: VideoPlayer(controller),
          )
        else
          Container(
            color: Colors.grey.shade900,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        // Gradient overlay for UI visibility
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Top bar - Back button and options
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        // Right side - Action buttons
        Positioned(
          right: 8,
          bottom: 100,
          child: Column(
            children: [
              // Like button
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.white,
                label: _formatCount(likeCount),
                onTap: () => _toggleLike(index),
              ),
              const SizedBox(height: 20),

              // Comment button
              _buildActionButton(
                icon: Icons.comment,
                color: Colors.white,
                label: _formatCount(post.comments.length),
                onTap: () => _showComments(post),
              ),
              const SizedBox(height: 20),

              // Share button
              _buildActionButton(
                icon: Icons.share,
                color: Colors.white,
                label: 'Share',
                onTap: () => _showShareOptions(post),
              ),
              const SizedBox(height: 20),

              // More options
              _buildActionButton(
                icon: Icons.more_vert,
                color: Colors.white,
                label: '',
                onTap: () => _showMoreOptions(post),
              ),
            ],
          ),
        ),

        // Bottom left - User info and caption
        Positioned(
          left: 16,
          right: 80,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info row
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarmerProfileScreen(
                        userId: post.userId,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    // Avatar
                    UserProfileImage(
                      userId: post.userId,
                      radius: 20,
                      initialImageUrl: authorAvatar,
                    ),
                    const SizedBox(width: 12),

                    // Name and verified
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  authorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '@${authorName.toLowerCase().replaceAll(' ', '')}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Follow button
                    if (post.userId != widget.currentUserId)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Follow',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Caption
              if (post.content.isNotEmpty)
                Text(
                  post.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 8),

              // Music/location tag
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Original Sound - ${post.locationTag ?? 'AgriBased'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Play/Pause indicator when paused
        if (controller != null && isInitialized && !controller.value.isPlaying)
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMoreOptions(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.userId == widget.currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Video',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteVideo(post);
                },
              ),
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.white),
              title: const Text(
                'Not Interested',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.white),
              title: const Text(
                'Report',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteVideo(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Delete Video?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(post.id)
                    .delete();

                if (mounted) {
                  setState(() {
                    _posts.removeWhere((p) => p.id == post.id);
                  });
                }
              } catch (e) {
                debugPrint('Error deleting video: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
