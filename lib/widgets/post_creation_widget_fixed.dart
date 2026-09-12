import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/services/storage_router_service.dart';
import 'package:agribased/controllers/feed_controller.dart';
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
    print('📱 PostCreation: _pickImage() called');
    developer.log('PostCreation: _pickImage() called', name: 'PostCreation');
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    print('📱 PostCreation: Image picker result: ${picked?.path ?? 'null'}');
    developer.log(
      'PostCreation: Image picker result: ${picked?.path ?? 'null'}',
      name: 'PostCreation',
    );
    if (picked != null) {
      final file = File(picked.path);
      setState(() {
        _selectedFiles.add(file);
        _selectedMediaTypes.add('image');
        print('📱 PostCreation: File added: ${file.path}');
        developer.log(
          'PostCreation: File added: ${file.path}',
          name: 'PostCreation',
        );
      });
      print('📱 PostCreation: Starting upload...');
      developer.log('PostCreation: Starting upload...', name: 'PostCreation');
      await _uploadFile(file, "image", _selectedFiles.length - 1);
    } else {
      print('📱 PostCreation: No image selected');
      developer.log('PostCreation: No image selected', name: 'PostCreation');
    }
  }

  // 🎥 Pick Video
  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      setState(() {
        _selectedFiles.add(file);
        _selectedMediaTypes.add('video');
      });
      await _uploadFile(file, "video", _selectedFiles.length - 1);
    }
  }

  // 🗑️ Remove media
  void _removeMedia(int index) {
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
    setState(() {
      _locationTag = 'Farm Location';
    });
  }

  // 😊 Pick Feeling
  Future<void> _pickFeeling() async {
    setState(() {
      _feelingTag = 'Happy';
    });
  }

  // 📺 Start Live Stream
  Future<void> _startLiveStream() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live streaming coming soon!')),
    );
  }

  // ☁ Upload to Cloudinary
  Future<void> _uploadFile(File file, String type, int index) async {
    if (mounted) {
      setState(() {
        _isUploadingMedia = true;
      });
    }
    try {
      print('📱 PostCreation: Starting upload for file: ${file.path}');
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
      print('📱 PostCreation: Received URL: $url');
      developer.log('PostCreation: Received URL: $url', name: 'PostCreation');
      print(
        '📱 PostCreation: URL starts with http: ${url?.startsWith('http') ?? false}',
      );
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
      print('📱 PostCreation: Upload failed with error: $e');
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
    if (_textController.text.trim().isEmpty && _selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or media')),
      );
      return;
    }

    // Check if all media has finished uploading
    if (_isUploadingMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for media to finish uploading'),
        ),
      );
      return;
    }

    // Check if any media failed to upload
    if (_selectedFiles.isNotEmpty &&
        _mediaUrls.length < _selectedFiles.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some media is still uploading. Please wait...'),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      // Create PostMedia objects from uploaded URLs
      final List<PostMedia> mediaList = [];
      for (int i = 0; i < _mediaUrls.length; i++) {
        if (_mediaUrls[i].isNotEmpty) {
          mediaList.add(
            PostMedia(url: _mediaUrls[i], type: _selectedMediaTypes[i]),
          );
        }
      }

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
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
                                            : Container(
                                                color: Colors.black,
                                                child: const Icon(
                                                  Icons.play_circle_filled,
                                                  color: Colors.white,
                                                  size: 50,
                                                ),
                                              ))
                                      : (mediaType == 'image'
                                            ? Image.file(
                                                file,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              )
                                            : Container(
                                                color: Colors.black,
                                                child: const Icon(
                                                  Icons.play_circle_filled,
                                                  color: Colors.white,
                                                  size: 50,
                                                ),
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

            /// 🧰 Action buttons
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
                            SizedBox(width: 12),
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

  // Helper methods for media preview
  int _getCrossAxisCount() {
    if (_selectedFiles.length == 1) return 1;
    if (_selectedFiles.length == 2) return 2;
    if (_selectedFiles.length == 3) return 3;
    return 2; // For 4+ images, use 2 columns
  }

  double _getMediaPreviewHeight() {
    final screenWidth = MediaQuery.of(context).size.width;
    final count = _selectedFiles.length;

    if (count == 1) return 250;
    if (count == 2) return screenWidth / 2;
    if (count == 3) return screenWidth / 3;
    if (count == 4) return screenWidth;
    if (count == 5) return screenWidth * 1.5;
    return screenWidth * (count / 2).ceil() / 2; // For 6+ images
  }
}
