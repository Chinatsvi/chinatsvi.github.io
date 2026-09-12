import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// =======================================================
/// ✅ CCTV PREVIEW PLAYER (HLS ONLY – OPTIMIZED)
/// =======================================================
class CCTVPreviewPlayer extends StatefulWidget {
  final String hlsUrl;

  const CCTVPreviewPlayer({
    super.key,
    required this.hlsUrl,
  });

  @override
  State<CCTVPreviewPlayer> createState() => _CCTVPreviewPlayerState();
}

class _CCTVPreviewPlayerState extends State<CCTVPreviewPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  Timer? _previewTimer;

  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  @override
  void didUpdateWidget(covariant CCTVPreviewPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔥 Only reinitialize if URL changes
    if (oldWidget.hlsUrl != widget.hlsUrl) {
      _disposePlayer();
      _initializePreview();
    }
  }

  Future<void> _initializePreview() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.hlsUrl),
      );

      await _controller!.initialize();

      _chewie = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: true,
        showControls: false,
      );

      // ⏱ Pause after 5 seconds (preview only)
      _previewTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) _controller?.pause();
      });

      if (mounted) {
        setState(() {
          _loading = false;
          _error = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _disposePlayer() {
    _previewTimer?.cancel();
    _previewTimer = null;

    _chewie?.dispose();
    _controller?.dispose();

    _chewie = null;
    _controller = null;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error || _chewie == null) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CCTVFullPlayer(hlsUrl: widget.hlsUrl),
          ),
        ),
        child: Container(
          color: Colors.black12,
          child: const Center(
            child: Text(
              "Camera Offline",
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CCTVFullPlayer(hlsUrl: widget.hlsUrl),
        ),
      ),
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Chewie(controller: _chewie!),
      ),
    );
  }
}

/// =======================================================
/// ✅ FULL SCREEN CCTV PLAYER
/// =======================================================
class CCTVFullPlayer extends StatefulWidget {
  final String hlsUrl;

  const CCTVFullPlayer({
    super.key,
    required this.hlsUrl,
  });

  @override
  State<CCTVFullPlayer> createState() => _CCTVFullPlayerState();
}

class _CCTVFullPlayerState extends State<CCTVFullPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;

  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeFullPlayer();
  }

  Future<void> _initializeFullPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.hlsUrl),
      );

      await _controller!.initialize();

      _chewie = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
      );

      if (mounted) {
        setState(() {
          _loading = false;
          _error = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error || _chewie == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Camera Offline",
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = false;
                  });
                  _initializeFullPlayer();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Chewie(controller: _chewie!),
        ),
      ),
    );
  }
}

/// =======================================================
/// ✅ RECORDING PLAYER (HLS / MP4)
/// =======================================================
class RecordingPlayer extends StatefulWidget {
  final String url;

  const RecordingPlayer({
    super.key,
    required this.url,
  });

  @override
  State<RecordingPlayer> createState() => _RecordingPlayerState();
}

class _RecordingPlayerState extends State<RecordingPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;

  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeRecording();
  }

  Future<void> _initializeRecording() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );

      await _controller!.initialize();

      _chewie = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: false,
      );

      if (mounted) {
        setState(() {
          _loading = false;
          _error = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error || _chewie == null) {
      return const Center(
        child: Text(
          "Recording not available",
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Chewie(controller: _chewie!),
    );
  }
}
