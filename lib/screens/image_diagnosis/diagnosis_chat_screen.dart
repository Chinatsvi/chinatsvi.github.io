import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_manager.dart';
import '../../services/enhanced_ai_service.dart';
import '../../services/storage_router_service.dart';
import '../../utils/verification_helpers.dart';
import '../../widgets/thinking_indicator.dart';
import '../badge/renewal_payment_screen.dart';
import '../badge/verification_intro_screen.dart';
import '../badge/verification_payment_screen.dart';
import 'diagnosis_message_bubble.dart';
import 'diagnosis_input_bar.dart';
import 'previous_chats_screen.dart';

class ChatGreetingHeader extends StatefulWidget {
  const ChatGreetingHeader({super.key, required this.name});

  final String? name;

  @override
  State<ChatGreetingHeader> createState() => _ChatGreetingHeaderState();
}

class _ChatGreetingHeaderState extends State<ChatGreetingHeader> {
  String _displayedGreeting = '';
  String _displayedSubtitle = '';
  bool _showCursor = false;
  Timer? _typeTimer;
  Timer? _cursorTimer;
  Timer? _subtitleDelayTimer;

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _fullGreeting =>
      widget.name != null && widget.name!.trim().isNotEmpty
      ? '$_timeGreeting, ${widget.name!.trim()}'
      : _timeGreeting;

  static const String _fullSubtitle =
      "I'm Chinatsvi — ask me about farming, or anything else on your mind.";

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant ChatGreetingHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _startTyping();
    }
  }

  void _startTyping() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    _subtitleDelayTimer?.cancel();

    _displayedGreeting = '';
    _displayedSubtitle = '';
    _showCursor = true;

    int charIndex = 0;
    final greeting = _fullGreeting;

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 520), (_) {
      if (!mounted) return;
      setState(() => _showCursor = !_showCursor);
    });

    _typeTimer = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (charIndex < greeting.length) {
          charIndex++;
          _displayedGreeting = greeting.substring(0, charIndex);
        } else {
          timer.cancel();
          _subtitleDelayTimer = Timer(const Duration(milliseconds: 180), () {
            _startSubtitleTyping();
          });
        }
      });
    });
  }

  void _startSubtitleTyping() {
    if (!mounted) return;

    int subIndex = 0;

    _typeTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (subIndex < _fullSubtitle.length) {
          subIndex++;
          _displayedSubtitle = _fullSubtitle.substring(0, subIndex);
        } else {
          timer.cancel();
          _cursorTimer?.cancel();
          _showCursor = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    _subtitleDelayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.green[700]!, Colors.green[400]!],
                          ).createShader(bounds),
                          child: Text(
                            _displayedGreeting,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _showCursor ? 1 : 0,
                        duration: const Duration(milliseconds: 120),
                        child: Text(
                          '|',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            AnimatedOpacity(
              opacity: _displayedSubtitle.isNotEmpty ? 1 : 0,
              duration: const Duration(milliseconds: 240),
              child: Text(
                _displayedSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiagnosisChatScreen extends StatefulWidget {
  final String chatId;
  final String sender;

  const DiagnosisChatScreen({
    super.key,
    required this.chatId,
    required this.sender,
  });

  @override
  State<DiagnosisChatScreen> createState() => _DiagnosisChatScreenState();
}

class _PendingDiagnosisMessage {
  final String id;
  final String text;
  final String attachmentType;
  final File? attachment;
  final List<File> attachments;
  final String? attachmentUrl;
  final List<String> attachmentUrls;
  final DateTime timestamp;
  final bool isSending;

  _PendingDiagnosisMessage({
    required this.id,
    required this.text,
    this.attachmentType = 'text',
    this.attachment,
    this.attachments = const [],
    this.attachmentUrl,
    this.attachmentUrls = const [],
    required this.timestamp,
    this.isSending = true,
  });
}

class _DiagnosisChatScreenState extends State<DiagnosisChatScreen> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _aiBusy = false;
  final List<_PendingDiagnosisMessage> _pendingMessages = [];
  final Map<String, File> _localFileByUrl = {};
  String? _farmerName;
  bool _isGenuinelyNewChat = false;
  String? _chatTitle;
  bool _titleGenerationTriggered = false;

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  // Message queue for handling multiple user messages
  final List<Map<String, dynamic>> _messageQueue = [];
  bool _isProcessingQueue = false;

  String get _chatId => widget.chatId;

  @override
  void initState() {
    super.initState();
    _preloadRewardedAd();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureChatDocExists();
      _loadFarmerName();
      await _autoFocusIfNewChat();
    });
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Refresh rate limit display
  void _refreshRateLimit() {
    if (mounted) {
      setState(() {});
    }
  }

  // ================= REWARDED ADS & PRO NAVIGATION =================
  void _preloadRewardedAd() {
    if (!AdManager.instance.adsEnabled) return;
    _rewardedAd?.dispose();
    _rewardedAd = null;

    RewardedAd.load(
      adUnitId: AdManager.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _rewardedAd = ad;
            _isAdLoading = false;
          });
          debugPrint('✅ [Diagnosis Chat Ads] Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '⚠️ [Diagnosis Chat Ads] Rewarded ad failed to load: ${error.message}',
          );
          if (!mounted) return;
          setState(() {
            _rewardedAd = null;
            _isAdLoading = false;
          });
        },
      ),
    );
  }

  Future<void> _watchRewardedAd() async {
    if (_rewardedAd == null) {
      setState(() => _isAdLoading = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10),
              Text('Loading ad, please wait a moment...'),
            ],
          ),
          backgroundColor: Colors.green[800],
          duration: const Duration(seconds: 2),
        ),
      );

      RewardedAd.load(
        adUnitId: AdManager.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _rewardedAd = ad;
              _isAdLoading = false;
            });
            _showLoadedRewardedAd();
          },
          onAdFailedToLoad: (error) {
            debugPrint(
              '⚠️ [Diagnosis Chat Ads] On-demand ad failed: ${error.message}',
            );
            if (!mounted) return;
            setState(() {
              _rewardedAd = null;
              _isAdLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ad not ready: ${error.message}. Please try again shortly.',
                ),
                backgroundColor: Colors.green[800],
              ),
            );
          },
        ),
      );
      return;
    }

    _showLoadedRewardedAd();
  }

  void _showLoadedRewardedAd() {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('📱 [Diagnosis Chat Ads] Rewarded ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('📱 [Diagnosis Chat Ads] Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        _preloadRewardedAd(); // Preload next ad immediately for banking
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
          '⚠️ [Diagnosis Chat Ads] Rewarded ad failed to show: ${error.message}',
        );
        ad.dispose();
        _rewardedAd = null;
        _preloadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint(
          '🎉 [Diagnosis Chat Ads] User earned reward: ${reward.amount} ${reward.type}',
        );
        await EnhancedAiService.instance.addRewardPoints(1);
        final rateInfo = await EnhancedAiService.instance.getRateLimitInfo();
        final total = rateInfo['remaining'] as int;
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🎉 +1 Point earned! You now have $total point${total == 1 ? '' : 's'} available.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  Future<void> _handleGetProNavigation(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to upgrade to Pro.'),
          backgroundColor: Colors.green[800],
        ),
      );
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};
      final isVerified =
          data['isVerified'] == true || data['verified'] == true;
      final verificationStatus =
          (data['verificationStatus'] ?? '').toString().toLowerCase().trim();
      final verificationPaid = data['verificationPaid'] == true;
      final isExpired = isVerificationExpiredFromMap(data);

      if (!context.mounted) return;

      if (isExpired && verificationPaid) {
        // Expired verification -> Renewal payment
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RenewalPaymentScreen()),
        );
      } else if (verificationStatus == 'approved' ||
          (isVerified && !verificationPaid)) {
        // Approved by admin, waiting for payment -> Verification payment
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VerificationPaymentScreen(),
          ),
        );
      } else if (verificationStatus == 'pending') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '⏳ Your verification request is pending review by admin.',
            ),
            backgroundColor: Colors.green[800],
          ),
        );
      } else {
        // Not yet requested -> Verification Intro
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VerificationIntroScreen(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VerificationIntroScreen(),
          ),
        );
      }
    }
  }

  // ================= INIT CHAT =================
  Future<void> _ensureChatDocExists() async {
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(_chatId);
    final snapshot = await chatDoc.get();

    if (snapshot.exists) {
      _chatTitle = (snapshot.data()?['title'] as String?) ?? '';
    }
  }

  String _generateTitleFromMessage(String message) {
    final rawMessage = message.trim();
    if (rawMessage.isEmpty) {
      return 'New diagnosis';
    }

    final introPattern = RegExp(
      r'^(hi|hello|hey|please|can you|could you|i want to know|i need help with|help me with|what is|how do i|how to|can i|could i)\b[,:\s-]*',
      caseSensitive: false,
    );

    var cleaned = rawMessage.replaceFirst(introPattern, '').trim();
    if (cleaned.isEmpty) {
      cleaned = rawMessage;
    }

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[?!.]+$'), '');
    cleaned = cleaned.trim();

    if (cleaned.isEmpty) {
      return 'New diagnosis';
    }

    cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);

    const maxLength = 42;
    if (cleaned.length <= maxLength) {
      return cleaned;
    }

    final truncated = cleaned.substring(0, maxLength).trimRight();
    final lastSpace = truncated.lastIndexOf(' ');
    final cutIndex = lastSpace > 15 ? lastSpace : maxLength;
    return '${truncated.substring(0, cutIndex).trim()}…';
  }

  Future<void> _maybeSaveTitle(String firstUserMessage) async {
    if (_titleGenerationTriggered) return;
    if (_chatTitle != null && _chatTitle!.isNotEmpty) return;
    if (firstUserMessage.trim().isEmpty) return;

    _titleGenerationTriggered = true;

    final title = _generateTitleFromMessage(firstUserMessage);
    _chatTitle = title;

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
    await chatRef.set(
      {
        'chat_id': _chatId,
        'sender': widget.sender,
        'type': 'diagnosis',
        'timestamp': FieldValue.serverTimestamp(),
        'last_message': firstUserMessage.trim(),
        'title': title,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _autoFocusIfNewChat() async {
    if (!_isGenuinelyNewChat || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  Future<void> _loadFarmerName() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    String? name;

    try {
      final farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(authUser.uid)
          .get();

      name = farmerDoc.data()?['user_name'] as String?;
    } catch (e) {
      debugPrint('Failed to load farmer name: $e');
    }

    if (name == null || name.trim().isEmpty) {
      name = authUser.displayName?.trim();
    }

    if (mounted) {
      setState(() {
        _farmerName = (name != null && name.trim().isNotEmpty)
            ? name.trim().split(' ').first
            : null;
      });
    }
  }

  // ================= SCROLL =================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= QUEUE MANAGEMENT =================
  void _addToQueue(
    String text, {
    required String docId,
    File? attachment,
    List<File>? attachments,
    String? attachmentType,
    String? attachmentUrl,
    List<String>? attachmentUrls,
  }) {
    _messageQueue.add({
      'docId': docId,
      'text': text,
      'attachment': attachment,
      'attachments':
          attachments ?? (attachment == null ? <File>[] : [attachment]),
      'attachmentType': attachmentType,
      'attachmentUrl': attachmentUrl,
      'attachmentUrls':
          attachmentUrls ??
          (attachmentUrl == null ? <String>[] : [attachmentUrl]),
      'timestamp': DateTime.now(),
    });

    if (!_isProcessingQueue) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _messageQueue.isEmpty) return;

    _isProcessingQueue = true;

    while (_messageQueue.isNotEmpty) {
      final message = _messageQueue.removeAt(0);
      await _sendSingleMessage(
        message['text'] as String,
        docId: message['docId'] as String,
        attachment: message['attachment'] as File?,
        attachments: (message['attachments'] as List<File>?) ?? const <File>[],
        attachmentType: message['attachmentType'] as String?,
        attachmentUrl: message['attachmentUrl'] as String?,
        attachmentUrls:
            (message['attachmentUrls'] as List<String>?) ?? const <String>[],
      );

      // Wait for AI response before processing next message
      while (_aiBusy) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    _isProcessingQueue = false;
  }

  // ================= SEND MESSAGE =================
  Future<void> sendMessage(
    String text, {
    File? attachment,
    List<File>? attachments,
    String? attachmentType,
    String? attachmentUrl,
    List<String>? attachmentUrls,
  }) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty && attachment == null && (attachments == null || attachments.isEmpty)) return;

    // Cache local files by their remote URL so bubbles render immediately from disk
    if (attachmentUrl != null && attachment != null) {
      _localFileByUrl[attachmentUrl] = attachment;
    }
    if (attachmentUrls != null && attachments != null) {
      for (int i = 0; i < attachmentUrls.length; i++) {
        if (i < attachments.length) {
          _localFileByUrl[attachmentUrls[i]] = attachments[i];
        }
      }
    }

    // Pre-allocate the Firestore docId so the optimistic bubble and Firestore doc share the same ID
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages');
    final farmerDocId = messagesRef.doc().id;

    final allAttachments = attachments ?? (attachment == null ? <File>[] : [attachment]);
    final allUrls = attachmentUrls ?? (attachmentUrl == null ? <String>[] : [attachmentUrl]);
    final resolvedType = attachmentType ?? (allAttachments.isNotEmpty || allUrls.isNotEmpty ? 'image' : 'text');

    final pending = _PendingDiagnosisMessage(
      id: farmerDocId,
      text: trimmed,
      attachmentType: resolvedType,
      attachment: attachment ?? (allAttachments.isNotEmpty ? allAttachments.first : null),
      attachments: allAttachments,
      attachmentUrl: attachmentUrl ?? (allUrls.isNotEmpty ? allUrls.first : null),
      attachmentUrls: allUrls,
      timestamp: DateTime.now(),
      isSending: true,
    );

    if (mounted) {
      setState(() {
        _pendingMessages.add(pending);
      });
      _scrollToBottom();
    }

    _addToQueue(
      trimmed,
      docId: farmerDocId,
      attachment: attachment,
      attachments: allAttachments,
      attachmentType: resolvedType,
      attachmentUrl: attachmentUrl,
      attachmentUrls: allUrls,
    );
  }

  Future<void> _sendSingleMessage(
    String text, {
    required String docId,
    File? attachment,
    List<File> attachments = const <File>[],
    String? attachmentType,
    String? attachmentUrl,
    List<String> attachmentUrls = const <String>[],
  }) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty && attachment == null && attachments.isEmpty) return;

    // Check rate limits before sending any message
    final rateInfo = await EnhancedAiService.instance.getRateLimitInfo();
    final remaining = rateInfo['remaining'] as int;
    final isUnlimited = rateInfo['unlimited'] as bool;

    if (!isUnlimited && remaining <= 0) {
      if (mounted) {
        setState(() {
          _pendingMessages.removeWhere((p) => p.id == docId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '⚡ Daily points consumed. Watch a video ad to earn +1 point or Get Pro for unlimited access!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Watch Ad',
              textColor: Colors.amberAccent,
              onPressed: () {
                _watchRewardedAd();
              },
            ),
          ),
        );
      }
      return;
    }

    // Track usage only if we will upload now (not already uploaded by input bar)
    final isUpload = attachments.isNotEmpty && attachmentUrls.isEmpty;
    if (isUpload) {
      await EnhancedAiService.instance.trackUsage(isUpload: true);
    } else if (trimmed.isNotEmpty) {
      await EnhancedAiService.instance.trackUsage(isUpload: false);
    }

    // Check upload limits for attachments
    if (attachment != null && attachmentUrl == null) {
      final canUpload = await EnhancedAiService.instance.canUpload();
      if (!canUpload) {
        if (mounted) {
          setState(() {
            _pendingMessages.removeWhere((p) => p.id == docId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '📁 Daily upload limit reached or insufficient points (5 points required). Verified Pro users have unlimited uploads.',
              ),
              backgroundColor: Colors.green[800],
              action: SnackBarAction(
                label: 'Get Pro',
                textColor: Colors.amberAccent,
                onPressed: () => _handleGetProNavigation(context),
              ),
            ),
          );
        }
        // Refund the usage if upload is not allowed
        await EnhancedAiService.instance.refundUsage(isUpload: isUpload);
        return;
      }
    }

    try {
      String? mediaUrl = attachmentUrl;

      if (attachmentUrl == null &&
          attachment != null &&
          await attachment.exists()) {
        // Upload to Cloudinary using StorageRouterService (fallback if not pre-uploaded)
        mediaUrl = await StorageRouterService.instance.uploadPostMedia(
          file: attachment,
          userId: widget.sender,
          mediaType: 'image',
        );

        if (mediaUrl.isEmpty) {
          if (mounted) {
            setState(() {
              _pendingMessages.removeWhere((p) => p.id == docId);
            });
          }
          throw Exception('Failed to upload image to Cloudinary');
        }

        _localFileByUrl[mediaUrl] = attachment;
      }

      final chatDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId);

      final messagesRef = chatDoc.collection('messages');

      if (trimmed.isNotEmpty || attachment != null || attachments.isNotEmpty) {
        await chatDoc.set(
          {
            'chat_id': _chatId,
            'sender': widget.sender,
            'type': 'diagnosis',
            'timestamp': FieldValue.serverTimestamp(),
            'last_message': trimmed.isNotEmpty ? trimmed : 'Image attachment',
            'title': '',
          },
          SetOptions(merge: true),
        );
      }

      if (trimmed.isNotEmpty) {
        unawaited(_maybeSaveTitle(trimmed));
      }

      // ================= AI RESPONSE =================
      if (!_aiBusy) {
        _aiBusy = true;

        final farmerDoc = messagesRef.doc(docId);
        final thinkingDoc = messagesRef.doc();
        final messageTime = Timestamp.now();
        final thinkingTime = Timestamp.fromDate(
          messageTime.toDate().add(const Duration(milliseconds: 1)),
        );

        // Write the user message doc first, then the thinking placeholder.
        await farmerDoc.set({
          'senderId': widget.sender,
          'content': trimmed,
          'type': (attachment != null || attachments.isNotEmpty || mediaUrl != null || attachmentUrls.isNotEmpty) ? 'image' : 'text',
          'mediaUrl': mediaUrl ?? '',
          'mediaUrls': attachmentUrls.isNotEmpty
              ? attachmentUrls
              : (mediaUrl == null ? <String>[] : [mediaUrl]),
          'timestamp': messageTime,
        });

        await thinkingDoc.set({
          'senderId': 'assistant',
          'content': '',
          'status': 'thinking',
          'type': 'text',
          'mediaUrl': '',
          'timestamp': thinkingTime,
        });

        if (mounted) {
          setState(() {
            _pendingMessages.removeWhere((p) => p.id == docId);
          });
        }
        _scrollToBottom();

        try {
          await _streamAiResponse(
            trimmed.isEmpty ? "Please analyze this image" : trimmed,
            thinkingDoc.id,
            isUpload: isUpload,
            attachment: attachment,
            attachmentType: attachmentType,
          );
        } catch (e) {
          // Refund usage if AI response fails
          await EnhancedAiService.instance.refundUsage(isUpload: isUpload);
          debugPrint("AI response failed, usage refunded: $e");
        }
      }
    } catch (e) {
      debugPrint("Send message error: $e");
      if (mounted) {
        setState(() {
          _pendingMessages.removeWhere((p) => p.id == docId);
        });
      }
      // Refund usage if message sending fails
      await EnhancedAiService.instance.refundUsage(isUpload: isUpload);
    }
  }

  // ================= STREAM AI RESPONSE =================
  Future<void> _streamAiResponse(
    String prompt,
    String messageId, {
    bool isUpload = false,
    File? attachment,
    String? attachmentType,
  }) async {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages');

    String fullResponse = '';

    try {
      // Fetch conversation history (last 6 messages for context)
      final historySnapshot = await messagesRef
          .orderBy('timestamp', descending: true)
          .limit(6)
          .get();

      List<String> conversationHistory = [];
      for (var doc in historySnapshot.docs.reversed) {
        final data = doc.data();
        final senderId = data['senderId'] as String;
        final content = (data['content'] ?? '').toString();
        final status = (data['status'] ?? 'complete').toString();

        if (senderId == 'assistant' && status == 'thinking') {
          continue; // Skip pending thinking placeholders
        }

        final role = senderId == widget.sender ? 'User' : 'Assistant';
        conversationHistory.add('$role: $content');
      }

      final stream = EnhancedAiService.instance.streamResponse(
        prompt,
        conversationHistory: conversationHistory,
        attachment: attachment,
        attachmentType: attachmentType,
      );

      await for (final chunk in stream) {
        fullResponse += chunk;

        await messagesRef.doc(messageId).update({
          'content': fullResponse,
          'status': 'streaming',
        });
      }

      await messagesRef.doc(messageId).update({'status': 'complete'});
      _scrollToBottom();

      // Usage is already tracked at the beginning, no need to track again
    } catch (e) {
      await messagesRef.doc(messageId).update({
        'content': "Sorry, something went wrong. Please try again.",
        'status': 'complete',
      });
      // Re-throw to trigger refund in the calling method
      rethrow;
    } finally {
      _aiBusy = false;
      // Refresh rate limit display after AI response
      _refreshRateLimit();
    }
  }

  // ================= MESSAGE STREAM =================
  Stream<QuerySnapshot> _messagesStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chinatsvi Assistant"),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PreviousChatsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ================= RATE LIMIT & REWARDED AD BANNER =================
          FutureBuilder<Map<String, dynamic>>(
            future: EnhancedAiService.instance.getRateLimitInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              final rateInfo =
                  snapshot.data ??
                  {
                    'remaining': 0,
                    'limit': 10,
                    'isVerified': false,
                    'unlimited': false,
                    'uploadCount': 0,
                    'uploadLimit': 3,
                    'canUpload': true,
                  };

              final remaining = rateInfo['remaining'] as int;
              final isUnlimited = rateInfo['unlimited'] as bool;

              if (isUnlimited) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Unlimited AI access (Verified Pro ✅)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[300]!, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Points counter pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 12,
                                color: Colors.amberAccent,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$remaining pts',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Banner prompt text
                        Expanded(
                          child: Text(
                            'Get pro for unlimited or add point by ad view',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[900],
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Get Pro button
                        InkWell(
                          onTap: () => _handleGetProNavigation(context),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Get Pro',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Rewarded Ad button
                        InkWell(
                          onTap: _isAdLoading ? null : _watchRewardedAd,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _isAdLoading
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      Text(
                                        '+1 Pt',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    // Queue status indicator (only show when there's a backlog)
                    if ((_messageQueue.length > 1) ||
                        (_isProcessingQueue && _messageQueue.isNotEmpty))
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.queue,
                              size: 12,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isProcessingQueue
                                  ? 'Processing queue...'
                                  : '${_messageQueue.length} message${_messageQueue.length == 1 ? '' : 's'} in queue',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
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

          // ================= MESSAGES =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final existingDocIds = docs.map((d) => d.id).toSet();
                final activePending = _pendingMessages
                    .where((p) => !existingDocIds.contains(p.id))
                    .toList();

                if (docs.isEmpty && activePending.isEmpty) {
                  return ChatGreetingHeader(name: _farmerName);
                }

                final totalCount = docs.length + activePending.length;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    if (index < docs.length) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final isFarmer = data['senderId'] == widget.sender;

                      final content = data['content'] ?? '';
                      final status = (data['status'] ?? 'complete').toString();

                      final mediaUrl =
                          data['mediaUrl'] != null && data['mediaUrl'] != ''
                          ? data['mediaUrl'] as String
                          : null;
                      final mediaUrls =
                          (data['mediaUrls'] as List<dynamic>?)
                              ?.whereType<String>()
                              .where((url) => url.isNotEmpty)
                              .toList() ??
                          (mediaUrl == null ? <String>[] : [mediaUrl]);

                      final timestamp = data['timestamp'] != null
                          ? (data['timestamp'] as Timestamp).toDate()
                          : DateTime.now();

                      if (!isFarmer && status == 'thinking') {
                        return ThinkingIndicator(
                          key: ValueKey(doc.id),
                        );
                      }

                      File? localFile;
                      if (mediaUrl != null && _localFileByUrl.containsKey(mediaUrl)) {
                        localFile = _localFileByUrl[mediaUrl];
                      }

                      return DiagnosisMessageBubble(
                        key: ValueKey(doc.id),
                        sender: isFarmer ? '' : 'Chinatsvi AI',
                        text: content,
                        attachmentType: data['type'] ?? 'text',
                        attachmentUrl: mediaUrl,
                        attachmentUrls: mediaUrls,
                        localFile: localFile,
                        isFarmer: isFarmer,
                        timestamp: timestamp,
                        isSending: false,
                      );
                    } else {
                      final pending = activePending[index - docs.length];
                      return DiagnosisMessageBubble(
                        key: ValueKey(pending.id),
                        sender: '',
                        text: pending.text,
                        attachmentType: pending.attachmentType,
                        attachmentUrl: pending.attachmentUrl,
                        attachmentUrls: pending.attachmentUrls,
                        attachmentFiles: pending.attachments,
                        localFile: pending.attachment,
                        isFarmer: true,
                        timestamp: pending.timestamp,
                        isSending: true,
                      );
                    }
                  },
                );
              },
            ),
          ),

          // ================= INPUT =================
          DiagnosisInputBar(
            chatId: _chatId,
            sender: widget.sender,
            onSend: sendMessage,
            textController: _textController,
            focusNode: _focusNode,
          ),
        ],
      ),
    );
  }
}
