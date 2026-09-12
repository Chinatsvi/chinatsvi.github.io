import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ For clipboard
import 'package:flutter_markdown/flutter_markdown.dart';

class DiagnosisMessageBubble extends StatelessWidget {
  final String sender;
  final String? text;
  final String attachmentType;
  final String? attachmentUrl;
  final List<String> attachmentUrls;
  final List<File>? attachmentFiles;
  final File? localFile;
  final bool isFarmer;
  final DateTime? timestamp;
  final bool isSending;

  const DiagnosisMessageBubble({
    super.key,
    required this.sender,
    required this.text,
    required this.attachmentType,
    required this.attachmentUrl,
    this.attachmentUrls = const [],
    this.attachmentFiles,
    this.localFile,
    required this.isFarmer,
    this.timestamp,
    this.isSending = false,
  });

  Widget _buildImageItem({String? url, File? file}) {
    Widget imageWidget;
    if (file != null && file.existsSync()) {
      imageWidget = Image.file(
        file,
        fit: BoxFit.contain,
      );
    } else if (url != null && url.isNotEmpty) {
      imageWidget = Image.network(
        url,
        fit: BoxFit.contain,
        color: Colors.black12,
        colorBlendMode: BlendMode.dstOver,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return Container(
            width: 160,
            height: 120,
            color: Colors.grey.shade200,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.green[700],
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 100),
      );
    } else {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 160,
        maxHeight: 160,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alignment = isFarmer
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    // Gradient for message bubble
    final bubbleGradient = isFarmer
        ? const LinearGradient(colors: [Color(0xFFa8e063), Color(0xFF56ab2f)])
        : const LinearGradient(colors: [Color(0xFFe0e0e0), Color(0xFFcfcfcf)]);

    final textColor = isFarmer ? Colors.white : Colors.black87;

    final imageUrls = attachmentUrls.isNotEmpty
        ? attachmentUrls
        : (attachmentUrl?.isNotEmpty ?? false ? [attachmentUrl!] : <String>[]);
    final hasLocalFiles = (attachmentFiles != null && attachmentFiles!.isNotEmpty) ||
        (localFile != null && localFile!.existsSync());
    final hasImage = attachmentType == 'image' && (imageUrls.isNotEmpty || hasLocalFiles);
    final hasFile =
        attachmentType == 'file' && (attachmentUrl?.isNotEmpty ?? false);
    final hasText = text?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: bubbleGradient,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isFarmer ? 16 : 4),
              bottomRight: Radius.circular(isFarmer ? 4 : 16),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x42000000), // Black with 26% opacity
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: sender + copy button (only for assistant)
              if (!isFarmer)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sender,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.9),
                      ),
                    ),
                    if (hasText)
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.black54,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: text ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied!')),
                          );
                        },
                      ),
                  ],
                ),

              // Image attachment
              if (hasImage)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: () {
                      final items = <Widget>[];
                      if (attachmentFiles != null && attachmentFiles!.isNotEmpty) {
                        for (final f in attachmentFiles!) {
                          items.add(_buildImageItem(file: f));
                        }
                      } else if (localFile != null && localFile!.existsSync()) {
                        items.add(_buildImageItem(file: localFile));
                      } else {
                        for (final url in imageUrls) {
                          items.add(_buildImageItem(url: url));
                        }
                      }
                      return items;
                    }(),
                  ),
                ),

              // File attachment
              if (hasFile)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        size: 20,
                        color: Colors.yellowAccent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          attachmentUrl!.split('/').last,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Text message
              if (hasText)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: isFarmer
                      ? Text(
                          text!,
                          style: TextStyle(color: textColor, fontSize: 14),
                        )
                      : MarkdownBody(
                          data: text!,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                h1: TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                h2: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                h3: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                h4: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                strong: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                em: TextStyle(
                                  color: textColor,
                                  fontStyle: FontStyle.italic,
                                ),
                                blockquote: TextStyle(
                                  color: textColor.withValues(alpha: 0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                                listBullet: TextStyle(color: textColor),
                                code: TextStyle(
                                  backgroundColor: Colors.grey.withValues(
                                    alpha: 0.2,
                                  ),
                                  color: textColor,
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                          selectable: true,
                          onTapLink: (text, href, title) {
                            // Handle link taps if needed
                          },
                        ),
                ),

              // Timestamp & Sending status
              if (timestamp != null || isSending)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (timestamp != null)
                        Text(
                          '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor.withValues(
                              alpha: (textColor.a * 0.7).round() / 255,
                            ),
                          ),
                        ),
                      if (isSending) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: textColor.withValues(
                            alpha: (textColor.a * 0.7).round() / 255,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
