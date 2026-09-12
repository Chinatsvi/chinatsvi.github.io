import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';
import '../../services/imagekit_upload_service.dart';

class CloudinaryTestScreen extends StatefulWidget {
  const CloudinaryTestScreen({super.key});

  @override
  State<CloudinaryTestScreen> createState() => _CloudinaryTestScreenState();
}

class _CloudinaryTestScreenState extends State<CloudinaryTestScreen> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImageKitUploadService _imageKitService = ImageKitUploadService();
  String? _uploadedImageUrl;
  String? _uploadedVideoUrl;
  bool _isUploading = false;
  String _uploadStatusText = '';

  Future<void> _testImageKitImageUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _isUploading = true;
        _uploadStatusText = 'Uploading image to ImageKit...';
      });

      try {
        final file = File(picked.path);
        final url = await _imageKitService.uploadPostImage(
          file: file,
          postId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          setState(() {
            _uploadedImageUrl = url;
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                url != null ? 'ImageKit upload successful!' : 'ImageKit upload failed',
              ),
              backgroundColor: url != null ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _testImageKitVideoUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _isUploading = true;
        _uploadStatusText = 'Uploading video to ImageKit...';
      });

      try {
        final file = File(picked.path);
        final url = await _imageKitService.uploadPostVideo(
          file: file,
          postId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          setState(() {
            _uploadedVideoUrl = url;
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                url != null ? 'ImageKit video upload successful!' : 'ImageKit upload failed',
              ),
              backgroundColor: url != null ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _testImageUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _isUploading = true);

      try {
        final file = File(picked.path);
        final url = await _cloudinaryService.uploadPostImage(
          file: file,
          postId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          setState(() {
            _uploadedImageUrl = url;
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                url != null ? 'Image uploaded successfully!' : 'Upload failed',
              ),
              backgroundColor: url != null ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _testVideoUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _isUploading = true);

      try {
        final file = File(picked.path);
        final url = await _cloudinaryService.uploadPostVideo(
          file: file,
          postId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          setState(() {
            _uploadedVideoUrl = url;
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                url != null ? 'Video uploaded successfully!' : 'Upload failed',
              ),
              backgroundColor: url != null ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloudinary Test'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Media Uploads',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _isUploading ? null : _testImageKitImageUpload,
              icon: const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? 'Uploading...' : 'Test ImageKit Image Upload (Default)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isUploading ? null : _testImageKitVideoUpload,
              icon: const Icon(Icons.video_call),
              label: Text(_isUploading ? 'Uploading...' : 'Test ImageKit Video Upload (Default)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Legacy Cloudinary Tests:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isUploading ? null : _testImageUpload,
              icon: const Icon(Icons.image),
              label: Text(_isUploading ? 'Uploading...' : 'Legacy Cloudinary Image Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isUploading ? null : _testVideoUpload,
              icon: const Icon(Icons.video_library),
              label: Text(_isUploading ? 'Uploading...' : 'Legacy Cloudinary Video Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 20),

            if (_uploadedImageUrl != null) ...[
              const Text(
                'Uploaded Image:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  _uploadedImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Text('Failed to load image')),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(_uploadedImageUrl!),
              const SizedBox(height: 20),
            ],

            if (_uploadedVideoUrl != null) ...[
              const Text(
                'Uploaded Video URL:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectableText(_uploadedVideoUrl!),
              const SizedBox(height: 20),
            ],

            if (_isUploading)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_uploadStatusText.isNotEmpty ? _uploadStatusText : 'Uploading media...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
