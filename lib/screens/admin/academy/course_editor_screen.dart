import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/academy/course_model.dart';
import '../../../services/academy/academy_service.dart';
import '../../../services/storage_router_service.dart';

class CourseEditorScreen extends StatefulWidget {
  final CourseModel? course;

  const CourseEditorScreen({super.key, this.course});

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _shortDescController;
  late TextEditingController _fullDescController;
  late TextEditingController _instructorController;
  late TextEditingController _durationController;
  late TextEditingController _cropController;
  late TextEditingController _thumbnailUrlController;
  late TextEditingController _whatYouWillLearnController;
  late TextEditingController _sourceController;
  late TextEditingController _disclaimerController;
  late TextEditingController _regionsController;
  late TextEditingController _countriesController;
  late TextEditingController _versionController;

  String _categoryId = 'crop_production';
  String _categoryName = 'Crop Production';
  String _difficulty = 'Beginner';
  String _language = 'English';
  String _status = 'draft';
  bool _isFree = true;
  bool _isFeatured = false;
  bool _isSaving = false;
  bool _isUploadingThumbnail = false;
  File? _pickedImage;

  final List<Map<String, String>> _categories = const [
    {'id': 'crop_production', 'name': 'Crop Production'},
    {'id': 'poultry', 'name': 'Poultry'},
    {'id': 'livestock', 'name': 'Livestock'},
    {'id': 'irrigation', 'name': 'Irrigation'},
    {'id': 'aquaculture', 'name': 'Aquaculture'},
    {'id': 'soil_fertility', 'name': 'Soil & Fertility'},
    {'id': 'agribusiness', 'name': 'Agribusiness'},
    {'id': 'greenhouse', 'name': 'Greenhouse Farming'},
    {'id': 'farm_management', 'name': 'Farm Management'},
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _titleController = TextEditingController(text: c?.title ?? '');
    _shortDescController =
        TextEditingController(text: c?.shortDescription ?? '');
    _fullDescController = TextEditingController(text: c?.description ?? '');
    _instructorController = TextEditingController(
        text: c?.instructorName ?? 'AgriBase Agronomist');
    _durationController =
        TextEditingController(text: c?.estimatedDuration ?? '1h 30m');
    _cropController =
        TextEditingController(text: c?.cropOrLivestock ?? '');
    _thumbnailUrlController =
        TextEditingController(text: c?.thumbnailUrl ?? '');
    _whatYouWillLearnController =
        TextEditingController(text: c?.whatYouWillLearn.join('\n') ?? '');
    _sourceController =
        TextEditingController(text: c?.agriculturalSource ?? '');
    _disclaimerController = TextEditingController(text: c?.disclaimer ?? '');
    _regionsController =
        TextEditingController(text: c?.targetRegions.join(', ') ?? '');
    _countriesController =
        TextEditingController(text: c?.targetCountries.join(', ') ?? '');
    _versionController = TextEditingController(text: c?.version ?? '1.0');

    if (c != null) {
      _categoryId = c.categoryId;
      _categoryName = c.categoryName;
      _difficulty = c.difficulty;
      _language = c.language;
      _status = c.status;
      _isFree = c.isFree;
      _isFeatured = c.isFeatured;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _fullDescController.dispose();
    _instructorController.dispose();
    _durationController.dispose();
    _cropController.dispose();
    _thumbnailUrlController.dispose();
    _whatYouWillLearnController.dispose();
    _sourceController.dispose();
    _disclaimerController.dispose();
    _regionsController.dispose();
    _countriesController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _pickedImage = file;
      _isUploadingThumbnail = true;
    });

    try {
      final uploadedUrl = await StorageRouterService.instance.uploadFile(
        file: file,
        folder: 'academy/courses',
      );

      if (mounted) {
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          setState(() {
            _thumbnailUrlController.text = uploadedUrl;
            _isUploadingThumbnail = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course thumbnail uploaded to MediaKit successfully! ✅'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _isUploadingThumbnail = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not upload image. Please try again or check connection.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingThumbnail = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading thumbnail: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? finalThumbnail = _thumbnailUrlController.text.trim();

      if (_pickedImage != null && finalThumbnail.isEmpty) {
        final uploaded = await StorageRouterService.instance.uploadFile(
          file: _pickedImage!,
          folder: 'academy/courses',
        );
        if (uploaded != null && uploaded.isNotEmpty) {
          finalThumbnail = uploaded;
        }
      }

      final learnList = _whatYouWillLearnController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final regions = _regionsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final countries = _countriesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final model = CourseModel(
        id: widget.course?.id ?? '',
        title: _titleController.text.trim(),
        shortDescription: _shortDescController.text.trim(),
        description: _fullDescController.text.trim(),
        categoryId: _categoryId,
        categoryName: _categoryName,
        difficulty: _difficulty,
        language: _language,
        thumbnailUrl: finalThumbnail.isNotEmpty ? finalThumbnail : null,
        instructorName: _instructorController.text.trim(),
        estimatedDuration: _durationController.text.trim(),
        isFree: _isFree,
        isFeatured: _isFeatured,
        status: _status,
        targetRegions: regions,
        targetCountries: countries,
        cropOrLivestock: _cropController.text.trim().isNotEmpty
            ? _cropController.text.trim()
            : null,
        whatYouWillLearn: learnList,
        agriculturalSource: _sourceController.text.trim().isNotEmpty
            ? _sourceController.text.trim()
            : null,
        disclaimer: _disclaimerController.text.trim().isNotEmpty
            ? _disclaimerController.text.trim()
            : null,
        version: _versionController.text.trim().isNotEmpty
            ? _versionController.text.trim()
            : '1.0',
        lastReviewedAt: DateTime.now(),
        lessonCount: widget.course?.lessonCount ?? 0,
        enrolledCount: widget.course?.enrolledCount ?? 0,
        completionCount: widget.course?.completionCount ?? 0,
        createdAt: widget.course?.createdAt,
        publishedAt: widget.course?.publishedAt,
      );

      if (widget.course == null) {
        await AcademyService.instance.createCourse(model);
      } else {
        await AcademyService.instance.updateCourse(model);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course saved successfully! ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving course: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.course == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Create Course' : 'Edit Course'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            tooltip: 'Save Course',
            onPressed: _isSaving ? null : _saveCourse,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Course Title *',
                  hintText: 'e.g. Tomato Farming for Beginners',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Short Description
              TextFormField(
                controller: _shortDescController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Short Summary / Teaser *',
                  hintText: 'Appears on course cards and search previews',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Full Description
              TextFormField(
                controller: _fullDescController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Full Description',
                  hintText: 'Detailed course overview and curriculum description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Category & Difficulty
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c['id'],
                          child: Text(c['name']!, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _categoryId = val;
                            _categoryName = _categories
                                .firstWhere((c) => c['id'] == val)['name']!;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Beginner', 'Intermediate', 'Advanced']
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _difficulty = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Crop/Livestock & Instructor
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cropController,
                      decoration: const InputDecoration(
                        labelText: 'Crop / Livestock Tag',
                        hintText: 'e.g. Tomato, Broiler',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _instructorController,
                      decoration: const InputDecoration(
                        labelText: 'Instructor / Author',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Duration & Language & Version
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        hintText: 'e.g. 2h 15m',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _versionController,
                      decoration: const InputDecoration(
                        labelText: 'Version',
                        hintText: '1.0',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['draft', 'review', 'published', 'archived']
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.toUpperCase(),
                                    style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Thumbnail Image Upload or URL
              if (_isUploadingThumbnail) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Uploading thumbnail to MediaKit / Image storage...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              TextFormField(
                controller: _thumbnailUrlController,
                decoration: InputDecoration(
                  labelText: 'Thumbnail Image URL',
                  hintText: 'https://...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.photo_library),
                    tooltip: 'Pick & Upload Image from Device',
                    onPressed: _isUploadingThumbnail ? null : _pickImage,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_thumbnailUrlController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _thumbnailUrlController.text.trim(),
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 28, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Thumbnail active and ready for course display ✅',
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ] else if (_pickedImage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_pickedImage!,
                          width: 80, height: 60, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    const Text('New image selected',
                        style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                ),
              ],
              const SizedBox(height: 14),

              // "What You Will Learn" (one per line)
              TextFormField(
                controller: _whatYouWillLearnController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'What You Will Learn (one point per line)',
                  hintText:
                      'Prepare a nursery\nAccurate plant spacing\nFertilizer schedule',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Target Regions & Target Countries
              TextFormField(
                controller: _regionsController,
                decoration: const InputDecoration(
                  labelText: 'Target Regions (comma separated)',
                  hintText: 'Southern Africa, East Africa, West Africa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _countriesController,
                decoration: const InputDecoration(
                  labelText: 'Target Countries (comma separated)',
                  hintText: 'Zimbabwe, South Africa, Zambia, Kenya, Nigeria',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Agricultural Source
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Agricultural Source / Research Institute',
                  hintText: 'e.g. Seed Co Guide / AGRITEX Extension',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Agricultural Disclaimer
              TextFormField(
                controller: _disclaimerController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Agricultural Disclaimer (Optional)',
                  hintText:
                      'AgriBase educational recommendations. Always consider local extension advice.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Switches
              SwitchListTile(
                title: const Text('Free Course'),
                subtitle: const Text('Accessible to all registered farmers'),
                value: _isFree,
                activeColor: Colors.green,
                onChanged: (val) => setState(() => _isFree = val),
              ),
              SwitchListTile(
                title: const Text('Featured Course'),
                subtitle: const Text('Display on Academy main carousel'),
                value: _isFeatured,
                activeColor: Colors.amber.shade800,
                onChanged: (val) => setState(() => _isFeatured = val),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isNew ? 'Create Course' : 'Save Changes',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSaving ? null : _saveCourse,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
