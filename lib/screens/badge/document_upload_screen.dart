import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/storage_router_service.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  File? _selectedFile;
  bool _uploading = false;

  final ImagePicker _picker = ImagePicker();

  String? _selectedDocType;

  final List<String> _documentTypes = [
    'National ID / Passport',
    'Farmer Permit / License',
    'Agricultural College ID',
    'Company Registration Document',
  ];

  /// 📸 Pick from camera or gallery
  Future<void> _pickDocument(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  /// ⬆️ Upload document using Cloudinary
  Future<void> _uploadDocument() async {
    if (_selectedFile == null || _selectedDocType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a document type and upload a clear image',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Check if file exists before uploading
      if (!await _selectedFile!.exists()) {
        throw Exception('File does not exist: ${_selectedFile!.path}');
      }

      // Upload to Cloudinary using StorageRouterService
      final downloadUrl = await StorageRouterService.instance
          .uploadVerificationDocument(
            file: _selectedFile!,
            userId: uid,
            docType: _selectedDocType!,
          );

      if (downloadUrl.isEmpty) {
        throw Exception('Failed to upload document to Cloudinary');
      }

      await FirebaseFirestore.instance.collection('farmers').doc(uid).update({
        'verificationDocument': {
          'type': _selectedDocType,
          'url': downloadUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
        },
        'verificationStatus': 'pending',
        'verificationRequestedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Document uploaded. Verification in progress.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Documents'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 📘 Instructions
            const Text(
              'Upload a Verification Document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To receive a green verification tick, you must upload at least ONE of the following documents. '
              'Ensure the document is clear, complete, and all text is readable.',
            ),

            const SizedBox(height: 16),

            /// 📄 Document Type Selector
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Document Type *',
                border: OutlineInputBorder(),
              ),
              value: _selectedDocType,
              items: _documentTypes
                  .map((doc) => DropdownMenuItem(value: doc, child: Text(doc)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedDocType = value);
              },
            ),

            const SizedBox(height: 20),

            /// 🖼️ Preview
            _selectedFile != null
                ? Column(
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(child: Text('Failed to load image')),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '✔ Make sure the document is clear and fully visible',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  )
                : Container(
                    height: 160,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('No document selected'),
                  ),

            const SizedBox(height: 20),

            /// 📸 Pick Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Use Camera'),
                    onPressed: () => _pickDocument(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                    onPressed: () => _pickDocument(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// ⬆️ Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploading ? null : _uploadDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _uploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Upload & Submit for Verification',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
