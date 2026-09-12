import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../models/academy/course_model.dart';
import '../../../models/academy/lesson_block_model.dart';
import '../../../models/academy/lesson_model.dart';
import '../../../models/academy/quiz_model.dart';
import '../../../services/academy/academy_service.dart';
import '../../../services/storage_router_service.dart';

class LessonBlockEditorScreen extends StatefulWidget {
  final CourseModel course;
  final LessonModel? lesson;

  const LessonBlockEditorScreen({
    super.key,
    required this.course,
    this.lesson,
  });

  @override
  State<LessonBlockEditorScreen> createState() =>
      _LessonBlockEditorScreenState();
}

class _LessonBlockEditorScreenState extends State<LessonBlockEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _durationController;
  late TextEditingController _sourcesController;

  List<LessonBlockModel> _blocks = [];
  bool _isSaving = false;

  // Media upload tracking
  final Map<String, bool> _uploadingBlocks = {};
  final Map<String, String?> _uploadErrors = {};
  final Map<String, String> _localMediaPreviews = {};

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    _titleController = TextEditingController(text: l?.title ?? '');
    _descController = TextEditingController(text: l?.description ?? '');
    _durationController =
        TextEditingController(text: l?.duration ?? '15 min');
    _sourcesController =
        TextEditingController(text: l?.sourcesAndReferences.join('\n') ?? '');

    if (l != null) {
      _blocks = List.from(l.blocks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _sourcesController.dispose();
    super.dispose();
  }

  // Media pick & background upload helpers
  Future<void> _pickAndUploadMedia(int index, {required bool isVideo}) async {
    final picker = ImagePicker();
    final picked = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final block = _blocks[index];
    final blockId = block.id;

    setState(() {
      _uploadingBlocks[blockId] = true;
      _uploadErrors[blockId] = null;
      _localMediaPreviews[blockId] = picked.path;
    });

    try {
      final file = File(picked.path);
      final url = await StorageRouterService.instance.uploadFile(
        file: file,
        isVideo: isVideo,
        folder: 'academy/lessons/${widget.course.id}',
      );

      if (url != null && url.isNotEmpty) {
        if (mounted) {
          setState(() {
            final idx = _blocks.indexWhere((b) => b.id == blockId);
            if (idx != -1) {
              _blocks[idx] = _blocks[idx].copyWith(mediaUrl: url);
            }
            _uploadingBlocks.remove(blockId);
            _uploadErrors.remove(blockId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isVideo ? "Video" : "Image"} uploaded successfully! ✅'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } else {
        throw Exception('Storage service returned empty URL');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingBlocks[blockId] = false;
          _uploadErrors[blockId] = 'Upload failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading ${isVideo ? "video" : "image"}: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // Block creation helpers
  void _addTextBlock() {
    setState(() {
      _blocks.add(
        LessonBlockModel(
          id: _uuid.v4(),
          type: LessonBlockType.text,
          order: _blocks.length,
          content: '### New Section\n\nEnter rich educational text here.',
        ),
      );
    });
  }

  void _addImageBlock() {
    final blockId = _uuid.v4();
    setState(() {
      _blocks.add(
        LessonBlockModel(
          id: blockId,
          type: LessonBlockType.image,
          order: _blocks.length,
          mediaUrl: '',
          caption: 'Figure: Field observation example',
        ),
      );
    });
    _pickAndUploadMedia(_blocks.length - 1, isVideo: false);
  }

  void _addVideoBlock() {
    final blockId = _uuid.v4();
    setState(() {
      _blocks.add(
        LessonBlockModel(
          id: blockId,
          type: LessonBlockType.video,
          order: _blocks.length,
          title: 'Field Demonstration Video',
          mediaUrl: '',
        ),
      );
    });
    _pickAndUploadMedia(_blocks.length - 1, isVideo: true);
  }

  void _addPdfBlock() {
    setState(() {
      _blocks.add(
        LessonBlockModel(
          id: _uuid.v4(),
          type: LessonBlockType.pdf,
          order: _blocks.length,
          title: 'Download Seed & Variety Guide',
          content: 'PDF Guide for offline study',
          mediaUrl: '',
        ),
      );
    });
  }

  void _addTipBlock() {
    setState(() {
      _blocks.add(
        LessonBlockModel(
          id: _uuid.v4(),
          type: LessonBlockType.tip,
          order: _blocks.length,
          title: '💡 FARMER TIP',
          content: 'Water early in the morning to minimize evaporative loss.',
        ),
      );
    });
  }

  void _addWarningBlock() {
    setState(() {
      _blocks.add(
        LessonBlockModel(
          id: _uuid.v4(),
          type: LessonBlockType.warning,
          order: _blocks.length,
          title: '⚠️ IMPORTANT WARNING',
          content: 'Do not apply pesticide spray during high winds or rain.',
        ),
      );
    });
  }

  void _addCalculatorBlock() {
    setState(() {
      _blocks.add(
        LessonBlockModel(
          id: _uuid.v4(),
          type: LessonBlockType.calculator,
          order: _blocks.length,
          title: 'Practical Field Tool',
          calculatorType: 'fertilizer',
          content: 'Calculate your field nutrient requirements.',
        ),
      );
    });
  }

  void _addLinkBlock() {
    setState(() {
      _blocks.add(
        LessonBlockModel(
          id: _uuid.v4(),
          type: LessonBlockType.link,
          order: _blocks.length,
          linkTitle: 'Official Ministry Agricultural Calendar',
          linkUrl: 'https://',
        ),
      );
    });
  }

  void _addQuizBlock() {
    final quizId = _uuid.v4();
    final quiz = QuizModel(
      id: quizId,
      title: 'Knowledge Check Quiz',
      description: 'Test what you learned in this lesson.',
      passPercentage: 70,
      questions: [
        QuizQuestionModel(
          id: _uuid.v4(),
          question: 'What is one key factor in seed nursery preparation?',
          options: [
            'Overwatering seeds daily',
            'Fine tilth and adequate drainage',
            'Planting in total darkness',
            'Using unsterilized soil',
          ],
          correctAnswerIndex: 1,
          explanation:
              'Fine tilth and good drainage allow delicate roots to penetrate easily without waterlogging.',
        ),
      ],
    );

    setState(() {
      _blocks.add(
        LessonBlockModel(
          id: quizId,
          type: LessonBlockType.quiz,
          order: _blocks.length,
          title: quiz.title,
          metadata: quiz.toMap(),
        ),
      );
    });
  }

  QuizModel _getQuizForBlock(LessonBlockModel block) {
    if (block.metadata != null) {
      final q = QuizModel.fromMap(block.metadata!, block.id);
      if (q.questions.isNotEmpty) return q;
    }
    return QuizModel(
      id: block.id,
      title: block.title ?? 'Knowledge Check Quiz',
      description: 'Test what you learned in this lesson.',
      passPercentage: 70,
      questions: [
        QuizQuestionModel(
          id: _uuid.v4(),
          question: '',
          options: ['', '', '', ''],
          correctAnswerIndex: 0,
          explanation: '',
        ),
      ],
    );
  }

  void _updateQuizForBlock(int blockIndex, QuizModel quiz) {
    setState(() {
      _blocks[blockIndex] = _blocks[blockIndex].copyWith(
        title: quiz.title,
        metadata: quiz.toMap(),
      );
    });
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final sources = _sourcesController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Normalize orders
      for (int i = 0; i < _blocks.length; i++) {
        _blocks[i] = _blocks[i].copyWith(order: i);
      }

      final lessonModel = LessonModel(
        id: widget.lesson?.id ?? '',
        courseId: widget.course.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        duration: _durationController.text.trim(),
        order: widget.lesson?.order ?? 0,
        blocks: _blocks,
        sourcesAndReferences: sources,
        createdAt: widget.lesson?.createdAt,
      );

      await AcademyService.instance.saveLesson(lessonModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson saved successfully! ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving lesson: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson == null ? 'New Lesson' : 'Edit Lesson'),
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
            tooltip: 'Save Lesson',
            onPressed: _isSaving ? null : _saveLesson,
          ),
        ],
      ),
      bottomNavigationBar: _buildAddBlockToolbar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lesson Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Lesson Title *',
                  hintText: 'e.g. Lesson 1 — Variety Selection & Nursery',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Short Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        hintText: '15 min',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Block section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Content Blocks (${_blocks.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade900,
                    ),
                  ),
                  const Text(
                    'Use toolbar below to add blocks',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Reorderable blocks
              if (_blocks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No content blocks added yet.\nTap a button in the toolbar below to add Text, Image, Video, Tip, Warning, Calculator, or Quiz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...List.generate(_blocks.length, (index) {
                  return _buildBlockEditorCard(index);
                }),

              const SizedBox(height: 24),

              // Sources and references
              TextFormField(
                controller: _sourcesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Sources & References (one per line)',
                  hintText:
                      'Department of Agricultural Research (AGRITEX)\nSeed Co Horticultural Guide',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddBlockToolbar() {
    return Container(
      color: Colors.purple.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolbarButton('+ Text', Icons.text_fields, _addTextBlock),
            _toolbarButton('+ Image', Icons.image, _addImageBlock),
            _toolbarButton('+ Video', Icons.videocam, _addVideoBlock),
            _toolbarButton('+ Tip', Icons.lightbulb, _addTipBlock),
            _toolbarButton('+ Warning', Icons.warning, _addWarningBlock),
            _toolbarButton('+ Calculator', Icons.calculate, _addCalculatorBlock),
            _toolbarButton('+ Quiz', Icons.quiz, _addQuizBlock),
            _toolbarButton('+ PDF', Icons.picture_as_pdf, _addPdfBlock),
            _toolbarButton('+ Link', Icons.link, _addLinkBlock),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBlockEditorCard(int index) {
    final block = _blocks[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.purple.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Block header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${index + 1} ${block.type.name.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.purple.shade900,
                    ),
                  ),
                ),
                const Spacer(),
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    onPressed: () {
                      setState(() {
                        final item = _blocks.removeAt(index);
                        _blocks.insert(index - 1, item);
                      });
                    },
                  ),
                if (index < _blocks.length - 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    onPressed: () {
                      setState(() {
                        final item = _blocks.removeAt(index);
                        _blocks.insert(index + 1, item);
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () {
                    setState(() {
                      _blocks.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Field inputs based on block type
            if (block.type == LessonBlockType.text) ...[
              TextFormField(
                initialValue: block.content,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Text Content (Markdown supported)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(content: val);
                },
              ),
            ] else if (block.type == LessonBlockType.image) ...[
              // Upload status / local preview
              if (_uploadingBlocks[block.id] == true) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Uploading image to media storage in background...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_uploadErrors[block.id] != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploadErrors[block.id]!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _pickAndUploadMedia(index, isVideo: false),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('img_${block.id}'),
                      initialValue: block.mediaUrl,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        _blocks[index] = block.copyWith(mediaUrl: val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Upload', style: TextStyle(fontSize: 12)),
                    onPressed: () => _pickAndUploadMedia(index, isVideo: false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: ValueKey('cap_${block.id}'),
                initialValue: block.caption,
                decoration: const InputDecoration(
                  labelText: 'Image Caption',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(caption: val);
                },
              ),
            ] else if (block.type == LessonBlockType.video) ...[
              // Upload status / local preview
              if (_uploadingBlocks[block.id] == true) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Uploading video to media storage in background...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_uploadErrors[block.id] != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploadErrors[block.id]!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _pickAndUploadMedia(index, isVideo: true),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
              TextFormField(
                key: ValueKey('vid_t_${block.id}'),
                initialValue: block.title,
                decoration: const InputDecoration(
                  labelText: 'Video Title',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(title: val);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('vid_${block.id}'),
                      initialValue: block.mediaUrl,
                      decoration: const InputDecoration(
                        labelText: 'Video URL (MP4 / Stream)',
                        hintText: 'https://...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        _blocks[index] = block.copyWith(mediaUrl: val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    icon: const Icon(Icons.videocam, size: 18),
                    label: const Text('Upload', style: TextStyle(fontSize: 12)),
                    onPressed: () => _pickAndUploadMedia(index, isVideo: true),
                  ),
                ],
              ),
            ] else if (block.type == LessonBlockType.tip) ...[
              TextFormField(
                initialValue: block.title ?? '💡 FARMER TIP',
                decoration: const InputDecoration(
                  labelText: 'Tip Title',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(title: val);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: block.content,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Tip Text',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(content: val);
                },
              ),
            ] else if (block.type == LessonBlockType.warning) ...[
              TextFormField(
                initialValue: block.title ?? '⚠️ IMPORTANT WARNING',
                decoration: const InputDecoration(
                  labelText: 'Warning Title',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(title: val);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: block.content,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Warning Text',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(content: val);
                },
              ),
            ] else if (block.type == LessonBlockType.calculator) ...[
              DropdownButtonFormField<String>(
                value: block.calculatorType ?? 'fertilizer',
                decoration: const InputDecoration(
                  labelText: 'Calculator Link Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'fertilizer', child: Text('Fertilizer Calculator')),
                  DropdownMenuItem(
                      value: 'irrigation', child: Text('Irrigation Calculator')),
                  DropdownMenuItem(
                      value: 'profit', child: Text('Farm Profit Calculator')),
                  DropdownMenuItem(
                      value: 'break_even', child: Text('Break-Even Calculator')),
                  DropdownMenuItem(
                      value: 'population', child: Text('Plant Population Calculator')),
                  DropdownMenuItem(
                      value: 'spacing', child: Text('Spacing Calculator')),
                ],
                onChanged: (val) {
                  _blocks[index] = block.copyWith(calculatorType: val);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: block.content,
                decoration: const InputDecoration(
                  labelText: 'Prompt / Instruction Text',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(content: val);
                },
              ),
            ] else if (block.type == LessonBlockType.link) ...[
              TextFormField(
                initialValue: block.linkTitle,
                decoration: const InputDecoration(
                  labelText: 'Link Title / Resource Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(linkTitle: val);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: block.linkUrl,
                decoration: const InputDecoration(
                  labelText: 'Resource URL',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(linkUrl: val);
                },
              ),
            ] else if (block.type == LessonBlockType.pdf) ...[
              TextFormField(
                initialValue: block.title,
                decoration: const InputDecoration(
                  labelText: 'PDF Title',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(title: val);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: block.mediaUrl,
                decoration: const InputDecoration(
                  labelText: 'PDF Download URL',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  _blocks[index] = block.copyWith(mediaUrl: val);
                },
              ),
            ] else if (block.type == LessonBlockType.quiz) ...[
              _buildQuizBlockEditor(index, block),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuizBlockEditor(int blockIndex, LessonBlockModel block) {
    final quiz = _getQuizForBlock(block);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quiz Header Settings
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                key: ValueKey('qz_t_${block.id}'),
                initialValue: quiz.title,
                decoration: const InputDecoration(
                  labelText: 'Quiz Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.quiz, color: Colors.purple),
                ),
                onChanged: (val) {
                  _updateQuizForBlock(blockIndex, quiz.copyWith(title: val));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                key: ValueKey('qz_p_${block.id}'),
                initialValue: quiz.passPercentage.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pass %',
                  hintText: '70',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final pass = int.tryParse(val) ?? 70;
                  _updateQuizForBlock(blockIndex, quiz.copyWith(passPercentage: pass));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('qz_d_${block.id}'),
          initialValue: quiz.description,
          decoration: const InputDecoration(
            labelText: 'Quiz Description / Instructions',
            hintText: 'e.g. Test what you learned in this lesson.',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            _updateQuizForBlock(blockIndex, quiz.copyWith(description: val));
          },
        ),
        const SizedBox(height: 14),

        // Questions Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions (${quiz.questions.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.purple.shade900,
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('+ Add Question', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                final newQuestions = List<QuizQuestionModel>.from(quiz.questions);
                newQuestions.add(
                  QuizQuestionModel(
                    id: _uuid.v4(),
                    question: '',
                    options: ['', '', '', ''],
                    correctAnswerIndex: 0,
                    explanation: '',
                  ),
                );
                _updateQuizForBlock(blockIndex, quiz.copyWith(questions: newQuestions));
              },
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Questions List
        if (quiz.questions.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  final newQuestions = [
                    QuizQuestionModel(
                      id: _uuid.v4(),
                      question: '',
                      options: ['', '', '', ''],
                      correctAnswerIndex: 0,
                      explanation: '',
                    ),
                  ];
                  _updateQuizForBlock(blockIndex, quiz.copyWith(questions: newQuestions));
                },
                icon: const Icon(Icons.add),
                label: const Text('Add First Question'),
              ),
            ),
          ),
        ] else ...[
          ...List.generate(quiz.questions.length, (qIdx) {
            final q = quiz.questions[qIdx];
            return Container(
              key: ValueKey('qz_q_${q.id}'),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Header & Actions
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Q${qIdx + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Question #${qIdx + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade900,
                        ),
                      ),
                      const Spacer(),
                      if (qIdx > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          tooltip: 'Move Up',
                          onPressed: () {
                            final questions = List<QuizQuestionModel>.from(quiz.questions);
                            final item = questions.removeAt(qIdx);
                            questions.insert(qIdx - 1, item);
                            _updateQuizForBlock(blockIndex, quiz.copyWith(questions: questions));
                          },
                        ),
                      if (qIdx < quiz.questions.length - 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          tooltip: 'Move Down',
                          onPressed: () {
                            final questions = List<QuizQuestionModel>.from(quiz.questions);
                            final item = questions.removeAt(qIdx);
                            questions.insert(qIdx + 1, item);
                            _updateQuizForBlock(blockIndex, quiz.copyWith(questions: questions));
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        tooltip: 'Delete Question',
                        onPressed: () {
                          final questions = List<QuizQuestionModel>.from(quiz.questions);
                          questions.removeAt(qIdx);
                          _updateQuizForBlock(blockIndex, quiz.copyWith(questions: questions));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Question Text
                  TextFormField(
                    key: ValueKey('q_text_${q.id}'),
                    initialValue: q.question,
                    decoration: const InputDecoration(
                      labelText: 'Question Text *',
                      hintText: 'e.g. What is the optimal soil pH for tomatoes?',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) {
                      final questions = List<QuizQuestionModel>.from(quiz.questions);
                      questions[qIdx] = questions[qIdx].copyWith(question: val);
                      _updateQuizForBlock(blockIndex, quiz.copyWith(questions: questions));
                    },
                  ),
                  const SizedBox(height: 10),

                  // Options Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Options (Select the correct answer radio):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      if (q.options.length < 6)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Option', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final questions = List<QuizQuestionModel>.from(quiz.questions);
                            final newOpts = List<String>.from(q.options)..add('');
                            questions[qIdx] = questions[qIdx].copyWith(options: newOpts);
                            _updateQuizForBlock(blockIndex, quiz.copyWith(questions: questions));
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Options List
                  ...List.generate(q.options.length, (optIdx) {
                    final isCorrect = q.correctAnswerIndex == optIdx;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: optIdx,
                            groupValue: q.correctAnswerIndex,
                            activeColor: Colors.purple.shade800,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              if (val != null) {
                                final questions = List<QuizQuestionModel>.from(quiz.questions);
                                questions[qIdx] = questions[qIdx].copyWith(correctAnswerIndex: val);
                                _updateQuizForBlock(blockIndex, quiz.copyWith(questions: questions));
                              }
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('opt_${q.id}_$optIdx'),
                              initialValue: q.options[optIdx],
                              decoration: InputDecoration(
                                labelText: 'Option ${String.fromCharCode(65 + optIdx)}${isCorrect ? " (Correct Answer)" : ""}',
                                filled: true,
                                fillColor: isCorrect ? Colors.green.shade50 : Colors.white,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isCorrect ? Colors.green.shade700 : Colors.grey.shade400,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              onChanged: (val) {
                                final questions = List<QuizQuestionModel>.from(quiz.questions);
                                final opts = List<String>.from(questions[qIdx].options);
                                opts[optIdx] = val;
                                questions[qIdx] = questions[qIdx].copyWith(options: opts);
                                _updateQuizForBlock(blockIndex, quiz.copyWith(questions: questions));
                              },
                            ),
                          ),
                          if (q.options.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 18),
                              padding: const EdgeInsets.only(left: 4),
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              tooltip: 'Remove Option',
                              onPressed: () {
                                final questions = List<QuizQuestionModel>.from(quiz.questions);
                                final opts = List<String>.from(questions[qIdx].options)..removeAt(optIdx);
                                final currentCorrect = questions[qIdx].correctAnswerIndex;
                                final newCorrect = currentCorrect >= opts.length
                                    ? 0
                                    : (currentCorrect > optIdx ? currentCorrect - 1 : currentCorrect);
                                questions[qIdx] = questions[qIdx].copyWith(options: opts, correctAnswerIndex: newCorrect);
                                _updateQuizForBlock(blockIndex, quiz.copyWith(questions: questions));
                              },
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 6),

                  // Explanation Field
                  TextFormField(
                    key: ValueKey('exp_${q.id}'),
                    initialValue: q.explanation,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Explanation (Optional, shown after answer)',
                      hintText: 'e.g. Tomatoes grow best in slightly acidic soil (pH 6.0 - 6.8).',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) {
                      final questions = List<QuizQuestionModel>.from(quiz.questions);
                      questions[qIdx] = questions[qIdx].copyWith(explanation: val);
                      _updateQuizForBlock(blockIndex, quiz.copyWith(questions: questions));
                    },
                  ),
                ],
              ),
            );
          }),

          // Add Question Button at the bottom
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple.shade900,
                side: BorderSide(color: Colors.purple.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Add Another Question'),
              onPressed: () {
                final newQuestions = List<QuizQuestionModel>.from(quiz.questions);
                newQuestions.add(
                  QuizQuestionModel(
                    id: _uuid.v4(),
                    question: '',
                    options: ['', '', '', ''],
                    correctAnswerIndex: 0,
                    explanation: '',
                  ),
                );
                _updateQuizForBlock(blockIndex, quiz.copyWith(questions: newQuestions));
              },
            ),
          ),
        ],
      ],
    );
  }
}
