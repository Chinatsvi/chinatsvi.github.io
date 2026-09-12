import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/smart_moderation_service.dart';

class ReportPostDialog extends StatefulWidget {
  final String postId;
  final String postAuthorId;
  final String postAuthorName;

  const ReportPostDialog({
    required this.postId,
    required this.postAuthorId,
    required this.postAuthorName,
  });

  static void show(
    BuildContext context, {
    required String postId,
    required String postAuthorId,
    required String postAuthorName,
  }) {
    showDialog(
      context: context,
      builder: (_) => ReportPostDialog(
        postId: postId,
        postAuthorId: postAuthorId,
        postAuthorName: postAuthorName,
      ),
    );
  }

  @override
  State<ReportPostDialog> createState() => _ReportPostDialogState();
}

class _ReportPostDialogState extends State<ReportPostDialog> {
  late String _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Sexual or nude content',
    'Hateful or abusive content',
    'Violent or harmful content',
    'Spam or misleading',
    'Harassment or bullying',
    'Misinformation',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasons.first;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Description Required',
        'Please provide details about why you\'re reporting this post',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await SmartModerationService.reportPost(
        postId: widget.postId,
        postAuthorId: widget.postAuthorId,
        postAuthorName: widget.postAuthorName,
        reportReason: _selectedReason,
        description: _descriptionController.text.trim(),
      );

      Get.back(); // Close dialog

      Get.snackbar(
        'Report Submitted',
        'Thank you! This post has been hidden from the feed pending review.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit report: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us keep the community safe. Why are you reporting this post?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedReason,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedReason = value);
                }
              },
              items: _reasons
                  .map((reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Provide more details (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: False reports may result in penalties. Please only report actual violations.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}

/// Show appeal dialog for removed posts
class AppealRemovalDialog extends StatefulWidget {
  final String postId;

  const AppealRemovalDialog({required this.postId});

  static void show(BuildContext context, {required String postId}) {
    showDialog(
      context: context,
      builder: (_) => AppealRemovalDialog(postId: postId),
    );
  }

  @override
  State<AppealRemovalDialog> createState() => _AppealRemovalDialogState();
}

class _AppealRemovalDialogState extends State<AppealRemovalDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitAppeal() async {
    if (_reasonController.text.trim().isEmpty) {
      Get.snackbar(
        'Required',
        'Please explain why you believe this is an error',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await SmartModerationService.appealRemoval(
        postId: widget.postId,
        reason: _reasonController.text.trim(),
      );

      Get.back();

      Get.snackbar(
        'Appeal Submitted',
        'Our team will review your appeal within 24-48 hours.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit appeal: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Appeal Post Removal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If you believe your post was removed by mistake, explain why below:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              minLines: 4,
              decoration: InputDecoration(
                hintText: 'Explain why this should not have been removed...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Our admin team will review your appeal and get back to you within 24-48 hours.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitAppeal,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit Appeal'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
