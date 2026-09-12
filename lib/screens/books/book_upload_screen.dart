import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:agribased/models/books/book_model.dart';
import 'package:agribased/services/imagekit_upload_service.dart';
import 'dart:developer' as developer;

class BookUploadScreen extends StatefulWidget {
  final BookModel? book;

  const BookUploadScreen({super.key, this.book});

  @override
  State<BookUploadScreen> createState() => _BookUploadScreenState();
}

class _BookUploadScreenState extends State<BookUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageKitService = ImageKitUploadService();
  final _imagePicker = ImagePicker();

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  File? _bookFile;
  File? _coverImageFile;
  String? _bookFileName;
  String? _bookFilePreview;
  String? _existingBookUrl;
  String? _existingCoverImageUrl;

  bool _isUploading = false;
  String? _uploadStatus;

  bool get _isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final book = widget.book!;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _descriptionController.text = book.description;
      _categoryController.text = book.category;
      _existingBookUrl = book.fullPages.isNotEmpty ? book.fullPages.first : null;
      _existingCoverImageUrl = book.coverImage.isNotEmpty ? book.coverImage : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickBookFile() async {
    try {
      final result = await _imagePicker.pickMedia();
      if (result == null) return;

      File file = File(result.path);
      final extension = file.path.split('.').last.toLowerCase();

      if (extension != 'pdf' && extension != 'txt' && extension != 'docx') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only PDF, TXT or DOCX files are allowed for books'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      String? preview;
      try {
        if (extension == 'txt') {
          final content = await file.readAsString();
          preview = content.length > 1200 ? content.substring(0, 1200) + '...' : content;
        } else if (extension == 'docx') {
          final bytes = await file.readAsBytes();
          try {
            final archive = ZipDecoder().decodeBytes(bytes);
            final docFile = archive.files.firstWhere(
              (f) => f.name == 'word/document.xml' || f.name.endsWith('/word/document.xml'),
              orElse: () => ArchiveFile('', 0, []),
            );
            if (docFile.name.isNotEmpty && docFile.content != null) {
              final xmlString = utf8.decode(docFile.content as List<int>);
              var text = xmlString.replaceAll(RegExp(r'<w:p[^>]*>'), '\n\n');
              text = text.replaceAll(RegExp(r'<w:br[^>]*\/?>'), '\n');
              text = text.replaceAll(RegExp(r'<[^>]+>'), '');
              text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
              preview = text.length > 1200 ? text.substring(0, 1200) + '...' : text;

              final dir = await getTemporaryDirectory();
              final tempFile = File('${dir.path}/${result.name}.txt');
              await tempFile.writeAsString(text);
              file = tempFile;
            }
          } catch (e) {
            developer.log('Error converting DOCX: $e', name: 'BookUpload');
          }
        }
      } catch (e) {
        preview = null;
      }

      setState(() {
        _bookFile = file;
        _bookFileName = result.name;
        _bookFilePreview = preview;
      });
    } catch (e) {
      developer.log('Error picking book file: $e', name: 'BookUpload');
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final result = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (result == null) return;

      setState(() {
        _coverImageFile = File(result.path);
      });
    } catch (e) {
      developer.log('Error picking cover image: $e', name: 'BookUpload');
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_bookFile == null && _existingBookUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a book file (PDF or TXT)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = _isEditing ? 'Saving book changes...' : 'Uploading book...';
    });

    try {
      final bookId = _isEditing ? widget.book!.id : FirebaseFirestore.instance.collection('books').doc().id;
      String? fullBookUrl = _existingBookUrl;
      String? coverImageUrl = _existingCoverImageUrl ?? '';

      if (_bookFile != null) {
        setState(() {
          _uploadStatus = 'Uploading book file...';
        });
        final uploadedBookUrl = await _imageKitService.uploadBookFile(
          file: _bookFile!,
          bookId: bookId,
        );

        if (uploadedBookUrl == null) {
          throw Exception('Failed to upload book file');
        }

        fullBookUrl = uploadedBookUrl;
      }

      if (_coverImageFile != null) {
        setState(() {
          _uploadStatus = 'Uploading cover image...';
        });
        final uploadedCoverUrl = await _imageKitService.uploadBookCoverImage(
          file: _coverImageFile!,
          bookId: bookId,
        );

        if (uploadedCoverUrl != null) {
          coverImageUrl = uploadedCoverUrl;
        }
      }

      setState(() {
        _uploadStatus = 'Saving book metadata...';
      });

      final payload = {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'coverImage': coverImageUrl ?? '',
        'price': 0,
        'isFree': true,
        'previewPages': [],
        'fullPages': fullBookUrl == null ? [] : [fullBookUrl],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing) {
        await FirebaseFirestore.instance.collection('books').doc(widget.book!.id).update(payload);
      } else {
        await FirebaseFirestore.instance.collection('books').doc(bookId).set({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
          'uploadedBy': 'admin',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Book updated successfully! ✅' : 'Book uploaded successfully! ✅',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      developer.log('Error saving book: $e', name: 'BookUpload');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(_isEditing ? 'Edit Farming Book' : 'Upload Farming Book'),
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _uploadStatus ?? 'Saving...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Book File (Optional to keep current file)' : 'Book File (PDF or TXT)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_bookFile != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf, color: Colors.green),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _bookFileName ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _bookFile = null;
                                          _bookFileName = null;
                                          _bookFilePreview = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_bookFilePreview != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text(
                                        _bookFilePreview!,
                                        maxLines: 10,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                            ] else if (_isEditing && _existingBookUrl != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.attach_file, color: Colors.green),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text('Current book file will be kept'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            ElevatedButton.icon(
                              onPressed: _pickBookFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Select PDF or TXT File'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cover Image (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_coverImageFile != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _coverImageFile!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _coverImageFile = null;
                                  });
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text('Remove Cover'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ] else if (_isEditing && _existingCoverImageUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _existingCoverImageUrl!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 150,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(Icons.book, size: 40, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            ElevatedButton.icon(
                              onPressed: _pickCoverImage,
                              icon: const Icon(Icons.image),
                              label: const Text('Select Cover Image'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an author';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category (e.g., Crops, Livestock, Vegetables)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isEditing ? 'Save Changes' : 'Upload Book',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
