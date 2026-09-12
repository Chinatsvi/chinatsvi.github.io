import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/post_model.dart';
import '../../controllers/feed_controller.dart';
import '../../services/storage_router_service.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final Post post;

  const EditPostScreen({super.key, required this.postId, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _captionController;
  late TextEditingController _contentController;
  
  // Existing media from post
  List<PostMedia> _existingMedia = [];

  // Newly selected media files
  final List<File> _newFiles = [];
  final List<String> _newMediaTypes = []; // 'image' or 'video'
  final Map<int, VideoPlayerController> _videoControllers = {};

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.post.caption);
    _contentController = TextEditingController(text: widget.post.content);
    _existingMedia = List<PostMedia>.from(widget.post.media);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _contentController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _hasVideo {
    return _existingMedia.any((m) => m.type == 'video') ||
        _newMediaTypes.any((t) => t == 'video');
  }

  bool get _hasImages {
    return _existingMedia.any((m) => m.type == 'image') ||
        _newMediaTypes.any((t) => t == 'image');
  }

  // 📷 Pick Image from Gallery or Camera
  Future<void> _pickImage(ImageSource source) async {
    if (_hasVideo) {
      _showErrorSnackBar('Cannot mix images with a video. Please remove the video first.');
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _newFiles.add(File(picked.path));
          _newMediaTypes.add('image');
        });
      }
    } catch (e) {
      developer.log('Error picking image: $e', name: 'EditPostScreen');
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  // 🎥 Pick Video from Gallery or Camera
  Future<void> _pickVideo(ImageSource source) async {
    if (_hasVideo) {
      _showErrorSnackBar('Only one video per post is allowed.');
      return;
    }

    if (_hasImages) {
      _showErrorSnackBar('Cannot mix a video with images. Please remove the images first.');
      return;
    }

    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (picked != null) {
        final file = File(picked.path);
        final newIndex = _newFiles.length;

        setState(() {
          _newFiles.add(file);
          _newMediaTypes.add('video');
        });

        // Initialize local video preview
        final controller = VideoPlayerController.file(file);
        _videoControllers[newIndex] = controller;
        await controller.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      developer.log('Error picking video: $e', name: 'EditPostScreen');
      _showErrorSnackBar('Failed to pick video: $e');
    }
  }

  void _showMediaSourceDialog({required bool isVideo}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  isVideo ? Icons.videocam : Icons.photo_camera,
                  color: const Color(0xFF2E7D32),
                ),
                title: Text(isVideo ? 'Record Video' : 'Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  if (isVideo) {
                    _pickVideo(ImageSource.camera);
                  } else {
                    _pickImage(ImageSource.camera);
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  isVideo ? Icons.video_library : Icons.photo_library,
                  color: const Color(0xFF2E7D32),
                ),
                title: Text(isVideo ? 'Choose Video from Gallery' : 'Choose Photo from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  if (isVideo) {
                    _pickVideo(ImageSource.gallery);
                  } else {
                    _pickImage(ImageSource.gallery);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeExistingMedia(int index) {
    setState(() {
      _existingMedia.removeAt(index);
    });
  }

  void _removeNewMedia(int index) {
    final controller = _videoControllers[index];
    if (controller != null) {
      controller.dispose();
      _videoControllers.remove(index);
    }

    setState(() {
      _newFiles.removeAt(index);
      _newMediaTypes.removeAt(index);
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 🚀 Update Post with Text & Media
  Future<void> _updatePost() async {
    if (_isLoading) return;

    final caption = _captionController.text.trim();
    final content = _contentController.text.trim();

    if (caption.isEmpty && content.isEmpty && _existingMedia.isEmpty && _newFiles.isEmpty) {
      _showErrorSnackBar('Post cannot be empty. Please enter text or add media.');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Saving changes...';
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? widget.post.authorId;
      final List<PostMedia> finalMedia = List<PostMedia>.from(_existingMedia);

      // Upload newly picked files if any
      if (_newFiles.isNotEmpty) {
        for (int i = 0; i < _newFiles.length; i++) {
          final file = _newFiles[i];
          final type = _newMediaTypes[i];

          setState(() {
            _uploadStatus = 'Uploading ${type == 'video' ? 'video' : 'image'} (${i + 1}/${_newFiles.length})...';
          });

          developer.log(
            'EditPostScreen: Uploading $type $i to storage router...',
            name: 'EditPostScreen',
          );

          final uploadedUrl = await StorageRouterService.instance.uploadPostMedia(
            file: file,
            userId: currentUserId,
            mediaType: type,
          );

          if (uploadedUrl.isNotEmpty && uploadedUrl.startsWith('http')) {
            finalMedia.add(PostMedia(url: uploadedUrl, type: type));
          } else {
            throw Exception('Failed to upload $type. Please try again.');
          }
        }
      }

      setState(() {
        _uploadStatus = 'Updating post...';
      });

      // Determine content type
      String contentType = 'text';
      if (finalMedia.any((m) => m.type == 'video')) {
        contentType = 'video';
      } else if (finalMedia.isNotEmpty) {
        contentType = 'image';
      }

      // Legacy URL helpers
      final imageMediaList = finalMedia.where((m) => m.type == 'image').toList();
      final String firstImageUrl = imageMediaList.isNotEmpty ? imageMediaList.first.url : '';
      final List<String> allImageUrls = imageMediaList.map((m) => m.url).toList();

      final updateData = <String, dynamic>{
        'caption': caption,
        'content': content,
        'media': finalMedia.map((m) => m.toJson()).toList(),
        'content_type': contentType,
        'contentType': contentType,
        'imageUrl': firstImageUrl,
        'mediaUrl': firstImageUrl,
        'mediaUrls': allImageUrls,
        'updated_at': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh feed & single post
        FeedController().refreshPosts();
        FeedController().refreshSinglePost(widget.postId);

        Navigator.of(context).pop();
      }
    } catch (e) {
      developer.log('Error updating post: $e', name: 'EditPostScreen', error: e);
      _showErrorSnackBar('Error updating post: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMediaCount = _existingMedia.length + _newFiles.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Post',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updatePost,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _uploadStatus.isNotEmpty ? _uploadStatus : 'Updating post...',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caption / Title field
                  TextField(
                    controller: _captionController,
                    decoration: InputDecoration(
                      labelText: 'Caption (Optional)',
                      hintText: 'Enter a short title or summary...',
                      prefixIcon: const Icon(Icons.title, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Content / Body field
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      hintText: 'What do you want to share with farmers?',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.edit_note, color: Color(0xFF2E7D32)),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    maxLines: 8,
                    minLines: 4,
                  ),
                  const SizedBox(height: 20),

                  // Media Header & Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Post Media',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B382B),
                        ),
                      ),
                      if (totalMediaCount > 0)
                        Text(
                          '$totalMediaCount item${totalMediaCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Media Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showMediaSourceDialog(isVideo: false),
                          icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF2E7D32)),
                          label: const Text(
                            'Add Image',
                            style: TextStyle(color: Color(0xFF2E7D32)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showMediaSourceDialog(isVideo: true),
                          icon: const Icon(Icons.videocam, color: Color(0xFF2E7D32)),
                          label: const Text(
                            'Add Video',
                            style: TextStyle(color: Color(0xFF2E7D32)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Media Previews Grid
                  if (totalMediaCount > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemCount: totalMediaCount,
                        itemBuilder: (context, index) {
                          // Check if it's existing media or newly picked file
                          if (index < _existingMedia.length) {
                            final media = _existingMedia[index];
                            final isVideo = media.type == 'video';

                            return _buildMediaTile(
                              child: isVideo
                                  ? Container(
                                      color: Colors.black87,
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      ),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: media.url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    ),
                              badgeText: isVideo ? 'Video (Saved)' : 'Image (Saved)',
                              badgeColor: const Color(0xFF2E7D32),
                              onRemove: () => _removeExistingMedia(index),
                            );
                          } else {
                            final newIndex = index - _existingMedia.length;
                            final file = _newFiles[newIndex];
                            final type = _newMediaTypes[newIndex];
                            final isVideo = type == 'video';

                            return _buildMediaTile(
                              child: isVideo
                                  ? _buildLocalVideoPreview(newIndex, file)
                                  : Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                    ),
                              badgeText: isVideo ? 'New Video' : 'New Image',
                              badgeColor: Colors.blue.shade700,
                              onRemove: () => _removeNewMedia(newIndex),
                            );
                          }
                        },
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.perm_media_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No media attached to this post',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Use the buttons above to add photos or a video',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Bottom Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updatePost,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Update Post',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLocalVideoPreview(int newIndex, File file) {
    final controller = _videoControllers[newIndex];
    if (controller != null && controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 42),
          ),
        ],
      );
    }

    return Container(
      color: Colors.black87,
      child: const Center(
        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 42),
      ),
    );
  }

  Widget _buildMediaTile({
    required Widget child,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onRemove,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          // Badge
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Delete button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
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
        ],
      ),
    );
  }
}
