import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agribased/screens/profile/farmer_profile_screen.dart';
import 'package:agribased/utils/verification_helpers.dart';
import 'package:agribased/widgets/user_info_display.dart';
import 'package:agribased/widgets/stable_follow_button.dart';
import 'package:agribased/services/comment_service.dart';
import 'package:agribased/services/moderation_service.dart';
import 'package:agribased/screens/community/report_comment_page.dart';
import '../utils/time_formatter.dart';

/// Fire-and-forget helper for non-blocking operations
void unawaited(Future<void> future) {
  // Intentionally not awaiting - fire and forget
}

class CommentSection extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String? profileOwnerId;
  final Function(String commentId, Map<String, dynamic> commentData)? onEdit;
  final Function(String commentId, Map<String, dynamic> commentData)? onDelete;
  final Function(String replyId, Map<String, dynamic> replyData)? onEditReply;
  final Function(String replyId, Map<String, dynamic> replyData)? onDeleteReply;
  final VoidCallback? onCommentChanged; // Callback when comments are added/deleted
  final int? initialCommentsCount; // Cached comment count from post analytics
  final String? highlightedCommentId; // ID of comment to highlight
  final String? highlightedReplyId; // ID of reply to highlight

  const CommentSection({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.profileOwnerId,
    this.onEdit,
    this.onDelete,
    this.onEditReply,
    this.onDeleteReply,
    this.onCommentChanged,
    this.initialCommentsCount,
    this.highlightedCommentId,
    this.highlightedReplyId,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, bool> _showReplyBox = {};
  final Map<String, bool> _showRepliesForComment = {};
  final Map<String, bool> _expandedComments = {};
  final Map<String, bool> _expandedRepliesText = {};

  bool _isSendingComment = false;
  final Map<String, bool> _isSendingReply = {};

  // Inline editing state
  final TextEditingController _editCommentController = TextEditingController();
  final Map<String, TextEditingController> _editReplyControllers = {};
  String? _editingCommentId;
  String? _editingReplyId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(CommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Force rebuild when postId changes to refresh comments and replies
    if (oldWidget.postId != widget.postId) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editCommentController.dispose();
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }

    // Dispose all edit reply controllers
    for (final controller in _editReplyControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FarmerProfileScreen(
          userId: userId,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  /// Launch external web links clicked in comments
  Future<void> _launchExternalUrl(String url) async {
    try {
      String formattedUrl = url.trim();
      if (!formattedUrl.startsWith('http://') &&
          !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }
      final uri = Uri.parse(formattedUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      developer.log('Error launching URL $url: $e', name: 'CommentSection');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Parses text into clickable link spans and standard text spans
  List<InlineSpan> _buildTextSpansWithLinks(
    String text,
    TextStyle defaultStyle,
  ) {
    final List<InlineSpan> spans = [];
    final urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+|www\.[^\s]+)',
      caseSensitive: false,
    );

    int lastMatchEnd = 0;
    for (final match in urlRegExp.allMatches(text)) {
      // Add text leading up to URL
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: defaultStyle,
          ),
        );
      }

      final rawUrl = match.group(0) ?? '';
      String cleanUrl = rawUrl;
      String trailingPunctuation = '';

      // Strip trailing punctuation so sentence-ending periods aren't part of URL
      while (cleanUrl.isNotEmpty &&
          (cleanUrl.endsWith('.') ||
              cleanUrl.endsWith(',') ||
              cleanUrl.endsWith('!') ||
              cleanUrl.endsWith('?') ||
              cleanUrl.endsWith(')'))) {
        trailingPunctuation = cleanUrl[cleanUrl.length - 1] + trailingPunctuation;
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => _launchExternalUrl(cleanUrl),
            child: Text(
              cleanUrl,
              style: defaultStyle.copyWith(
                color: Colors.blue.shade700,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );

      if (trailingPunctuation.isNotEmpty) {
        spans.add(
          TextSpan(
            text: trailingPunctuation,
            style: defaultStyle,
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    // Add trailing text after last URL
    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: defaultStyle,
        ),
      );
    }

    return spans;
  }

  bool _isPaymentExpired(dynamic paidAt) {
    return isVerificationPaymentExpired(paidAt);
  }

  bool _shouldShowVerifiedTick(Map<String, dynamic>? farmerData) {
    return shouldShowVerificationTick(farmerData);
  }

  Widget _buildVerifiedTick(
    String userId,
    bool fallbackVerified, {
    double size = 16,
  }) {
    if (userId.trim().isEmpty) return const SizedBox.shrink();
    // Always use real-time data from Firestore for verification status
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final bool isVerified = _shouldShowVerifiedTick(data);

        if (!isVerified) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Image.asset(
            'assets/icon/verification_tick.png',
            width: size,
            height: size,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.verified, size: size, color: Colors.blue);
            },
          ),
        );
      },
    );
  }

  Widget _buildCommentVerifiedTick(
    String userId,
    bool storedVerified, {
    double size = 16,
  }) {
    if (userId.trim().isEmpty) return const SizedBox.shrink();
    // Always use real-time data from Firestore for verification status
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final bool isVerified = _shouldShowVerifiedTick(data);

        if (!isVerified) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Image.asset(
            'assets/icon/verification_tick.png',
            width: size,
            height: size,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.verified, size: size, color: Colors.blue);
            },
          ),
        );
      },
    );
  }

  /// Collapsible text helper with clickable links and green "Read more..." / "Read less"
  Widget _buildExpandableText({
    required String text,
    required int maxLength,
    required bool isExpanded,
    required VoidCallback onToggle,
    TextStyle? style,
  }) {
    final effectiveStyle =
        style ?? const TextStyle(fontSize: 14, color: Colors.black87);

    if (text.length <= maxLength) {
      return Text.rich(
        TextSpan(
          children: _buildTextSpansWithLinks(text, effectiveStyle),
        ),
      );
    }

    final displayText =
        isExpanded ? text : text.substring(0, maxLength).trimRight();

    final List<InlineSpan> contentSpans =
        _buildTextSpansWithLinks(displayText, effectiveStyle);

    return Text.rich(
      TextSpan(
        children: [
          ...contentSpans,
          if (!isExpanded)
            TextSpan(
              text: '... ',
              style: effectiveStyle,
            ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  isExpanded ? 'Read less' : 'Read more...',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (_isSendingComment) return;
    setState(() => _isSendingComment = true);

    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.currentUserId)
          .get();

      final currentUserData = currentUserDoc.data();
      final currentUserName = currentUserData?['user_name'] ?? 'Farmer';
      final currentUserProfile = currentUserData?['profile_pic'] ?? '';
      final bool showVerified = _shouldShowVerifiedTick(currentUserData);

      await CommentService().addComment(
        postId: widget.postId,
        authorId: widget.currentUserId,
        authorName: currentUserName,
        authorProfilePic: currentUserProfile,
        authorVerified: showVerified,
        content: text,
      );

      if (!mounted) return;
      widget.onCommentChanged?.call();
      FocusScope.of(context).unfocus();
      _commentController.clear();
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to send comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingComment = false);
      }
    }
  }

  Future<void> _sendReply(String commentId, String replyText) async {
    if (replyText.trim().isEmpty) return;

    if (_isSendingReply[commentId] == true) return;
    setState(() => _isSendingReply[commentId] = true);

    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.currentUserId)
          .get();

      final currentUserData = currentUserDoc.data();
      final currentUserName = currentUserData?['user_name'] ?? 'Farmer';
      final currentUserProfile = currentUserData?['profile_pic'] ?? '';
      final bool showVerified = _shouldShowVerifiedTick(currentUserData);

      final replyRef = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .add({
            'userId': widget.currentUserId,
            'user_name': currentUserName,
            'author_verified': showVerified,
            'profile_pic': currentUserProfile,
            'text': replyText.trim(),
            'created_at': Timestamp.now(),
          });

      await replyRef.update({
        'text': replyText.trim(),
        'created_at': Timestamp.now(),
      });

      // Run moderation after reply creation (fire-and-forget to avoid blocking)
      unawaited(
        _runReplyModerationCheck(
          replyText.trim(),
          replyRef.id,
          widget.currentUserId,
        ),
      );

      _replyControllers[commentId]?.clear();
      if (!mounted) return;
      widget.onCommentChanged?.call();
      FocusScope.of(context).unfocus();
      setState(() {
        _showReplyBox[commentId] = false;
        _showRepliesForComment[commentId] = true; // Automatically expand replies to view newly added reply
      });
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to send reply: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingReply[commentId] = false);
      }
    }
  }

  /// Run moderation check for replies in background without blocking
  Future<void> _runReplyModerationCheck(
    String replyText,
    String replyId,
    String userId,
  ) async {
    try {
      await ModerationService.checkContent(
        text: replyText,
        postId: replyId,
        userId: userId,
      );
      developer.log(
        '✅ Reply moderation completed for $replyId',
        name: 'CommentSection',
      );
    } catch (e) {
      developer.log(
        '❌ Reply moderation failed for $replyId: $e',
        name: 'CommentSection',
      );
      // Reply remains even if moderation fails
    }
  }

  void _showCommentNonOwnerOptions({
    required String commentId,
    required String authorId,
    required String authorName,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text('Report'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _navigateToReportPage(
                    contentId: commentId,
                    authorId: authorId,
                    authorName: authorName,
                    content: content,
                    isReply: false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReplyNonOwnerOptions({
    required String replyId,
    required String commentId,
    required String authorId,
    required String authorName,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text('Report'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _navigateToReportPage(
                    contentId: replyId,
                    authorId: authorId,
                    authorName: authorName,
                    content: content,
                    isReply: true,
                    commentId: commentId,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteCommentConfirmation(
    String commentId,
    Map<String, dynamic> commentData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissals
      useSafeArea: true, // Ensure dialog doesn't interfere with UI
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text(
            'Are you sure you want to delete this comment? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Use CommentService to maintain proper count
                  await CommentService().deleteComment(
                    postId: widget.postId,
                    commentId: commentId,
                  );

                  // Add a small delay to allow the stream to update naturally
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Notify parent that comment was deleted
                  widget.onCommentChanged?.call();

                  // Call the callback if provided
                  if (widget.onDelete != null) {
                    widget.onDelete!(commentId, commentData);
                  }

                  // Show success message after everything has settled
                  if (!mounted) return;
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(this.context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Comment deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    final messenger = ScaffoldMessenger.of(this.context);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error deleting comment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showCommentOwnerOptions(
    String commentId,
    Map<String, dynamic> commentData,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Comment'),
                onTap: () async {
                  Navigator.of(context).pop();
                  // Small delay for smooth transition
                  await Future.delayed(const Duration(milliseconds: 50));
                  if (!mounted) return;
                  // Start inline editing
                  final commentText = commentData['text'] ?? '';
                  setState(() {
                    _editingCommentId = commentId;
                    _editCommentController.text = commentText;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Comment'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteCommentConfirmation(commentId, commentData);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isCommentOwner(String userId) {
    return userId == widget.currentUserId;
  }

  /// Build professional time display for comments
  Widget _buildCommentTime(Map<String, dynamic> commentData) {
    Timestamp? timestamp;

    // Try different timestamp field names
    if (commentData['timestamp'] != null) {
      timestamp = commentData['timestamp'] as Timestamp;
    } else if (commentData['created_at'] != null) {
      timestamp = commentData['created_at'] as Timestamp;
    } else if (commentData['createdAt'] != null) {
      timestamp = commentData['createdAt'] as Timestamp;
    }

    if (timestamp == null) {
      return const SizedBox.shrink();
    }

    final commentTime = timestamp.toDate();
    final timeText = TimeFormatter.formatTime(commentTime);
    final timeWithColor = TimeFormatter.getTimeWithColor(commentTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        timeText,
        style: TextStyle(
          fontSize: 11,
          color: _getTimeColor(timeWithColor.colorType),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Build professional time display for replies
  Widget _buildReplyTime(Map<String, dynamic> replyData) {
    Timestamp? timestamp;

    // Try different timestamp field names
    if (replyData['timestamp'] != null) {
      timestamp = replyData['timestamp'] as Timestamp;
    } else if (replyData['created_at'] != null) {
      timestamp = replyData['created_at'] as Timestamp;
    } else if (replyData['createdAt'] != null) {
      timestamp = replyData['createdAt'] as Timestamp;
    }

    if (timestamp == null) {
      return const SizedBox.shrink();
    }

    final replyTime = timestamp.toDate();
    final timeText = TimeFormatter.formatShortTime(replyTime);

    return Text(
      timeText,
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey[600],
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Get color based on time recency
  Color _getTimeColor(ColorType colorType) {
    switch (colorType) {
      case ColorType.green:
        return Colors.green[600]!;
      case ColorType.blue:
        return Colors.blue[600]!;
      case ColorType.grey:
        return Colors.grey[600]!;
      case ColorType.lightGrey:
        return Colors.grey[500]!;
    }
  }

  void _showReplyOwnerOptions(
    Map<String, dynamic> replyData,
    String replyId,
    String commentId,
  ) {
    developer.log(
      'DEBUG: _showReplyOwnerOptions called for replyId: $replyId',
      name: 'CommentSection',
    );
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Reply'),
                onTap: () async {
                  Navigator.of(context).pop();
                  // Small delay for smooth transition
                  await Future.delayed(const Duration(milliseconds: 50));
                  if (!mounted) return;
                  // Start inline editing for reply
                  final replyText = replyData['text'] ?? '';
                  setState(() {
                    _editingReplyId = replyId;
                    final controller = _editReplyControllers.putIfAbsent(
                      replyId,
                      () => TextEditingController(),
                    );
                    controller.text = replyText;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Reply'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteReplyConfirmation(replyId, replyData, commentId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteReplyConfirmation(
    String replyId,
    Map<String, dynamic> replyData,
    String commentId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissals
      useSafeArea: true, // Ensure dialog doesn't interfere with UI
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Reply'),
          content: const Text(
            'Are you sure you want to delete this reply? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Delete the reply from Firestore
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(commentId)
                      .collection('replies')
                      .doc(replyId)
                      .delete();

                  // Add delay to allow stream to update naturally
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Call the callback if provided
                  if (widget.onDeleteReply != null) {
                    widget.onDeleteReply!(replyId, replyData);
                  }

                  // Show success message after everything has settled
                  if (!mounted) return;
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(this.context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Reply deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    final messenger = ScaffoldMessenger.of(this.context);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error deleting reply: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToReportPage({
    required String contentId,
    required String authorId,
    required String authorName,
    required String content,
    required bool isReply,
    String? commentId,
  }) async {
    var resolvedAuthorName = authorName;

    try {
      final authorDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(authorId)
          .get();
      if (authorDoc.exists) {
        final authorData = authorDoc.data();
        final latestName = authorData?['user_name'];
        if (latestName is String && latestName.trim().isNotEmpty) {
          resolvedAuthorName = latestName;
        }
      }
    } catch (_) {
      // Best-effort: fall back to provided authorName
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportCommentPage(
          commentId: contentId,
          commentContent: content,
          commentAuthorId: authorId,
          commentAuthorName: resolvedAuthorName,
          postId: widget.postId,
        ),
      ),
    );
  }

  /// Builds the modern comment input bar matching the design with vertical expansion
  Widget _buildCommentInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Current user avatar with green ring border
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2E7D32),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: UserProfileImage(
                  userId: widget.currentUserId,
                  radius: 19,
                  onTap: () => _navigateToProfile(widget.currentUserId),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Pill shaped text input container that dynamically expands vertically
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 6,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: "Write a comment...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        isDense: true,
                        filled: false,
                        contentPadding: const EdgeInsets.only(
                          left: 16,
                          right: 8,
                          top: 10,
                          bottom: 10,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  // Trailing smiley & attachment icons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sentiment_satisfied_alt_outlined,
                          color: Colors.grey.shade600,
                          size: 21,
                        ),
                        const SizedBox(width: 6),
                        Transform.rotate(
                          angle: -0.6,
                          child: Icon(
                            Icons.attach_file,
                            color: Colors.grey.shade600,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Circular green send button
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF1B8E2D),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(21),
                  onTap: _isSendingComment ? null : _sendComment,
                  child: Center(
                    child: _isSendingComment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds empty comments state matching the design
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Speech bubbles illustration
            const SizedBox(
              width: 160,
              height: 120,
              child: CustomPaint(
                painter: _CommentBubblesPainter(),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              "No comments yet.",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F3822),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              "Be the first to share your thoughts,\nideas or questions!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),

            // Plant / Leaf divider
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.eco,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('comment_section_${widget.postId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Modern Comment input bar
        _buildCommentInputBar(),

        // Comment list - Read directly from post document for stability
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .snapshots(),
          key: ValueKey('comments_${widget.postId}'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                ),
              );
            }

            final postDoc = snapshot.data!;
            if (!postDoc.exists) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    "Post not found.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            final postData = postDoc.data() as Map<String, dynamic>?;
            final comments = postData?['comments'] as List<dynamic>? ?? [];

            if (comments.isEmpty) {
              return _buildEmptyState();
            }

            final commentList = List<Map<String, dynamic>>.from(
              comments.map((comment) => Map<String, dynamic>.from(comment)),
            ).reversed.toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: commentList.length,
              itemBuilder: (context, index) {
                final data = commentList[index];
                final dynamic commentIdRaw =
                    data['id'] ?? data['commentId'] ?? '';
                String commentId = commentIdRaw is String
                    ? commentIdRaw
                    : commentIdRaw.toString();

                final bool hasValidCommentId = commentId.trim().isNotEmpty;
                if (!hasValidCommentId) {
                  commentId = 'legacy_$index';
                }

                final dynamic userIdRaw =
                    data['userId'] ?? data['authorId'] ?? data['user_id'] ?? '';
                final userId = userIdRaw is String ? userIdRaw : '';

                final dynamic nameRaw =
                    data['user_name'] ??
                    data['authorName'] ??
                    data['author_name'];
                final displayName =
                    (nameRaw is String && nameRaw.trim().isNotEmpty)
                    ? nameRaw
                    : 'Farmer';

                final bool authorVerified = data['author_verified'] == true;

                final dynamic textRaw = data['text'] ?? data['content'] ?? '';
                final text = textRaw is String ? textRaw : '';

                final dynamic profileRaw =
                    data['profile_pic'] ??
                    data['authorProfilePic'] ??
                    data['user_profile'] ??
                    '';
                final profilePic = profileRaw is String ? profileRaw : '';

                if (!_replyControllers.containsKey(commentId)) {
                  _replyControllers[commentId] = TextEditingController();
                }

                final bool isCommentTextExpanded =
                    _expandedComments[commentId] ?? false;

                return Padding(
                  key: ValueKey('comment_$commentId'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comment item
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          UserProfileImage(
                            userId: userId,
                            initialImageUrl: profilePic,
                            onTap: () => _navigateToProfile(userId),
                          ),
                          const SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Username with verification and follow button
                                Row(
                                  children: [
                                    Flexible(
                                      child: GestureDetector(
                                        onTap: () => _navigateToProfile(userId),
                                        child: UserNameDisplay(
                                          userId: userId,
                                          initialName: displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                    _buildCommentVerifiedTick(
                                      userId,
                                      authorVerified,
                                    ),
                                    // Follow button for other users
                                    if (userId != widget.currentUserId)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: StableFollowButton(
                                          key: ValueKey('follow_$userId'),
                                          currentUserId: widget.currentUserId,
                                          targetUserId: userId,
                                        ),
                                      ),
                                  ],
                                ),
                                // Time display below name
                                _buildCommentTime(data),
                                const SizedBox(height: 4),
                                // Comment text with collapse (> 150 chars) and long press options
                                GestureDetector(
                                  onLongPress: _isCommentOwner(userId)
                                      ? () => _showCommentOwnerOptions(
                                          commentId,
                                          data,
                                        )
                                      : () => _showCommentNonOwnerOptions(
                                          commentId: commentId,
                                          authorId: userId,
                                          authorName: displayName,
                                          content: text,
                                        ),
                                  behavior: HitTestBehavior.translucent,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _editingCommentId == commentId
                                          ? Container(
                                              key: ValueKey(
                                                'edit_comment_$commentId',
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.blue.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: TextField(
                                                controller:
                                                    _editCommentController,
                                                keyboardType:
                                                    TextInputType.multiline,
                                                minLines: 1,
                                                maxLines: 6,
                                                autofocus: false,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Edit your comment...',
                                                  hintStyle: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 14,
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  border: InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                  suffixIcon: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.green,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: IconButton(
                                                          icon: const Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                          onPressed: () async {
                                                            if (_editCommentController
                                                                .text
                                                                .trim()
                                                                .isNotEmpty) {
                                                              final newText =
                                                                  _editCommentController
                                                                      .text
                                                                      .trim();
                                                              await CommentService().editComment(
                                                                postId: widget.postId,
                                                                commentId: commentId,
                                                                newContent: newText,
                                                                userId: widget.currentUserId,
                                                                userName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                                                              );

                                                              final updatedData =
                                                                  Map<
                                                                    String,
                                                                    dynamic
                                                                  >.from(data);
                                                              updatedData['text'] =
                                                                  newText;
                                                              updatedData['updatedAt'] =
                                                                  Timestamp.now();

                                                              widget.onEdit
                                                                  ?.call(
                                                                    commentId,
                                                                    updatedData,
                                                                  );

                                                              if (!mounted) {
                                                                return;
                                                              }
                                                              setState(
                                                                () =>
                                                                    _editingCommentId =
                                                                        null,
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors.grey[300],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: IconButton(
                                                          icon: const Icon(
                                                            Icons.close,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                          onPressed: () => setState(
                                                            () =>
                                                                _editingCommentId =
                                                                    null,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                          : _buildExpandableText(
                                              text: text,
                                              maxLength: 150,
                                              isExpanded: isCommentTextExpanded,
                                              onToggle: () {
                                                setState(() {
                                                  _expandedComments[commentId] =
                                                      !isCommentTextExpanded;
                                                });
                                              },
                                              style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.4,
                                                color: Colors.black87,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Reactions + Reply button
                      Row(
                        children: [
                          hasValidCommentId
                              ? StreamBuilder<QuerySnapshot>(
                                  key: ValueKey('reactions_$commentId'),
                                  stream: FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.postId)
                                      .collection('comments')
                                      .doc(commentId)
                                      .collection('reactions')
                                      .snapshots(),
                                  builder: (context, reactionSnapshot) {
                                    final count = reactionSnapshot.hasData
                                        ? reactionSnapshot.data!.docs.length
                                        : 0;
                                    final isReacted =
                                        reactionSnapshot.hasData &&
                                        reactionSnapshot.data!.docs.any(
                                          (doc) => doc.id == widget.currentUserId,
                                        );
                                    return Row(
                                      children: [
                                        GestureDetector(
                                          key: ValueKey('reaction_btn_$commentId'),
                                          onTap: () async {
                                            try {
                                              final ref = FirebaseFirestore
                                                  .instance
                                                  .collection('posts')
                                                  .doc(widget.postId)
                                                  .collection('comments')
                                                  .doc(commentId)
                                                  .collection('reactions')
                                                  .doc(widget.currentUserId);
                                              final doc = await ref.get();
                                              if (doc.exists) {
                                                await ref.delete();
                                              } else {
                                                await ref.set({
                                                  'created_at': Timestamp.now(),
                                                });
                                              }
                                            } catch (e) {
                                              // Handle error silently
                                            }
                                          },
                                          child: Icon(
                                            Icons.favorite,
                                            size: 16,
                                            color: isReacted
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                        ),
                                        if (count > 0)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 4),
                                            child: Text(
                                              '$count',
                                              style: const TextStyle(
                                                  fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                )
                              : const Row(
                                  children: [
                                    Icon(Icons.favorite,
                                        size: 16, color: Colors.grey),
                                  ],
                                ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showReplyBox[commentId] =
                                    !(_showReplyBox[commentId] ?? false);
                              });
                            },
                            child: const Text(
                              'Reply',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Reply input box with dynamic vertical stretch
                      if (_showReplyBox[commentId] == true)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 48,
                            right: 8,
                            top: 6,
                            bottom: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _replyControllers[commentId],
                                    keyboardType: TextInputType.multiline,
                                    minLines: 1,
                                    maxLines: 5,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.black87,
                                      height: 1.35,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Write a reply...',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 13.5,
                                      ),
                                      isDense: true,
                                      filled: false,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1B8E2D),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(19),
                                      onTap: _isSendingReply[commentId] == true
                                          ? null
                                          : () {
                                              final text =
                                                  _replyControllers[commentId]
                                                      ?.text ??
                                                  '';
                                              _sendReply(commentId, text);
                                            },
                                      child: Center(
                                        child: _isSendingReply[commentId] == true
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<Color>(
                                                        Colors.white,
                                                      ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.send_rounded,
                                                color: Colors.white,
                                                size: 17,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Replies section: Hidden by default with "View 1 reply" / "View N replies" button in green
                      hasValidCommentId
                          ? StreamBuilder<QuerySnapshot>(
                              key: ValueKey('replies_$commentId'),
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.postId)
                                  .collection('comments')
                                  .doc(commentId)
                                  .collection('replies')
                                  .orderBy('created_at', descending: false)
                                  .snapshots(),
                              builder: (context, replySnapshot) {
                                if (!replySnapshot.hasData) {
                                  return const SizedBox.shrink();
                                }
                                final replies = replySnapshot.data!.docs;
                                if (replies.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final int replyCount = replies.length;
                                final bool isRepliesVisible =
                                    _showRepliesForComment[commentId] ?? false;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // View reply / View replies button with count in green
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 48,
                                        top: 2,
                                        bottom: 4,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _showRepliesForComment[commentId] =
                                                !isRepliesVisible;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 2,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 1.5,
                                                color: const Color(0xFF2E7D32),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isRepliesVisible
                                                    ? (replyCount == 1
                                                        ? 'Hide reply'
                                                        : 'Hide $replyCount replies')
                                                    : (replyCount == 1
                                                        ? 'View 1 reply'
                                                        : 'View $replyCount replies'),
                                                style: const TextStyle(
                                                  color: Color(0xFF2E7D32),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                isRepliesVisible
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
                                                color: const Color(0xFF2E7D32),
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Display replies only when expanded
                                    if (isRepliesVisible)
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: replies.length,
                                        itemBuilder: (context, index) {
                                          final reply =
                                              replies[index].data() as Map<String, dynamic>;
                                          final String replyId = replies[index].id;
                                          final dynamic replyUserIdRaw =
                                              reply['userId'] ??
                                              reply['authorId'] ??
                                              reply['user_id'] ??
                                              '';
                                          final String replyUserId =
                                              replyUserIdRaw is String
                                              ? replyUserIdRaw
                                              : '';

                                          final dynamic replyNameRaw =
                                              reply['user_name'] ??
                                              reply['authorName'] ??
                                              reply['author_name'];
                                          final String replyUserName =
                                              (replyNameRaw is String &&
                                                  replyNameRaw.trim().isNotEmpty)
                                              ? replyNameRaw
                                              : 'Farmer';
                                          final bool replyVerified =
                                              reply['author_verified'] == true;
                                          final String replyText = reply['text'] ?? '';
                                          final String replyProfilePic =
                                              reply['profile_pic'] ?? '';
                                          final bool isReplyTextExpanded =
                                              _expandedRepliesText[replyId] ?? false;

                                          return Padding(
                                            key: ValueKey('reply_$replyId'),
                                            padding: const EdgeInsets.only(
                                              left: 48,
                                              top: 6,
                                              bottom: 4,
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Reply avatar
                                                GestureDetector(
                                                  onTap: () =>
                                                      _navigateToProfile(replyUserId),
                                                  child: UserProfileImage(
                                                    userId: replyUserId,
                                                    radius: 14,
                                                    initialImageUrl: replyProfilePic,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Reply content
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      // Reply username
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: GestureDetector(
                                                              onTap: () =>
                                                                  _navigateToProfile(
                                                                    replyUserId,
                                                                  ),
                                                              child: UserNameDisplay(
                                                                userId: replyUserId,
                                                                initialName: replyUserName,
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight.bold,
                                                                ),
                                                                overflow:
                                                                    TextOverflow.ellipsis,
                                                                maxLines: 1,
                                                              ),
                                                            ),
                                                          ),
                                                          _buildVerifiedTick(
                                                            replyUserId,
                                                            replyVerified,
                                                            size: 14,
                                                          ),
                                                          // Follow button for other users in replies
                                                          if (replyUserId !=
                                                              widget.currentUserId)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    left: 8,
                                                                  ),
                                                              child: StableFollowButton(
                                                                key: ValueKey(
                                                                  'follow_$replyUserId',
                                                                ),
                                                                currentUserId:
                                                                    widget.currentUserId,
                                                                targetUserId: replyUserId,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      // Time display below reply name
                                                      _buildReplyTime(reply),
                                                      const SizedBox(height: 2),
                                                      // Reply text with collapse (> 100 chars) and long press options
                                                      GestureDetector(
                                                        onLongPress:
                                                            _isCommentOwner(replyUserId)
                                                            ? () => _showReplyOwnerOptions(
                                                                reply,
                                                                replyId,
                                                                commentId,
                                                              )
                                                            : () =>
                                                                  _showReplyNonOwnerOptions(
                                                                    replyId:
                                                                        replyId,
                                                                    commentId: commentId,
                                                                    authorId: replyUserId,
                                                                    authorName:
                                                                        replyUserName,
                                                                    content: replyText,
                                                                  ),
                                                        behavior:
                                                            HitTestBehavior.translucent,
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            _editingReplyId ==
                                                                    replyId
                                                                ? Container(
                                                                    key: ValueKey(
                                                                      'edit_reply_$replyId',
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color:
                                                                          Colors.grey[50],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            10,
                                                                          ),
                                                                      border: Border.all(
                                                                        color: Colors.blue
                                                                            .withValues(
                                                                              alpha: 0.3,
                                                                            ),
                                                                        width: 1.5,
                                                                      ),
                                                                    ),
                                                                    child: TextField(
                                                                      controller: _editReplyControllers
                                                                          .putIfAbsent(
                                                                            replyId,
                                                                            () => TextEditingController()
                                                                              ..text =
                                                                                  replyText,
                                                                          ),
                                                                      keyboardType:
                                                                          TextInputType.multiline,
                                                                      minLines: 1,
                                                                      maxLines: 5,
                                                                      autofocus: false,
                                                                      style:
                                                                          const TextStyle(
                                                                            fontSize: 13,
                                                                            height: 1.4,
                                                                          ),
                                                                      decoration: InputDecoration(
                                                                        hintText:
                                                                            'Edit your reply...',
                                                                        hintStyle: TextStyle(
                                                                          color: Colors
                                                                              .grey[400],
                                                                          fontSize: 13,
                                                                        ),
                                                                        contentPadding:
                                                                            const EdgeInsets.symmetric(
                                                                              horizontal:
                                                                                  12,
                                                                              vertical: 8,
                                                                            ),
                                                                        border: InputBorder
                                                                            .none,
                                                                        enabledBorder:
                                                                            InputBorder
                                                                                .none,
                                                                        focusedBorder:
                                                                            InputBorder
                                                                                .none,
                                                                        suffixIcon: Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize
                                                                                  .min,
                                                                          children: [
                                                                            Container(
                                                                              decoration: BoxDecoration(
                                                                                color: Colors
                                                                                    .green,
                                                                                borderRadius:
                                                                                    BorderRadius.circular(
                                                                                      6,
                                                                                    ),
                                                                              ),
                                                                              child: IconButton(
                                                                                icon: const Icon(
                                                                                  Icons
                                                                                      .check,
                                                                                  color: Colors
                                                                                      .white,
                                                                                  size: 16,
                                                                                ),
                                                                                onPressed: () async {
                                                                                  final controller =
                                                                                      _editReplyControllers[replyId];
                                                                                  if (controller !=
                                                                                          null &&
                                                                                      controller
                                                                                          .text
                                                                                          .trim()
                                                                                          .isNotEmpty) {
                                                                                    try {
                                                                                      final replyData =
                                                                                          replies[index];
                                                                                      Map<String, dynamic> replyMap;
                                                                                      try {
                                                                                        replyMap =
                                                                                            replyData.data()
                                                                                                as Map<String, dynamic>;
                                                                                      } catch (_) {
                                                                                        replyMap =
                                                                                            replyData
                                                                                                as Map<String, dynamic>;
                                                                                      }

                                                                                      await CommentService().editReply(
                                                                                        postId:
                                                                                            widget.postId,
                                                                                        commentId:
                                                                                            commentId,
                                                                                        replyId:
                                                                                            replyId,
                                                                                        newContent:
                                                                                            controller.text.trim(),
                                                                                      );

                                                                                      replyMap['text'] = controller
                                                                                          .text
                                                                                          .trim();
                                                                                      replyMap['updatedAt'] =
                                                                                          Timestamp.now();

                                                                                      widget.onEditReply?.call(
                                                                                        replyId,
                                                                                        replyMap,
                                                                                      );

                                                                                      if (!mounted) {
                                                                                        return;
                                                                                      }
                                                                                      setState(
                                                                                        () =>
                                                                                            _editingReplyId = null,
                                                                                      );
                                                                                    } catch (e) {
                                                                                      developer.log(
                                                                                        'Error editing reply: $e',
                                                                                        name:
                                                                                            'CommentSection',
                                                                                      );
                                                                                    }
                                                                                  }
                                                                                },
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 4,
                                                                            ),
                                                                            Container(
                                                                              decoration: BoxDecoration(
                                                                                color: Colors
                                                                                    .grey[300],
                                                                                borderRadius:
                                                                                    BorderRadius.circular(
                                                                                      6,
                                                                                    ),
                                                                              ),
                                                                              child: IconButton(
                                                                                icon: const Icon(
                                                                                  Icons
                                                                                      .close,
                                                                                  color: Colors
                                                                                      .white,
                                                                                  size: 16,
                                                                                ),
                                                                                onPressed: () =>
                                                                                    setState(
                                                                                      () => _editingReplyId =
                                                                                          null,
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 6,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  )
                                                                : _buildExpandableText(
                                                                    text: replyText,
                                                                    maxLength: 100,
                                                                    isExpanded: isReplyTextExpanded,
                                                                    onToggle: () {
                                                                      setState(() {
                                                                        _expandedRepliesText[replyId] =
                                                                            !isReplyTextExpanded;
                                                                      });
                                                                    },
                                                                    style: const TextStyle(
                                                                      fontSize: 13,
                                                                      height: 1.4,
                                                                      color: Colors.black87,
                                                                    ),
                                                                  ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Custom painter for the empty comment state speech bubbles illustration
class _CommentBubblesPainter extends CustomPainter {
  const _CommentBubblesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // 1. Soft green shadow at base
    final shadowPaint = Paint()
      ..color = const Color(0xFFE2F4E5)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 4, size.height - 10),
        width: 110,
        height: 18,
      ),
      shadowPaint,
    );

    // 2. Back speech bubble (light pastel green)
    final backBubblePaint = Paint()
      ..color = const Color(0xFFC7EBC8)
      ..style = PaintingStyle.fill;

    final backPath = Path();
    final backRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + 26, cy - 2),
        width: 58,
        height: 52,
      ),
      const Radius.circular(26),
    );
    backPath.addRRect(backRect);
    // Back tail pointing to bottom right
    backPath.moveTo(cx + 34, cy + 18);
    backPath.quadraticBezierTo(cx + 46, cy + 30, cx + 44, cy + 32);
    backPath.quadraticBezierTo(cx + 36, cy + 26, cx + 24, cy + 24);
    canvas.drawPath(backPath, backBubblePaint);

    // 3. Front speech bubble (vibrant green)
    final frontBubblePaint = Paint()
      ..color = const Color(0xFF38A13D)
      ..style = PaintingStyle.fill;

    final frontPath = Path();
    final frontRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - 10, cy - 8),
        width: 68,
        height: 56,
      ),
      const Radius.circular(28),
    );
    frontPath.addRRect(frontRect);
    // Tail pointing to bottom-left
    frontPath.moveTo(cx - 24, cy + 12);
    frontPath.quadraticBezierTo(cx - 36, cy + 26, cx - 35, cy + 28);
    frontPath.quadraticBezierTo(cx - 22, cy + 22, cx - 12, cy + 18);
    canvas.drawPath(frontPath, frontBubblePaint);

    // 4. Three white dots inside front bubble
    final dotsPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final double dotY = cy - 8;
    canvas.drawCircle(Offset(cx - 21, dotY), 3.8, dotsPaint);
    canvas.drawCircle(Offset(cx - 10, dotY), 3.8, dotsPaint);
    canvas.drawCircle(Offset(cx + 1, dotY), 3.8, dotsPaint);

    // 5. Radiating spark accents (green dashed rays around bubbles)
    final sparkPaint = Paint()
      ..color = const Color(0xFF38A13D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    // Top-left spark
    canvas.drawLine(
      Offset(cx - 38, cy - 30),
      Offset(cx - 46, cy - 38),
      sparkPaint,
    );

    // Far-left spark
    canvas.drawLine(
      Offset(cx - 48, cy - 12),
      Offset(cx - 58, cy - 12),
      sparkPaint,
    );

    // Top-center-left spark
    canvas.drawLine(
      Offset(cx - 20, cy - 44),
      Offset(cx - 23, cy - 54),
      sparkPaint,
    );

    // Top-right spark
    canvas.drawLine(
      Offset(cx + 28, cy - 36),
      Offset(cx + 34, cy - 46),
      sparkPaint,
    );

    // Far-right spark
    canvas.drawLine(
      Offset(cx + 54, cy - 16),
      Offset(cx + 64, cy - 16),
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
