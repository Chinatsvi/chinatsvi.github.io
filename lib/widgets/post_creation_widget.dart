import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:agribased/controllers/feed_controller.dart';
import 'package:agribased/controllers/auth_controller.dart';
import 'package:agribased/services/storage_router_service.dart';
import 'package:agribased/services/optimized_user_service.dart';
import 'package:agribased/models/post_model.dart';
import 'package:agribased/utils/verification_helpers.dart';

class PostCreationWidget extends StatefulWidget {
  final String userId;
  final String communityName;

  const PostCreationWidget({
    super.key,
    required this.userId,
    required this.communityName,
  });

  @override
  _PostCreationWidgetState createState() => _PostCreationWidgetState();
}

class _PostCreationWidgetState extends State<PostCreationWidget> {
  final TextEditingController _textController = TextEditingController();
  final List<File> _selectedFiles = [];
  final List<String> _selectedMediaTypes = [];
  final List<String> _mediaUrls = [];
  final Map<int, VideoPlayerController> _videoControllers = {};
  bool _isUploadingMedia = false;
  bool _isPosting = false;
  String? _locationTag;
  String? _feelingTag;

  // Lock author info to prevent flickering
  String _lockedAuthorName = 'Farmer';
  String _lockedAuthorAvatar = '';
  bool _showVerificationTick = false;

  @override
  void initState() {
    super.initState();
    _lockAuthorInfo();
  }

  @override
  void dispose() {
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _lockAuthorInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _lockedAuthorName = data['user_name'] ?? 'Farmer';
          _lockedAuthorAvatar = data['profile_pic'] ?? '';

          // Check verification status (30-day expiration)
          final isVerified = data['isVerified'] == true;
          final verificationStatus = data['verificationStatus'];
          final verificationPaid = data['verificationPaid'] == true;
          final verificationPaidAt = data['verificationPaidAt'];

          if (isVerified &&
              verificationStatus == 'approved' &&
              verificationPaid &&
              verificationPaidAt != null) {
            _showVerificationTick = !isVerificationPaymentExpired(verificationPaidAt);
          }
        });
      }
    } catch (e) {
      developer.log('Error loading author info: $e', name: 'PostCreation');
    }
  }

  // 📷 Pick Image
  Future<void> _pickImage() async {
    developer.log('📱 PostCreation: _pickImage() called', name: 'PostCreation');

    // If there's already a video, don't allow images
    if (_selectedFiles.isNotEmpty &&
        _selectedMediaTypes.any((type) => type == 'video')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot mix images with video in a post')),
      );
      return;
    }

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    developer.log(
      'PostCreation: Image picker result: ${picked?.path ?? 'null'}',
      name: 'PostCreation',
    );
    if (picked != null) {
      final file = File(picked.path);
      final index = _selectedFiles.length;

      setState(() {
        _selectedFiles.add(file);
        _selectedMediaTypes.add('image');
      });

      await _uploadFile(file, "image", index);
    } else {
      developer.log('PostCreation: No image selected', name: 'PostCreation');
    }
  }

  // 🎥 Pick Video
  Future<void> _pickVideo() async {
    // If there are already files and any of them is a video, don't allow another video
    if (_selectedFiles.isNotEmpty &&
        _selectedMediaTypes.any((type) => type == 'video')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only one video per post is allowed')),
      );
      return;
    }

    // If there are already images, don't allow video (single media per post)
    if (_selectedFiles.isNotEmpty &&
        _selectedMediaTypes.any((type) => type == 'image')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot mix video with images in a post')),
      );
      return;
    }

    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final index = _selectedFiles.length;

      setState(() {
        _selectedFiles.add(file);
        _selectedMediaTypes.add('video');
      });

      // Initialize video controller for local file
      final controller = VideoPlayerController.file(file);
      _videoControllers[index] = controller;
      await controller.initialize();
      setState(() {});

      await _uploadFile(file, "video", index);
    }
  }

  // 🗑️ Remove media
  void _removeMedia(int index) {
    // Dispose video controller if it exists
    final controller = _videoControllers[index];
    if (controller != null) {
      controller.dispose();
      _videoControllers.remove(index);
    }

    setState(() {
      _selectedFiles.removeAt(index);
      _selectedMediaTypes.removeAt(index);
      if (index < _mediaUrls.length) {
        _mediaUrls.removeAt(index);
      }
    });
  }

  // 📍 Pick Location
  Future<void> _pickLocation() async {
    // Simple location picker implementation
    final TextEditingController locationController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Location'),
        content: TextField(
          controller: locationController,
          decoration: const InputDecoration(
            hintText: 'Enter location',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, locationController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _locationTag = result;
      });
    }
  }

  // 😊 Pick Feeling
  Future<void> _pickFeeling() async {
    // Simple emoji picker implementation
    final List<String> emojis = [
      '😊',
      '😃',
      '😁',
      '😍',
      '🥰',
      '😎',
      '🤗',
      '😌',
      '😔',
      '😢',
      '😭',
      '😤',
      '😡',
      '🤔',
      '😴',
      '🤒',
      '🌱',
      '🌾',
      '🚜',
      '🌻',
      '🍅',
      '🌽',
      '🥕',
      '🍎',
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How are you feeling?'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1,
            ),
            itemCount: emojis.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => Navigator.pop(context, emojis[index]),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    emojis[index],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _feelingTag = result;
      });
    }
  }

  // 📺 Start Live Stream
  Future<void> _startLiveStream() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live streaming coming soon!')),
    );
  }

  // Get feeling description for emoji
  String _getFeelingDescription(String emoji) {
    switch (emoji) {
      case '😊':
        return 'Happy';
      case '😃':
        return 'Very Happy';
      case '😁':
        return 'Excited';
      case '😍':
        return 'In Love';
      case '🥰':
        return 'Loved';
      case '😎':
        return 'Cool';
      case '🤗':
        return 'Hugging';
      case '😌':
        return 'Relaxed';
      case '😔':
        return 'Sad';
      case '😢':
        return 'Crying';
      case '😭':
        return 'Very Sad';
      case '😤':
        return 'Frustrated';
      case '😡':
        return 'Angry';
      case '🤔':
        return 'Thinking';
      case '😴':
        return 'Sleepy';
      case '🤒':
        return 'Sick';
      case '🌱':
        return 'Hopeful';
      case '🌾':
        return 'Grateful';
      case '🚜':
        return 'Productive';
      case '🌻':
        return 'Cheerful';
      case '🍅':
        return 'Energetic';
      case '🌽':
        return 'Healthy';
      case '🥕':
        return 'Nourished';
      case '🍎':
        return 'Sweet';
      default:
        return 'Feeling Good';
    }
  }

  // ☁ Upload to Cloudinary
  Future<void> _uploadFile(File file, String type, int index) async {
    if (mounted) {
      setState(() {
        _isUploadingMedia = true;
      });
    }
    try {
      developer.log(
        'PostCreation: Starting upload for file: ${file.path}',
        name: 'PostCreation',
      );
      final url = await StorageRouterService.instance.uploadPostMedia(
        file: file,
        userId: widget.userId,
        mediaType: type,
      );
      if (!mounted) return;
      developer.log('PostCreation: Received URL: $url', name: 'PostCreation');
      developer.log(
        'PostCreation: URL starts with http: ${url?.startsWith('http') ?? false}',
        name: 'PostCreation',
      );

      setState(() {
        // Ensure the _mediaUrls list has enough elements
        while (_mediaUrls.length <= index) {
          _mediaUrls.add('');
        }
        _mediaUrls[index] = url ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      developer.log(
        'PostCreation: Upload failed with error: $e',
        name: 'PostCreation',
        error: e,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      rethrow;
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
      });
    }
  }

  // 🚀 Submit Post
  Future<void> _submitPostHybrid() async {
    // Immediate UI feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting post submission...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    developer.log(
      'PostCreation: _submitPostHybrid() called',
      name: 'PostCreation',
    );
    developer.log(
      'PostCreation: _selectedFiles.length = ${_selectedFiles.length}',
      name: 'PostCreation',
    );
    developer.log(
      'PostCreation: _selectedMediaTypes = $_selectedMediaTypes',
      name: 'PostCreation',
    );

    if (_textController.text.trim().isEmpty && _selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or media')),
      );
      return;
    }

    developer.log(
      'PostCreation: Starting post submission, setting _isPosting = true',
      name: 'PostCreation',
    );
    setState(() => _isPosting = true);

    try {
      if (_selectedFiles.isNotEmpty) {
        developer.log(
          'PostCreation: Has media files, verifying upload status',
          name: 'PostCreation',
        );

        if (_isUploadingMedia) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait for media to finish uploading'),
            ),
          );
          return;
        }

        final List<PostMedia> mediaList = [];
        for (int i = 0; i < _mediaUrls.length; i++) {
          if (i < _selectedMediaTypes.length && _mediaUrls[i].isNotEmpty) {
            mediaList.add(
              PostMedia(url: _mediaUrls[i], type: _selectedMediaTypes[i]),
            );
          }
        }

        if (mediaList.isEmpty && _selectedFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Media upload failed. Please try selecting the file again.'),
            ),
          );
          return;
        }

        developer.log(
          'PostCreation: Creating post with ${mediaList.length} media items',
          name: 'PostCreation',
        );

        await FeedController().createPost(
          content: _textController.text.trim(),
          media: mediaList,
          hashtags: [],
          locationTag: _locationTag ?? '',
          feelingTag: _feelingTag ?? '',
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully!')),
          );
        }
      } else {
        developer.log('PostCreation: Text-only post', name: 'PostCreation');

        // Text-only post
        await FeedController().createPost(
          content: _textController.text.trim(),
          media: [],
          hashtags: [],
          locationTag: _locationTag ?? '',
          feelingTag: _feelingTag ?? '',
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully!')),
          );
        }
      }
    } catch (e) {
      developer.log(
        'PostCreation: Error in _submitPostHybrid: $e',
        name: 'PostCreation',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
      }
    } finally {
      developer.log(
        'PostCreation: Finally block, resetting _isPosting = false',
        name: 'PostCreation',
      );
      // Always reset posting state
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  // Upload video in background and update post
  Future<void> _uploadVideoInBackground(String postId) async {
    try {
      for (int i = 0; i < _selectedFiles.length; i++) {
        if (_selectedMediaTypes[i] == 'video') {
          developer.log(
            'PostCreation: Starting video upload for file $i',
            name: 'PostCreation',
          );

          // Add timeout to prevent infinite loading
          final url = await StorageRouterService.instance
              .uploadPostMedia(
                file: _selectedFiles[i],
                userId: widget.userId,
                mediaType: 'video',
              )
              .timeout(
                const Duration(minutes: 5), // 5 minute timeout
                onTimeout: () {
                  developer.log(
                    'PostCreation: Video upload timed out after 5 minutes',
                    name: 'PostCreation',
                  );
                  throw TimeoutException(
                    'Video upload timed out. Please try again.',
                    const Duration(minutes: 5),
                  );
                },
              );

          developer.log(
            'PostCreation: Video upload completed, URL: $url',
            name: 'PostCreation',
          );

          // Update the post with the actual video URL and remove processing message
          if (url.isNotEmpty) {
            final cleanContent = _textController.text.trim();
            final List<PostMedia> mediaList = [
              PostMedia(url: url, type: 'video'),
            ];

            // Update the post in Firestore
            await FirebaseFirestore.instance
                .collection('posts')
                .doc(postId)
                .update({
                  'content': cleanContent,
                  'media': mediaList.map((m) => m.toJson()).toList(),
                });

            // Refresh the post in the feed to update UI
            await FeedController().refreshSinglePost(postId);

            // Show success notification
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception('Video upload returned empty URL');
          }
        }
      }
    } catch (e) {
      developer.log(
        'PostCreation: Video upload failed: $e',
        name: 'PostCreation',
      );

      // Show error notification and reset posting state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video upload failed: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                // Retry the upload
                _submitPostHybrid();
              },
            ),
          ),
        );
      }

      // Reset posting state even on error
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  // Helper methods for media preview
  int _getCrossAxisCount() {
    if (_selectedFiles.length == 1) return 1; // Single media - full width
    if (_selectedFiles.length == 2) return 2;
    if (_selectedFiles.length == 3) return 3;
    return 2; // For 4+ images, use 2 columns
  }

  double _getMediaPreviewHeight() {
    final screenWidth = MediaQuery.of(context).size.width;
    final count = _selectedFiles.length;

    if (count == 1) return 300; // Single media - fixed height like Facebook
    if (count == 2) return screenWidth / 2;
    if (count == 3) return screenWidth / 3;
    if (count == 4) return screenWidth;
    if (count == 5) return screenWidth * 1.5;
    return screenWidth * (count / 2).ceil() / 2; // For 6+ images
  }

  // Build video thumbnail for uploaded video
  Widget _buildVideoThumbnail(int index, String url) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: const Icon(
            Icons.play_circle_filled,
            color: Colors.white,
            size: 50,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build video thumbnail for local video file
  Widget _buildLocalVideoThumbnail(int index, File file) {
    final controller = _videoControllers[index];

    if (controller != null && controller.value.isInitialized) {
      return Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 8,
            right: 8,
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Icon(
        Icons.play_circle_filled,
        color: Colors.white,
        size: 50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 👤 AUTHOR HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: _lockedAuthorAvatar.startsWith('http')
                        ? NetworkImage(_lockedAuthorAvatar)
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: !_lockedAuthorAvatar.startsWith('http')
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _lockedAuthorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_showVerificationTick)
                              Image.asset(
                                'assets/icon/verification_tick.png',
                                width: 18,
                                height: 18,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.verified, size: 18, color: Colors.blue);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Share your farming journey...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// ✏️ Text input
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                maxLines: 6,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'What\'s happening on your farm today?',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            /// 🖼 Media preview
            if (_selectedFiles.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media grid
                    Container(
                      height: _getMediaPreviewHeight(),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(),
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          final mediaType = _selectedMediaTypes[index];
                          final mediaUrl = index < _mediaUrls.length
                              ? _mediaUrls[index]
                              : null;

                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      mediaUrl != null &&
                                          mediaUrl.startsWith('http')
                                      ? (mediaType == 'image'
                                            ? Image.network(
                                                mediaUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              )
                                            : _buildVideoThumbnail(
                                                index,
                                                mediaUrl,
                                              ))
                                      : (mediaType == 'image'
                                            ? Image.file(
                                                file,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              )
                                            : _buildLocalVideoThumbnail(
                                                index,
                                                file,
                                              )),
                                ),
                              ),
                              // Remove button
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeMedia(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              // Upload status
                              if (mediaUrl == null ||
                                  !mediaUrl.startsWith('http'))
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (mediaUrl != null &&
                                  mediaUrl.startsWith('http'))
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      '✓',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Add more media button
                    if (_selectedFiles.length < 10)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(
                                  Icons.add_photo_alternate,
                                  size: 20,
                                ),
                                label: const Text('Add Image'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickVideo,
                                icon: const Icon(Icons.video_call, size: 20),
                                label: const Text('Add Video'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            /// Location and Feeling Tags Display
            if (_locationTag != null || _feelingTag != null)
              Container(
                margin: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (_locationTag != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Location',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _locationTag!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _locationTag = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_feelingTag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.pink.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _feelingTag!,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Feeling',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getFeelingDescription(_feelingTag!),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _feelingTag = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            /// Action buttons
            if (_selectedFiles.isEmpty)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      Icons.photo_library,
                      'Photo',
                      _pickImage,
                    ),
                    _buildActionButton(Icons.videocam, 'Video', _pickVideo),
                    _buildActionButton(
                      Icons.location_on,
                      'Location',
                      _pickLocation,
                    ),
                    _buildActionButton(
                      Icons.emoji_emotions,
                      'Feeling',
                      _pickFeeling,
                    ),
                    _buildActionButton(Icons.live_tv, 'Live', _startLiveStream),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            /// 🚀 Post button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isPosting || _isUploadingMedia)
                      ? null
                      : _submitPostHybrid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: (_isPosting || _isUploadingMedia)
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Posting...'),
                          ],
                        )
                      : const Text(
                          'Post',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for action buttons
  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.green),
          onPressed: onPressed,
          iconSize: 28,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
