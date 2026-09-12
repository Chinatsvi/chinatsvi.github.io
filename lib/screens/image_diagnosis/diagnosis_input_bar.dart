import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/enhanced_ai_service.dart';
import '../../services/storage_router_service.dart';

import 'previous_chats_screen.dart';
import 'diagnosis_chat_screen.dart';

class DiagnosisInputBar extends StatefulWidget {
  final String chatId;
  final String sender;
  final Future<void> Function(
    String text, {
    File? attachment,
    List<File>? attachments,
    String? attachmentType,
    String? attachmentUrl,
    List<String>? attachmentUrls,
  })
  onSend;

  final TextEditingController? textController;
  final FocusNode? focusNode;

  const DiagnosisInputBar({
    super.key,
    required this.chatId,
    required this.sender,
    required this.onSend,
    this.textController,
    this.focusNode,
  });

  @override
  State<DiagnosisInputBar> createState() => _DiagnosisInputBarState();
}

class _DiagnosisInputBarState extends State<DiagnosisInputBar> {
  late TextEditingController textController;
  late FocusNode _focusNode;

  final List<File> attachmentFiles = [];
  String? attachmentType;
  bool isUploadingRemote = false;
  final List<String> uploadedMediaUrls = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    textController = widget.textController ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (widget.textController == null) {
      textController.dispose();
    }

    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final scaffold = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final picked = await ImagePicker().pickImage(source: source);
    if (!mounted) return;

    if (picked == null) {
      navigator.pop();
      return;
    }

    final rateInfo = await EnhancedAiService.instance.getRateLimitInfo();
    final remaining = rateInfo['remaining'] as int;
    const uploadCost = 5; // Each upload costs 5 requests

    final hasEnoughRequests =
        remaining >= uploadCost || rateInfo['unlimited'] == true;

    if (!hasEnoughRequests) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            '📁 Image upload requires 5 points ($remaining available). Watch ads to add points or Get Pro for unlimited!',
          ),
          backgroundColor: Colors.green[800],
          duration: const Duration(seconds: 4),
        ),
      );
      navigator.pop();
      return;
    }

    setState(() {
      attachmentFiles.add(File(picked.path));
      attachmentType = 'image';
      isUploadingRemote = true;
    });

    navigator.pop();

    // Track usage for upload and start auto-upload in background
    try {
      await EnhancedAiService.instance.trackUsage(isUpload: true);
    } catch (e) {
      debugPrint('Failed to track usage before upload: $e');
    }

    try {
      final url = await StorageRouterService.instance.uploadPostMedia(
        file: File(picked.path),
        userId: widget.sender,
        mediaType: 'image',
      );
      if (!mounted) return;
      setState(() {
        if (url.isNotEmpty) uploadedMediaUrls.add(url);
        isUploadingRemote = false;
      });
    } catch (e) {
      // Refund usage if upload failed
      await EnhancedAiService.instance.refundUsage(isUpload: true);
      if (!mounted) return;
      setState(() {
        isUploadingRemote = false;
      });
      scaffold.showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    }
  }

  Future<void> pickFile() async {
    final scaffold = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await FilePicker.pickFiles();
    if (!mounted) return;

    if (result != null) {
      final rateInfo = await EnhancedAiService.instance.getRateLimitInfo();
      final remaining = rateInfo['remaining'] as int;
      const uploadCost = 5; // Each upload costs 5 requests

      final hasEnoughRequests =
          remaining >= uploadCost || rateInfo['unlimited'] == true;

      if (!hasEnoughRequests) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text(
              '📁 File upload requires 5 points ($remaining available). Watch ads to add points or Get Pro for unlimited!',
            ),
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 4),
          ),
        );
        navigator.pop();
        return;
      }

      setState(() {
        attachmentFiles.add(File(result.files.single.path!));
        attachmentType = 'file';
      });
    }

    navigator.pop();
  }

  Future<void> sendMessage() async {
    final scaffold = ScaffoldMessenger.of(context);
    final text = textController.text.trim();

    if (text.isEmpty && attachmentFiles.isEmpty) return;
    if (isUploadingRemote) {
      return;
    }

    final clearedText = text;
    final tempAttachments = List<File>.from(attachmentFiles);
    final tempAttachmentType = attachmentType;
    final tempAttachmentUrls = List<String>.from(uploadedMediaUrls);

    // ✅ Clear text input and attachment preview immediately so the message
    // disappears from the input bar and moves directly into the chat bubble.
    textController.clear();
    _focusNode.unfocus();

    setState(() {
      attachmentFiles.clear();
      attachmentType = null;
      uploadedMediaUrls.clear();
    });

    try {
      await widget.onSend(
        clearedText,
        attachment: tempAttachments.isNotEmpty ? tempAttachments.first : null,
        attachments: tempAttachments,
        attachmentType: tempAttachmentType,
        attachmentUrl: tempAttachmentUrls.isNotEmpty
            ? tempAttachmentUrls.first
            : null,
        attachmentUrls: tempAttachmentUrls,
      );
    } catch (e) {
      if (mounted) {
        textController.text = clearedText;

        setState(() {
          attachmentFiles
            ..clear()
            ..addAll(tempAttachments);
          attachmentType = tempAttachmentType;
          uploadedMediaUrls
            ..clear()
            ..addAll(tempAttachmentUrls);
        });

        scaffold.showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }

    // Don't request focus to allow keyboard to stay dismissed for better chat view
  }

  Widget buildAttachmentPreview() {
    if (attachmentFiles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachmentFiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    attachmentFiles[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      attachmentFiles.removeAt(index);
                      if (index < uploadedMediaUrls.length) {
                        uploadedMediaUrls.removeAt(index);
                      }
                      if (attachmentFiles.isEmpty) attachmentType = null;
                    });
                  },
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
              if (isUploadingRemote && index == attachmentFiles.length - 1)
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.center,
                    color: Colors.black.withOpacity(0.25),
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget buildAttachmentButton() {
    return Material(
      color: Colors.grey[200],
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.attach_file, color: Colors.green),
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Upload from Gallery'),
                onTap: () => pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Upload File'),
                onTap: pickFile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextInput() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: textController,
          focusNode: _focusNode,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.send,
          decoration: const InputDecoration(
            hintText: 'Describe your issue...',
            border: InputBorder.none,
          ),
          onSubmitted: (_) => sendMessage(),
        ),
      ),
    );
  }

  Widget buildSendButton() {
    final hasUnuploadedImage = attachmentType == 'image' && isUploadingRemote;
    final canSend = !isLoading && !hasUnuploadedImage;

    return Material(
      color: canSend ? Colors.green : Colors.grey,
      shape: const CircleBorder(),
      child: IconButton(
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send, color: Colors.white),
        onPressed: canSend ? sendMessage : null,
      ),
    );
  }

  Widget buildNavigationButtons() {
    final hasInput =
        textController.text.trim().isNotEmpty || attachmentFiles.isNotEmpty;

    if (hasInput) {
      return buildSendButton();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.blue,
          shape: const CircleBorder(),
          child: SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: const Text(
                'N',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () async {
                final chatId = const Uuid().v4();

                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .set({
                      'chat_id': chatId,
                      'sender': widget.sender,
                      'type': 'diagnosis',
                      'timestamp': FieldValue.serverTimestamp(),
                      'last_message': '',
                      'title': '',
                    });

                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiagnosisChatScreen(
                        chatId: chatId,
                        sender: widget.sender,
                      ),
                    ),
                  );
                }
              },
              tooltip: 'New Chat',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Material(
          color: Colors.orange,
          shape: const CircleBorder(),
          child: SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: const Icon(Icons.history, color: Colors.white, size: 16),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PreviousChatsScreen(),
                  ),
                );
              },
              tooltip: 'Previous Chat',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (attachmentFiles.isNotEmpty) ...[
                Center(child: buildAttachmentPreview()),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  if (!isUploadingRemote) buildAttachmentButton(),
                  const SizedBox(width: 4),
                  buildTextInput(),
                  const SizedBox(width: 4),
                  buildNavigationButtons(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
