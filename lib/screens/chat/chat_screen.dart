import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import 'package:agribased/utils/verification_helpers.dart';
import '../profile/farmer_profile_screen.dart';

/// Voice message UI state machine.
/// idle       -> normal text input, mic button visible
/// recording  -> Top recording banner + bottom slide-to-cancel
/// preview    -> play / delete / send controls before actually uploading
enum VoiceRecordState { idle, recording, preview }

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String? chatId;

  const ChatScreen({super.key, required this.otherUserId, this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  String? _currentlyPlayingMessageId;
  final Set<String> _playedVoiceMessages = {};
  final Map<String, String> _localVoiceCache = {};
  final Set<String> _voiceDownloadsInProgress = {};

  static const int _maxVoiceCacheSizeBytes = 120 * 1024 * 1024;
  static const Duration _maxVoiceCacheAge = Duration(days: 30);

  Timer? _typingTimer;
  bool _hasText = false;
  bool _showEmoji = false;
  int _lastMessageCount = 0;
  bool _initialScrollDone = false;

  String get myId => _auth.currentUser?.uid ?? '';

  String get chatId =>
      widget.chatId ?? _generateChatId(myId, widget.otherUserId);

  String _generateChatId(String a, String b) =>
      a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';

  String _mySenderName = 'Farmer';

  Future<String> _getSenderName() async {
    if (_mySenderName != 'Farmer') return _mySenderName;
    try {
      final userSnap = await _firestore.collection('farmers').doc(myId).get();
      if (userSnap.exists) {
        _mySenderName = userSnap.data()?['user_name'] ?? _mySenderName;
      }
    } catch (_) {}
    return _mySenderName;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureChatExists();
    _updatePresence(true);
    _markAllAsRead();
    _initRecorder();
    _cleanupVoiceCache();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence(true);
      _markAllAsRead();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _updatePresence(false);
      _setTyping(false);
    }
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId ||
        oldWidget.otherUserId != widget.otherUserId) {
      _ensureChatExists();
      _updatePresence(true);
      _markAllAsRead();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setTyping(false);
    _updatePresence(false);
    _typingTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.closeRecorder();
    _recordTimer?.cancel();
    _pulseController.dispose();
    _playerStateSub?.cancel();
    _player.dispose();
    if (_previewPath != null) {
      final f = File(_previewPath!);
      f.exists().then((exists) {
        if (exists) f.delete();
      });
    }
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (animated) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  void _navigateToProfile(String targetUserId) {
    if (targetUserId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FarmerProfileScreen(
          userId: targetUserId,
          currentUserId: myId,
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required String userId,
    required String? photoUrl,
    required String name,
    double radius = 19,
    bool showBorder = true,
  }) {
    return GestureDetector(
      onTap: () => _navigateToProfile(userId),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: const Color(0xFF2E7D32),
                  width: 1.8,
                )
              : Border.all(color: Colors.white30, width: 1.5),
          boxShadow: showBorder
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFE8F5E9),
          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
              ? NetworkImage(photoUrl)
              : null,
          child: (photoUrl == null || photoUrl.isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ---------------- RECORDING ----------------
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  VoiceRecordState _voiceState = VoiceRecordState.idle;

  String? _recordPath;
  Timer? _recordTimer;
  int _recordSeconds = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Slide-to-cancel tracking
  double _dragX = 0;
  bool _isCancelling = false;

  // Preview (post-recording, pre-send)
  String? _previewPath;
  Duration? _previewDuration;
  bool _isPreviewPlaying = false;

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  String _formatSeconds(int? seconds) {
    final s = seconds ?? 0;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    if (_voiceState != VoiceRecordState.idle) return;

    final dir = await getTemporaryDirectory();
    _recordPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    try {
      await _recorder.startRecorder(toFile: _recordPath, codec: Codec.aacADTS);
      _recordSeconds = 0;
      _dragX = 0;
      _isCancelling = false;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
      setState(() => _voiceState = VoiceRecordState.recording);
      _pulseController.repeat(reverse: true);
    } catch (e) {
      debugPrint('Recorder start error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  void _handleDrag(double dx) {
    if (_voiceState != VoiceRecordState.recording) return;
    setState(() {
      _dragX = dx.clamp(-120, 0).toDouble();
      _isCancelling = _dragX < -80;
    });
  }

  Future<void> _stopRecording({required bool cancelled}) async {
    if (_voiceState != VoiceRecordState.recording) return;

    _recordTimer?.cancel();
    _recordTimer = null;
    _pulseController.stop();
    _pulseController.reset();

    final wasCancelled = cancelled || _isCancelling;
    final recordedSeconds = _recordSeconds;
    _isCancelling = false;
    _dragX = 0;

    String? path;
    try {
      path = await _recorder.stopRecorder();
    } catch (e) {
      debugPrint('Recorder stop error: $e');
    }

    // Cancelled via slide/button, or nothing usable recorded.
    if (wasCancelled || path == null) {
      if (path != null) {
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
      if (mounted) setState(() => _voiceState = VoiceRecordState.idle);
      return;
    }

    // Guard against accidental quick taps
    if (recordedSeconds < 1) {
      final f = File(path);
      if (await f.exists()) await f.delete();
      if (mounted) setState(() => _voiceState = VoiceRecordState.idle);
      return;
    }

    Duration? dur;
    try {
      await _player.stop();
      dur = await _player.setFilePath(path);
    } catch (e) {
      debugPrint('Duration read error: $e');
    }

    if (mounted) {
      setState(() {
        _previewPath = path;
        _previewDuration = dur;
        _voiceState = VoiceRecordState.preview;
      });
    }
  }

  Future<void> _togglePreviewPlayback() async {
    if (_previewPath == null) return;

    if (_isPreviewPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPreviewPlaying = false);
      return;
    }

    try {
      await _player.stop();
      await _player.setFilePath(_previewPath!);
      if (mounted) setState(() => _isPreviewPlaying = true);
      _playerStateSub?.cancel();
      _playerStateSub = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _isPreviewPlaying = false);
        }
      });
      await _player.play();
    } catch (e) {
      debugPrint('Preview playback error: $e');
    }
  }

  Future<void> _deletePreview() async {
    await _player.stop();
    if (_previewPath != null) {
      final f = File(_previewPath!);
      if (await f.exists()) await f.delete();
    }
    if (mounted) {
      setState(() {
        _previewPath = null;
        _previewDuration = null;
        _isPreviewPlaying = false;
        _voiceState = VoiceRecordState.idle;
      });
    }
  }

  Future<void> _sendPreview() async {
    if (_previewPath == null) return;
    final path = _previewPath!;
    final duration = _previewDuration;

    await _player.stop();
    if (mounted) {
      setState(() {
        _voiceState = VoiceRecordState.idle;
        _previewPath = null;
        _previewDuration = null;
        _isPreviewPlaying = false;
      });
    }

    try {
      final url = await _uploadToCloudinaryUnsigned(File(path));
      final chatRef = _firestore.collection('chats').doc(chatId);
      final msgRef = chatRef.collection('messages').doc();

      final batch = _firestore.batch();
      final payload = {
        'type': 'voice',
        'url': url,
        if (duration != null) 'duration': duration.inSeconds,
      };

      batch.set(msgRef, {
        'id': msgRef.id,
        'text': payload,
        'content': payload,
        'mediaUrl': url,
        'type': 'voice',
        'senderId': myId,
        'receiverId': widget.otherUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'isRead': false,
        'read': false,
      });
      batch.set(chatRef, {
        'participants': [myId, widget.otherUserId],
        'lastMessage': '🎤 Voice message',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {widget.otherUserId: FieldValue.increment(1)},
      }, SetOptions(merge: true));
      await batch.commit();

      _scrollToBottom(animated: true);

      // Dispatch push notification to recipient
      final senderName = await _getSenderName();
      NotificationService.instance.sendChatPushNotification(
        receiverId: widget.otherUserId,
        senderName: senderName,
        content: '🎤 Voice message',
        chatId: chatId,
        messageId: msgRef.id,
        senderId: myId,
      );

      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _toggleMessagePlayback(String messageId, String? url) async {
    if (url == null) return;
    if (_currentlyPlayingMessageId == messageId) {
      if (_player.playing) {
        await _player.stop();
        setState(() => _currentlyPlayingMessageId = null);
      } else {
        await _player.play();
      }
      return;
    }

    try {
      await _player.stop();
      final src = await _resolveVoiceSource(messageId, url);
      if (src.startsWith('http://') || src.startsWith('https://')) {
        await _player.setUrl(src);
      } else {
        await _player.setFilePath(src);
      }
      setState(() {
        _currentlyPlayingMessageId = messageId;
        _playedVoiceMessages.add(messageId);
      });
      _playerStateSub?.cancel();
      _playerStateSub = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _currentlyPlayingMessageId = null);
        }
      });
      await _player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback error: $e')),
        );
      }
    }
  }

  List<double> _getWaveformHeights(String id) {
    final seed = id.hashCode;
    final rnd = math.Random(seed);
    const basePattern = [
      0.22, 0.45, 0.3, 0.72, 0.95, 0.55, 0.8, 1.0, 0.65, 0.38,
      0.75, 0.88, 0.5, 0.32, 0.62, 0.95, 0.82, 0.45, 0.7, 0.86,
      0.58, 0.28, 0.52, 0.76, 0.42, 0.68, 0.36, 0.22
    ];
    final result = <double>[];
    for (int i = 0; i < 28; i++) {
      final base = basePattern[i % basePattern.length];
      final jitter = (rnd.nextDouble() - 0.5) * 0.22;
      result.add((base + jitter).clamp(0.18, 1.0));
    }
    return result;
  }

  Future<String> _voiceCacheFileName(String messageId, String url) async {
    try {
      final uri = Uri.parse(url);
      final lastSegment =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      final extension = lastSegment.contains('.')
          ? lastSegment.substring(lastSegment.lastIndexOf('.'))
          : '.aac';
      return 'voice_$messageId$extension';
    } catch (_) {
      return 'voice_$messageId.aac';
    }
  }

  Future<Directory> _getVoiceCacheDirectory() async {
    Directory? baseDir;
    try {
      baseDir = await getExternalStorageDirectory();
    } catch (_) {
      baseDir = null;
    }
    baseDir ??= await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${baseDir.path}/voice_messages');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<File> _voiceCacheFile(String messageId, String url) async {
    final dir = await _getVoiceCacheDirectory();
    return File('${dir.path}/${await _voiceCacheFileName(messageId, url)}');
  }

  Future<String?> _getLocalVoicePath(String messageId, String url) async {
    final cachedPath = _localVoiceCache[messageId];
    if (cachedPath != null && await File(cachedPath).exists()) {
      return cachedPath;
    }
    final file = await _voiceCacheFile(messageId, url);
    if (await file.exists()) {
      _localVoiceCache[messageId] = file.path;
      return file.path;
    }
    return null;
  }

  void _scheduleVoicePrefetch(String messageId, String url) {
    if (_localVoiceCache.containsKey(messageId) ||
        _voiceDownloadsInProgress.contains(messageId)) {
      return;
    }
    _voiceDownloadsInProgress.add(messageId);
    Future.microtask(() async {
      try {
        final localPath = await _downloadVoiceMessage(messageId, url);
        if (localPath != null && mounted) {
          setState(() {});
        }
      } finally {
        _voiceDownloadsInProgress.remove(messageId);
      }
    });
  }

  Future<String?> _downloadVoiceMessage(String messageId, String url) async {
    try {
      final file = await _voiceCacheFile(messageId, url);
      if (await file.exists()) {
        _localVoiceCache[messageId] = file.path;
        return file.path;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint('Voice download failed: ${response.statusCode}');
        return null;
      }

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsBytes(response.bodyBytes);
      _localVoiceCache[messageId] = file.path;
      await _cleanupVoiceCache();
      return file.path;
    } catch (e) {
      debugPrint('Voice download error for $messageId: $e');
      return null;
    }
  }

  Future<String> _resolveVoiceSource(String messageId, String url) async {
    final localPath = await _getLocalVoicePath(messageId, url);
    if (localPath != null) {
      return localPath;
    }
    _scheduleVoicePrefetch(messageId, url);
    return url;
  }

  Future<void> _cleanupVoiceCache() async {
    try {
      final dir = await _getVoiceCacheDirectory();
      final now = DateTime.now();
      final expireBefore = now.subtract(_maxVoiceCacheAge);
      final files = await dir.list().toList();

      for (final file in files.whereType<File>()) {
        final stat = await file.stat();
        if (stat.modified.isBefore(expireBefore)) {
          await file.delete();
          _localVoiceCache.removeWhere((_, path) => path == file.path);
        }
      }

      var totalSize = 0;
      final entries = <File>[];
      for (final file in (await dir.list().toList()).whereType<File>()) {
        totalSize += await file.length();
        entries.add(file);
      }
      entries.sort(
          (a, b) => a.statSync().modified.compareTo(b.statSync().modified));
      for (final file in entries) {
        if (totalSize <= _maxVoiceCacheSizeBytes) break;
        final size = await file.length();
        await file.delete();
        totalSize -= size;
        _localVoiceCache.removeWhere((_, path) => path == file.path);
      }
    } catch (e) {
      debugPrint('Voice cache cleanup failed: $e');
    }
  }

  // ---------------- CLOUDINARY UNSIGNED UPLOAD ----------------
  Future<Map<String, String>> _loadCloudinaryConfig() async {
    try {
      final raw = await rootBundle.loadString('lib/cloudinary_config.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final cloudName = (data['cloudName'] as String?)?.trim();
      final uploadPreset = (data['uploadPreset'] as String?)?.trim();

      if (cloudName == null || cloudName.isEmpty) {
        throw Exception(
            'Cloudinary cloud name not set in lib/cloudinary_config.json');
      }
      if (uploadPreset == null || uploadPreset.isEmpty) {
        return {'cloudName': cloudName, 'uploadPreset': ''};
      }
      return {'cloudName': cloudName, 'uploadPreset': uploadPreset};
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _uploadToCloudinaryUnsigned(File file) async {
    final cfg = await _loadCloudinaryConfig();
    final cloudName = cfg['cloudName']!;
    final preset = cfg['uploadPreset']!;

    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
    final req = http.MultipartRequest('POST', uri);
    req.fields['upload_preset'] = preset;
    req.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final url = data['secure_url'] ?? data['url'];
      if (url == null) throw Exception('Cloudinary response missing URL');
      return url as String;
    }
    throw Exception('Cloudinary upload failed: ${resp.statusCode} ${resp.body}');
  }

  // ---------------- CHAT SETUP & PRESENCE ----------------
  Future<void> _ensureChatExists() async {
    if (myId.isEmpty) return;

    final chatRef = _firestore.collection('chats').doc(chatId);
    final snap = await chatRef.get();

    if (!snap.exists) {
      await chatRef.set({
        'participants': [myId, widget.otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {myId: 0, widget.otherUserId: 0},
        'typing': {myId: false, widget.otherUserId: false},
      });
    }
  }

  Future<void> _updatePresence(bool inChat) async {
    if (myId.isEmpty) return;
    await ChatService.instance.updateChatPresence(chatId, myId, inChat: inChat);
  }

  Future<void> _markAllAsRead() async {
    if (myId.isEmpty) return;
    await ChatService.instance.markMessagesDelivered(chatId, myId);
    await ChatService.instance.markMessagesRead(chatId, myId);
  }

  Future<void> _setTyping(bool typing) async {
    if (myId.isEmpty) return;
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'typing': {myId: typing},
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ---------------- SEND MESSAGE ----------------
  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || myId.isEmpty) return;

    _textCtrl.clear();
    setState(() => _hasText = false);
    _setTyping(false);

    final chatRef = _firestore.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final senderName = await _getSenderName();

    await _firestore.runTransaction((tx) async {
      tx.set(msgRef, {
        'id': msgRef.id,
        'text': text,
        'content': text,
        'senderId': myId,
        'senderName': senderName,
        'receiverId': widget.otherUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'isRead': false,
        'read': false,
      });

      tx.set(chatRef, {
        'participants': [myId, widget.otherUserId],
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {widget.otherUserId: FieldValue.increment(1)},
      }, SetOptions(merge: true));
    });

    // Dispatch push notification to recipient
    NotificationService.instance.sendChatPushNotification(
      receiverId: widget.otherUserId,
      senderName: senderName,
      content: text,
      chatId: chatId,
      messageId: msgRef.id,
      senderId: myId,
    );

    _scrollToBottom(animated: true);
  }

  // ---------------- IMAGE PICK ----------------
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (image == null) return;

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    if (!await File(image.path).exists()) {
      throw Exception('Image file does not exist: ${image.path}');
    }

    final ref = FirebaseStorage.instance.ref().child(
          'chat_images/$chatId/$fileName.jpg',
        );

    await ref.putFile(File(image.path));
    final imageUrl = await ref.getDownloadURL();

    final chatRef = _firestore.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final senderName = await _getSenderName();

    final batch = _firestore.batch();
    final payload = {'type': 'image', 'url': imageUrl};

    batch.set(msgRef, {
      'id': msgRef.id,
      'text': payload,
      'content': payload,
      'mediaUrl': imageUrl,
      'type': 'image',
      'senderId': myId,
      'receiverId': widget.otherUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'sent',
      'isRead': false,
      'read': false,
    });
    batch.set(chatRef, {
      'participants': [myId, widget.otherUserId],
      'lastMessage': '📷 Photo',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': {widget.otherUserId: FieldValue.increment(1)},
    }, SetOptions(merge: true));
    await batch.commit();

    _scrollToBottom(animated: true);

    // Dispatch push notification to recipient
    NotificationService.instance.sendChatPushNotification(
      receiverId: widget.otherUserId,
      senderName: senderName,
      content: '📷 Photo',
      chatId: chatId,
      messageId: msgRef.id,
      senderId: myId,
    );
  }

  void _toggleEmoji() {
    FocusScope.of(context).unfocus();
    setState(() => _showEmoji = !_showEmoji);
  }

  // ---------------- LAST SEEN FORMATTER ----------------
  String _formatLastSeen(dynamic lastSeenVal) {
    if (lastSeenVal == null) return 'Offline';
    DateTime? dt;
    if (lastSeenVal is Timestamp) {
      dt = lastSeenVal.toDate();
    } else if (lastSeenVal is String) {
      dt = DateTime.tryParse(lastSeenVal);
    } else if (lastSeenVal is DateTime) {
      dt = lastSeenVal;
    }
    if (dt == null) return 'Offline';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 45) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min ago';
    }

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final seenDate = DateTime(dt.year, dt.month, dt.day);

    final timeStr = DateFormat('HH:mm').format(dt);

    if (seenDate == today) {
      return 'today at $timeStr';
    } else if (seenDate == yesterday) {
      return 'yesterday at $timeStr';
    } else if (now.year == dt.year) {
      return '${DateFormat('d MMM').format(dt)} at $timeStr';
    } else {
      return '${DateFormat('d MMM yyyy').format(dt)} at $timeStr';
    }
  }

  // ---------------- APP BAR WITH PRESENCE ----------------
  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: const Color(0xFF1B5E20),
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('farmers')
            .doc(widget.otherUserId)
            .snapshots(),
        builder: (context, userSnap) {
          final userData =
              userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final userName = userData['user_name'] ?? 'User';

          final isVerified = userData['isVerified'] == true;
          final verificationStatus = userData['verificationStatus'] ?? '';
          final verificationPaid = userData['verificationPaid'] == true;
          final verificationPaidRaw =
              userData['verificationPaidAt'] ?? userData['verificationPaidat'];
          final isPaymentExpired =
              isVerificationPaymentExpired(verificationPaidRaw);
          final showTick = isVerified &&
              verificationStatus == 'approved' &&
              verificationPaid &&
              !isPaymentExpired;

          return StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('chats').doc(chatId).snapshots(),
            builder: (context, chatSnap) {
              final chatData =
                  chatSnap.data?.data() as Map<String, dynamic>? ?? {};

              // Check typing status
              final typingMap =
                  chatData['typing'] as Map<String, dynamic>? ?? {};
              final isTyping = typingMap[widget.otherUserId] == true;

              // Check presence status
              final presenceMap =
                  chatData['presence'] as Map<String, dynamic>? ?? {};
              final otherPresence =
                  presenceMap[widget.otherUserId] as Map<String, dynamic>? ??
                      {};
              final inChat = otherPresence['inChat'] == true;

              // Check lastSeen
              final lastSeenVal = otherPresence['lastSeen'] ??
                  (chatData['participantsInfo'] as Map<String, dynamic>?)?[
                      widget.otherUserId]?['lastSeen'] ??
                  userData['lastSeen'];

              String statusText;
              Color statusColor = Colors.white70;

              if (isTyping) {
                statusText = 'typing...';
                statusColor = const Color(0xFFB9F6CA);
              } else if (inChat || userData['isOnline'] == true) {
                statusText = 'Online';
                statusColor = const Color(0xFF69F0AE);
              } else if (lastSeenVal != null) {
                statusText = 'Last seen ${_formatLastSeen(lastSeenVal)}';
              } else {
                statusText = 'Offline';
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _navigateToProfile(widget.otherUserId),
                child: Row(
                  children: [
                    _buildAvatar(
                      userId: widget.otherUserId,
                      photoUrl: userData['profile_pic'] as String?,
                      name: userName,
                      radius: 19,
                      showBorder: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.15,
                                  ),
                                ),
                              ),
                              if (showTick) ...[
                                const SizedBox(width: 5),
                                Image.asset(
                                  'assets/icon/verification_tick.png',
                                  width: 17,
                                  height: 17,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1.5),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (statusText == 'Online') ...[
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF69F0AE),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              Flexible(
                                child: Text(
                                  statusText,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11.5,
                                    fontWeight:
                                        (isTyping || statusText == 'Online')
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                    fontStyle: isTyping
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------- TOP VOICE RECORDING BANNER (THIN & ATTRACTIVE GREEN) ----------------
  Widget _buildTopRecordingBar() {
    if (_voiceState != VoiceRecordState.recording) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: _isCancelling
            ? const LinearGradient(
                colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
              )
            : const LinearGradient(
                colors: [Color(0xFFF2FBF4), Color(0xFFE8F5E9)],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isCancelling
              ? const Color(0xFFFECDD3)
              : const Color(0xFFA7F3D0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isCancelling
                    ? Colors.red
                    : const Color(0xFF2E7D32))
                .withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isCancelling
                    ? const Color(0xFFE11D48)
                    : const Color(0xFF16A34A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isCancelling
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF16A34A))
                        .withValues(alpha: 0.45),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            _isCancelling ? 'Cancelling...' : 'Recording...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isCancelling
                  ? Colors.red.shade700
                  : const Color(0xFF166534),
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(width: 7),
          // Animated mini soundwave bars
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              final val = _pulseAnimation.value; // 1.0 to 1.4
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 2,
                    height: (6 * (val - 0.2)).clamp(4.0, 12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 2,
                    height: (12 * (1.5 - val)).clamp(4.0, 13.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 2,
                    height: (10 * val).clamp(5.0, 14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 2,
                    height: (8 * (1.6 - val)).clamp(4.0, 11.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              _formatSeconds(_recordSeconds),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF15803D),
              ),
            ),
          ),
          const Spacer(),
          // Cancel Button
          InkWell(
            onTap: () => _stopRecording(cancelled: true),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                children: [
                  Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Stop & Done Button
          GestureDetector(
            onTap: () => _stopRecording(cancelled: false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 11.5,
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
    );
  }

  // ---------------- DATE SEPARATOR ----------------
  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      if (messageDate == yesterday) {
        dateText = 'Yesterday';
      } else if (now.year == date.year) {
        dateText = DateFormat('MMMM d').format(date);
      } else {
        dateText = DateFormat('MMMM d, yyyy').format(date);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- TIME FORMATTING ----------------
  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    return DateFormat('HH:mm').format(dateTime);
  }

  Widget _buildMessageTime(Map<String, dynamic> messageData, bool isMe) {
    final rawTs = messageData['timestamp'] ??
        messageData['createdAt'] ??
        messageData['sent_at'];
    final timestamp = rawTs is Timestamp ? rawTs : null;
    final timeString = _formatMessageTime(timestamp);

    if (timeString.isEmpty) return const SizedBox.shrink();

    return Text(
      timeString,
      style: TextStyle(
        fontSize: 10.5,
        color: isMe ? Colors.white.withOpacity(0.75) : const Color(0xFF78909C),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // ---------------- MESSAGE STATUS TICKS ----------------
  Widget _buildMessageStatus(Map<String, dynamic> messageData, bool isMe) {
    if (!isMe) return const SizedBox.shrink();

    final status = messageData['status'] as String? ?? 'sent';
    final isRead =
        messageData['isRead'] == true || messageData['read'] == true;

    Color tickColor = Colors.white70;
    IconData tickIcon = Icons.done;

    if (isRead || status == 'read') {
      tickIcon = Icons.done_all;
      tickColor = const Color(0xFF38BDF8); // WhatsApp-style blue
    } else if (status == 'delivered') {
      tickIcon = Icons.done_all;
      tickColor = Colors.white70;
    } else {
      tickIcon = Icons.done;
      tickColor = Colors.white70;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Icon(tickIcon, size: 14.5, color: tickColor),
    );
  }

  // ---------------- MESSAGES STREAM ----------------
  Widget _messages() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('farmers').doc(myId).snapshots(),
      builder: (context, myUserSnap) {
        final myUserData =
            myUserSnap.data?.data() as Map<String, dynamic>? ?? {};
        final myUserAvatar = myUserData['profile_pic'] as String?;
        final myUserName = myUserData['user_name'] as String? ?? 'Me';

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('farmers')
              .doc(widget.otherUserId)
              .snapshots(),
          builder: (context, otherUserSnap) {
            final otherUserData =
                otherUserSnap.data?.data() as Map<String, dynamic>? ?? {};
            final otherUserAvatar = otherUserData['profile_pic'] as String?;
            final otherUserName =
                otherUserData['user_name'] as String? ?? 'User';

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages: ${snap.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawDocs = snap.data!.docs;

                // Auto-mark incoming unread messages as read
                final hasUnread = rawDocs.any((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final senderId = data['senderId'] ?? data['sender_id'];
                  final isRead =
                      data['isRead'] == true || data['read'] == true;
                  return senderId != myId && !isRead;
                });

                if (hasUnread) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markAllAsRead();
                  });
                }

                if (rawDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFC8E6C9), width: 1.5),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 36,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say hello to start the conversation!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ORDER: Chronological (Oldest at top index 0 -> Newest at bottom index N-1)
                final docs = rawDocs.reversed.toList();

                // Auto scroll to bottom upon loading or when new messages arrive
                if (!_initialScrollDone || docs.length != _lastMessageCount) {
                  _lastMessageCount = docs.length;
                  _initialScrollDone = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom(animated: false);
                  });
                }

                return ListView.builder(
                  reverse: false,
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i];
                    final data = m.data() as Map<String, dynamic>;
                    final senderId =
                        data['senderId'] ?? data['sender_id'] ?? '';
                    final isMe = senderId == myId;
                    final message = data['text'] ?? data['content'] ?? '';
                    final rawTimestamp = data['timestamp'] ??
                        data['createdAt'] ??
                        data['sent_at'];
                    final timestamp =
                        rawTimestamp is Timestamp ? rawTimestamp : null;

                    DateTime? previousMessageDate;
                    if (i > 0) {
                      final previousData =
                          docs[i - 1].data() as Map<String, dynamic>;
                      final previousTs = previousData['timestamp'] ??
                          previousData['createdAt'] ??
                          previousData['sent_at'];
                      if (previousTs is Timestamp) {
                        previousMessageDate = previousTs.toDate();
                      }
                    }

                    final currentMessageDate = timestamp?.toDate();
                    bool showDateSeparator = false;

                    if (currentMessageDate != null) {
                      if (i == 0 || previousMessageDate == null) {
                        showDateSeparator = true;
                      } else {
                        final currentDate = DateTime(
                          currentMessageDate.year,
                          currentMessageDate.month,
                          currentMessageDate.day,
                        );
                        final previousDate = DateTime(
                          previousMessageDate.year,
                          previousMessageDate.month,
                          previousMessageDate.day,
                        );
                        showDateSeparator = currentDate != previousDate;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateSeparator && currentMessageDate != null)
                          _buildDateSeparator(currentMessageDate),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Left Avatar (Receiver / Other User)
                              if (!isMe) ...[
                                _buildAvatar(
                                  userId: widget.otherUserId,
                                  photoUrl: otherUserAvatar,
                                  name: otherUserName,
                                  radius: 19,
                                  showBorder: true,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Builder(builder: (context) {
                                  if ((message is Map &&
                                          message['type'] == 'image') ||
                                      (data['type'] == 'image' &&
                                          data['mediaUrl'] != null)) {
                                    return _buildImageBubble(
                                      m,
                                      data,
                                      (message is Map
                                              ? message['url']
                                              : data['mediaUrl']) ??
                                          '',
                                      isMe,
                                    );
                                  } else if ((message is Map &&
                                          message['type'] == 'voice') ||
                                      (data['type'] == 'voice' &&
                                          data['mediaUrl'] != null)) {
                                    return _buildVoiceBubble(m, data, isMe);
                                  } else {
                                    return _buildTextBubble(
                                        m, data, message.toString(), isMe);
                                  }
                                }),
                              ),
                              // Right Avatar (Sender / Current User)
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                _buildAvatar(
                                  userId: myId,
                                  photoUrl: myUserAvatar,
                                  name: myUserName,
                                  radius: 19,
                                  showBorder: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------------- TEXT BUBBLE ----------------
  Widget _buildTextBubble(
    QueryDocumentSnapshot m,
    Map<String, dynamic> data,
    String text,
    bool isMe,
  ) {
    final bubbleColor = isMe ? const Color(0xFF2E7D32) : Colors.white;

    return GestureDetector(
      onDoubleTap: () => _showDeleteMessageDialog(m.id, data),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.70,
            ),
            margin: EdgeInsets.only(
              left: isMe ? 0 : 5,
              right: isMe ? 5 : 0,
            ),
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 5),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    )
                  : null,
              color: isMe ? null : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: isMe
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              border: isMe
                  ? null
                  : Border.all(color: const Color(0xFFE2E8E2), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: isMe
                      ? const Color(0xFF1B5E20).withOpacity(0.18)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 14.5,
                    height: 1.32,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildMessageTime(data, isMe),
                    if (isMe) ...[
                      const SizedBox(width: 2),
                      _buildMessageStatus(data, isMe),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Tail pointing to avatar
          Positioned(
            bottom: 0,
            right: isMe ? 0 : null,
            left: !isMe ? 0 : null,
            child: CustomPaint(
              size: const Size(6, 12),
              painter: BubbleTailPainter(
                color: bubbleColor,
                isMe: isMe,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- IMAGE BUBBLE ----------------
  Widget _buildImageBubble(
    QueryDocumentSnapshot m,
    Map<String, dynamic> data,
    String imageUrl,
    bool isMe,
  ) {
    return GestureDetector(
      onDoubleTap: () => _showDeleteMessageDialog(m.id, data),
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 0 : 4,
          right: isMe ? 4 : 0,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1B5E20) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrl,
                width: 220,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 220,
                    height: 180,
                    color: const Color(0xFFF1F5F2),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation(Color(0xFF2E7D32)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMessageTime(data, true),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      _buildMessageStatus(data, isMe),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- VOICE MESSAGE BUBBLE ----------------
  Widget _buildVoiceBubble(
    QueryDocumentSnapshot m,
    Map<String, dynamic> data,
    bool isMe,
  ) {
    final message = data['text'] is Map
        ? data['text'] as Map
        : (data['content'] is Map ? data['content'] as Map : {});
    final url = (message['url'] ?? data['mediaUrl'] ?? data['content_url'])
        as String?;
    final storedSeconds = message['duration'] is int
        ? message['duration'] as int
        : (data['duration'] is int ? data['duration'] as int : null);
    final storedDuration =
        storedSeconds != null ? Duration(seconds: storedSeconds) : null;
    final isThisPlaying = _currentlyPlayingMessageId == m.id;
    final isDownloading =
        url != null && _voiceDownloadsInProgress.contains(m.id);
    final isPlayed = _playedVoiceMessages.contains(m.id) ||
        data['played'] == true ||
        (isMe && (data['isRead'] == true || data['read'] == true));
    final bubbleColor = isMe ? const Color(0xFF2E7D32) : Colors.white;

    if (!isMe && url != null) {
      _scheduleVoicePrefetch(m.id, url);
    }

    final waveformHeights = _getWaveformHeights(m.id);

    // Play button colors: played voice message play button changes to blue color
    Color playBtnBg;
    Color playIconColor;
    if (isPlayed || isThisPlaying) {
      playBtnBg = isMe
          ? const Color(0xFF0284C7)
          : const Color(0xFFE0F2FE);
      playIconColor = isMe
          ? Colors.white
          : const Color(0xFF0284C7);
    } else {
      playBtnBg = isMe
          ? Colors.white.withOpacity(0.2)
          : const Color(0xFFE8F5E9);
      playIconColor = isMe
          ? Colors.white
          : const Color(0xFF2E7D32);
    }

    return GestureDetector(
      onDoubleTap: () => _showDeleteMessageDialog(m.id, data),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(
              maxWidth: 245,
              minWidth: 195,
            ),
            margin: EdgeInsets.only(
              left: isMe ? 0 : 5,
              right: isMe ? 5 : 0,
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 6),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    )
                  : null,
              color: isMe ? null : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: isMe
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              border: isMe
                  ? null
                  : Border.all(color: const Color(0xFFE2E8E2), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: isMe
                      ? const Color(0xFF1B5E20).withOpacity(0.18)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Play button + centered waveform
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: playBtnBg,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          isDownloading
                              ? Icons.download_for_offline
                              : (isThisPlaying && _player.playing)
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          color: playIconColor,
                          size: 24,
                        ),
                        onPressed: () => _toggleMessagePlayback(m.id, url),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StreamBuilder<Duration>(
                        stream: _player.positionStream,
                        builder: (context, snap) {
                          final pos = (isThisPlaying ? snap.data : null) ??
                              Duration.zero;
                          final total = (isThisPlaying
                                  ? _player.duration
                                  : null) ??
                              storedDuration ??
                              Duration.zero;
                          final progress = total.inMilliseconds > 0
                              ? (pos.inMilliseconds / total.inMilliseconds)
                                  .clamp(0.0, 1.0)
                              : 0.0;

                          final activeColor = isMe
                              ? (isPlayed ? const Color(0xFF38BDF8) : Colors.white)
                              : (isPlayed ? const Color(0xFF0284C7) : const Color(0xFF2E7D32));
                          final inactiveColor = isMe
                              ? Colors.white.withOpacity(0.35)
                              : const Color(0xFFCBD5E1);

                          return SizedBox(
                            height: 26,
                            child: CustomPaint(
                              painter: VoiceWaveformPainter(
                                heights: waveformHeights,
                                progress: isThisPlaying ? progress : 0.0,
                                activeColor: activeColor,
                                inactiveColor: inactiveColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Bottom Row: Duration (left) ....... Sent time + checkmarks (right)
                Padding(
                  padding: const EdgeInsets.only(left: 44, right: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StreamBuilder<Duration>(
                        stream: _player.positionStream,
                        builder: (context, snap) {
                          final label = isThisPlaying
                              ? _formatSeconds(
                                  (snap.data ?? Duration.zero).inSeconds,
                                )
                              : _formatSeconds(
                                  storedDuration?.inSeconds ?? 0,
                                );
                          return Text(
                            label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isMe
                                  ? Colors.white.withOpacity(0.75)
                                  : const Color(0xFF64748B),
                            ),
                          );
                        },
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMessageTime(data, isMe),
                          if (isMe) ...[
                            const SizedBox(width: 2),
                            _buildMessageStatus(data, isMe),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tail pointing to avatar
          Positioned(
            bottom: 0,
            right: isMe ? 0 : null,
            left: !isMe ? 0 : null,
            child: CustomPaint(
              size: const Size(6, 12),
              painter: BubbleTailPainter(
                color: bubbleColor,
                isMe: isMe,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- INPUT BAR ----------------
  Widget _chatInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE0E7E1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_voiceState == VoiceRecordState.idle) ...[
                        IconButton(
                          padding: const EdgeInsets.only(left: 6, bottom: 8),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _showEmoji
                                ? Icons.keyboard
                                : Icons.emoji_emotions_outlined,
                            color: const Color(0xFF4B6354),
                            size: 22,
                          ),
                          onPressed: _toggleEmoji,
                        ),
                      ],
                      Expanded(child: _buildMiddleContent()),
                      if (_voiceState == VoiceRecordState.idle) ...[
                        IconButton(
                          padding: const EdgeInsets.only(right: 6, bottom: 8),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.camera_alt_outlined,
                            color: Color(0xFF4B6354),
                            size: 22,
                          ),
                          onPressed: _pickImage,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildTrailingControl(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiddleContent() {
    switch (_voiceState) {
      case VoiceRecordState.recording:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Transform.translate(
            offset: Offset(_dragX, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_left,
                  color: _isCancelling ? Colors.red : const Color(0xFF2E7D32),
                  size: 20,
                ),
                Text(
                  _isCancelling ? 'Release to cancel' : 'Slide left to cancel',
                  style: TextStyle(
                    color:
                        _isCancelling ? Colors.red : const Color(0xFF166534),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );

      case VoiceRecordState.preview:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 22),
                onPressed: _deletePreview,
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isPreviewPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: const Color(0xFF2E7D32),
                  size: 28,
                ),
                onPressed: _togglePreviewPlayback,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, snap) {
                    final total = _previewDuration ?? Duration.zero;
                    final pos = _isPreviewPlaying
                        ? (snap.data ?? Duration.zero)
                        : Duration.zero;
                    final progress = total.inMilliseconds > 0
                        ? (pos.inMilliseconds / total.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;
                    return Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: const Color(0xFFDCFCE7),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF2E7D32)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatSeconds(total.inSeconds),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );

      case VoiceRecordState.idle:
        return TextField(
          controller: _textCtrl,
          minLines: 1,
          maxLines: 5,
          onTap: () {
            if (_showEmoji) {
              setState(() => _showEmoji = false);
            }
          },
          onChanged: (v) {
            setState(() => _hasText = v.isNotEmpty);
            _typingTimer?.cancel();
            _setTyping(true);
            _typingTimer =
                Timer(const Duration(seconds: 2), () => _setTyping(false));
          },
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1E293B),
          ),
          decoration: const InputDecoration(
            hintText: 'Message...',
            hintStyle: TextStyle(color: Color(0xFF8E9E94), fontSize: 15),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: InputBorder.none,
            isDense: true,
          ),
        );
    }
  }

  /// The mic/send button.
  Widget _buildTrailingControl() {
    if (_voiceState == VoiceRecordState.preview) {
      return Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          onPressed: _sendPreview,
        ),
      );
    }

    if (_voiceState == VoiceRecordState.idle && _hasText) {
      return Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          onPressed: _sendMessage,
        ),
      );
    }

    // idle-without-text OR actively recording: same gesture-holding button
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressMoveUpdate: (details) =>
          _handleDrag(details.offsetFromOrigin.dx),
      onLongPressEnd: (_) => _stopRecording(cancelled: false),
      onLongPressCancel: () => _stopRecording(cancelled: true),
      onTap: () {
        if (_voiceState == VoiceRecordState.idle) {
          _startRecording();
        } else {
          _stopRecording(cancelled: false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _voiceState == VoiceRecordState.recording
              ? (_isCancelling ? Colors.grey : const Color(0xFF0284C7))
              : const Color(0xFF2E7D32),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_voiceState == VoiceRecordState.recording
                      ? const Color(0xFF0284C7)
                      : const Color(0xFF2E7D32))
                  .withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _voiceState == VoiceRecordState.recording
              ? Icons.stop_rounded
              : Icons.mic_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  void _showDeleteMessageDialog(
    String messageId,
    Map<String, dynamic> msgData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Message'),
          content: const Text(
            'Are you sure you want to delete this message? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _firestore
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .doc(messageId)
                      .delete();

                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message deleted successfully'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting message: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _appBar(),
      body: Stack(
        children: [
          // Subtle Agricultural Pattern Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF4F6F4),
              child: CustomPaint(
                painter: AgriculturalPatternPainter(),
              ),
            ),
          ),
          // Main Chat Body
          SafeArea(
            child: Column(
              children: [
                // Prominent Voice Recording Banner at the TOP (Sleek Blue)
                _buildTopRecordingBar(),
                Expanded(child: _messages()),
                if (_showEmoji)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (_, e) {
                        _textCtrl.text += e.emoji;
                        setState(() => _hasText = true);
                      },
                    ),
                  ),
                _chatInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that creates audio waveform vertical bars with playback progress
class VoiceWaveformPainter extends CustomPainter {
  final List<double> heights;
  final double progress; // 0.0 to 1.0
  final Color activeColor;
  final Color inactiveColor;

  VoiceWaveformPainter({
    required this.heights,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty) return;

    final barCount = heights.length;
    const double spacing = 2.2;
    final double totalSpacing = spacing * (barCount - 1);
    final double barWidth =
        ((size.width - totalSpacing) / barCount).clamp(1.5, 3.5);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final barProgress = i / barCount;
      final isBarActive = progress > 0.0 && progress >= barProgress;
      final paint = isBarActive ? activePaint : inactivePaint;

      final barH = (heights[i] * size.height).clamp(3.0, size.height);
      final x = i * (barWidth + spacing);
      final y = centerY - (barH / 2);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VoiceWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.heights != heights;
  }
}

/// Custom painter that creates speech bubble tails connecting towards the avatars
class BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isMe;

  const BubbleTailPainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isMe) {
      // Outgoing tail pointing bottom-right
      path.moveTo(0, 0);
      path.quadraticBezierTo(
          size.width * 0.4, size.height * 0.5, size.width, size.height);
      path.quadraticBezierTo(size.width * 0.2, size.height * 0.9, 0, size.height);
      path.close();
    } else {
      // Incoming tail pointing bottom-left
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(
          size.width * 0.6, size.height * 0.5, 0, size.height);
      path.quadraticBezierTo(
          size.width * 0.8, size.height * 0.9, size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isMe != isMe;
}

/// Custom painter that creates a faint, elegant agricultural/botanical background
/// pattern with delicate leaf contours, wheat sprigs, seedling curves, and dots.
class AgriculturalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.038)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final dotPaint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    const double stepX = 85.0;
    const double stepY = 85.0;

    for (double y = 0; y < size.height + stepY; y += stepY) {
      for (double x = 0; x < size.width + stepX; x += stepX) {
        final int index = ((x / stepX) + (y / stepY)).toInt();

        if (index % 3 == 0) {
          // Draw subtle leaf sprig
          final path = Path();
          path.moveTo(x, y + 14);
          path.quadraticBezierTo(x + 12, y + 2, x + 16, y - 8);
          path.quadraticBezierTo(x + 4, y, x, y + 14);

          path.moveTo(x + 8, y + 4);
          path.quadraticBezierTo(x + 16, y + 6, x + 20, y + 2);

          canvas.drawPath(path, paint);
        } else if (index % 3 == 1) {
          // Draw subtle wheat / sprout head
          final path = Path();
          path.moveTo(x + 10, y + 16);
          path.lineTo(x + 10, y - 6);

          path.moveTo(x + 10, y + 2);
          path.quadraticBezierTo(x + 16, y, x + 18, y - 4);

          path.moveTo(x + 10, y + 8);
          path.quadraticBezierTo(x + 4, y + 6, x + 2, y + 2);

          canvas.drawPath(path, paint);
        } else {
          // Subtle dot constellation
          canvas.drawCircle(Offset(x + 6, y + 6), 1.5, dotPaint);
          canvas.drawCircle(Offset(x + 14, y + 14), 1.2, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
