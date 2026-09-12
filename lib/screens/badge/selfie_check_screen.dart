import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../services/storage_router_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class SelfieCheckScreen extends StatefulWidget {
  const SelfieCheckScreen({super.key});

  @override
  State<SelfieCheckScreen> createState() => _SelfieCheckScreenState();
}

class _SelfieCheckScreenState extends State<SelfieCheckScreen> {
  File? _capturedFile;
  bool _isVideo = false;
  bool _uploading = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  Future<void> _captureSelfie() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _disposeVideoControllers();
      setState(() {
        _capturedFile = File(pickedFile.path);
        _isVideo = false;
      });
    }
  }

  Future<void> _captureVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.camera);

    if (pickedFile != null) {
      _disposeVideoControllers();
      final file = File(pickedFile.path);
      setState(() {
        _capturedFile = file;
        _isVideo = true;
      });
      await _initVideoController(file);
    }
  }

  Future<void> _pickFromGallery({bool allowVideo = false}) async {
    final picker = ImagePicker();
    if (allowVideo) {
      final pickedVideo = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedVideo != null) {
        _disposeVideoControllers();
        final file = File(pickedVideo.path);
        setState(() {
          _capturedFile = file;
          _isVideo = true;
        });
        await _initVideoController(file);
        return;
      }
    }

    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      _disposeVideoControllers();
      setState(() {
        _capturedFile = File(pickedImage.path);
        _isVideo = false;
      });
    }
  }

  Future<void> _initVideoController(File file) async {
    try {
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
      );
      setState(() {});
    } catch (e) {
      // ignore initialization errors for now
    }
  }

  void _disposeVideoControllers() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  Future<void> _uploadSelfie() async {
    if (_capturedFile == null) return;

    setState(() => _uploading = true);

    try {
      // Check if file exists before uploading
      if (!await _capturedFile!.exists()) {
        throw Exception('File does not exist: ${_capturedFile!.path}');
      }

      final uid = FirebaseAuth.instance.currentUser!.uid;

      String downloadUrl = '';
      if (_isVideo) {
        downloadUrl = await StorageRouterService.instance
            .uploadVerificationVideo(file: _capturedFile!, userId: uid);
        if (downloadUrl.isEmpty) throw Exception('Failed to upload verification video');

        await FirebaseFirestore.instance.collection('farmers').doc(uid).update({
          'selfieVideoUrl': downloadUrl,
          'selfieVideoUploadedAt': FieldValue.serverTimestamp(),
        });
      } else {
        downloadUrl = await StorageRouterService.instance
            .uploadVerificationSelfie(file: _capturedFile!, userId: uid);
        if (downloadUrl.isEmpty) throw Exception('Failed to upload selfie to Cloudinary');

        await FirebaseFirestore.instance.collection('farmers').doc(uid).update({
          'selfieUrl': downloadUrl,
          'selfieUploadedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Selfie uploaded successfully')),
      );

      Navigator.pop(context, true); // return true to parent screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading selfie: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _disposeVideoControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selfie / Video Check"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _capturedFile != null
                ? Container(
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _isVideo
                          ? (_chewieController != null
                              ? Chewie(controller: _chewieController!)
                              : Center(child: Text('Video ready to preview')))
                          : Image.file(
                              _capturedFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: const Center(child: Text('Failed to load image')),
                              ),
                            ),
                    ),
                  )
                : const Text("No selfie captured"),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _captureSelfie,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Capture Selfie"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _captureVideo,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Capture Video"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickFromGallery(allowVideo: false),
                    child: const Text('Pick Image from Gallery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickFromGallery(allowVideo: true),
                    child: const Text('Pick Video from Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _uploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _capturedFile != null ? _uploadSelfie : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("Upload & Save"),
                  ),
          ],
        ),
      ),
    );
  }
}
