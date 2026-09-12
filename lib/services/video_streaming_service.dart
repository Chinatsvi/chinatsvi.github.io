import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'cloudinary_optimizer.dart';

/// Service for managing adaptive video streaming
/// Supports HLS/DASH for smooth playback without full downloads
class VideoStreamingService {
  static final VideoStreamingService _instance = VideoStreamingService._internal();
  factory VideoStreamingService() => _instance;
  VideoStreamingService._internal();

  // Controller cache for video reuse
  final Map<String, VideoPlayerController> _controllerCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Stream controller for video events
  final StreamController<VideoEvent> _eventController = StreamController.broadcast();
  Stream<VideoEvent> get videoEvents => _eventController.stream;

  // Cache configuration
  static const Duration _maxCacheAge = Duration(minutes: 10);
  static const int _maxCachedControllers = 3;

  /// Create an optimized video controller with HLS streaming
  /// Uses Cloudinary's adaptive streaming when available
  VideoPlayerController createOptimizedController({
    required String videoUrl,
    bool autoPlay = false,
    bool loop = false,
    String? cacheKey,
  }) {
    final key = cacheKey ?? videoUrl;

    // Check if we have a cached controller
    if (_controllerCache.containsKey(key)) {
      final cached = _controllerCache[key]!;
      final timestamp = _cacheTimestamps[key];
      
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _maxCacheAge) {
        developer.log(
          '🎬 Reusing cached video controller for: $key',
          name: 'VideoStreamingService',
        );
        
        // Configure cached controller
        cached.setLooping(loop);
        if (autoPlay) {
          cached.play();
        }
        
        return cached;
      } else {
        // Cache expired, dispose old controller
        _disposeController(key);
      }
    }

    // Optimize URL for streaming
    final optimizedUrl = CloudinaryOptimizer.getOptimizedVideoUrl(
      originalUrl: videoUrl,
      streaming: true,
    );

    developer.log(
      '🎬 Creating new video controller with HLS: $optimizedUrl',
      name: 'VideoStreamingService',
    );

    // Create new controller with streaming format
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(optimizedUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    // Configure controller
    controller.setLooping(loop);

    // Cache the controller
    _cacheController(key, controller);

    return controller;
  }

  /// Cache a video controller
  void _cacheController(String key, VideoPlayerController controller) {
    // Clean up old controllers if cache is full
    if (_controllerCache.length >= _maxCachedControllers) {
      _cleanupOldestController();
    }

    _controllerCache[key] = controller;
    _cacheTimestamps[key] = DateTime.now();

    // Listen for video events
    controller.addListener(() {
      _handleVideoEvent(key, controller);
    });
  }

  /// Handle video state changes
  void _handleVideoEvent(String key, VideoPlayerController controller) {
    if (!controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      _eventController.add(VideoEvent(
        type: VideoEventType.play,
        cacheKey: key,
        position: controller.value.position,
      ));
    } else if (controller.value.position >= controller.value.duration) {
      _eventController.add(VideoEvent(
        type: VideoEventType.completed,
        cacheKey: key,
        position: controller.value.position,
      ));
    }
  }

  /// Dispose a cached controller
  void _disposeController(String key) {
    final controller = _controllerCache[key];
    if (controller != null) {
      controller.dispose();
      _controllerCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clean up oldest controller from cache
  void _cleanupOldestController() {
    if (_controllerCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    _cacheTimestamps.forEach((key, time) {
      if (oldestTime == null || time.isBefore(oldestTime!)) {
        oldestKey = key;
        oldestTime = time;
      }
    });

    if (oldestKey != null) {
      developer.log(
        '🧹 Cleaning up oldest video controller: $oldestKey',
        name: 'VideoStreamingService',
      );
      _disposeController(oldestKey!);
    }
  }

  /// Preload a video (initialize controller without playing)
  Future<void> preloadVideo(String videoUrl, {String? cacheKey}) async {
    final key = cacheKey ?? videoUrl;

    if (_controllerCache.containsKey(key)) return;

    final controller = createOptimizedController(
      videoUrl: videoUrl,
      cacheKey: key,
    );

    try {
      await controller.initialize();
      developer.log(
        '✅ Preloaded video: $key',
        name: 'VideoStreamingService',
      );
    } catch (e) {
      developer.log(
        '❌ Failed to preload video $key: $e',
        name: 'VideoStreamingService',
      );
    }
  }

  /// Get a cached controller
  VideoPlayerController? getCachedController(String key) {
    return _controllerCache[key];
  }

  /// Dispose all cached controllers
  void disposeAllControllers() {
    for (final controller in _controllerCache.values) {
      controller.dispose();
    }
    _controllerCache.clear();
    _cacheTimestamps.clear();
  }

  /// Dispose service
  void dispose() {
    disposeAllControllers();
    _eventController.close();
  }
}

/// Video event types
enum VideoEventType {
  play,
  pause,
  completed,
  error,
  buffering,
}

/// Video event data
class VideoEvent {
  final VideoEventType type;
  final String cacheKey;
  final Duration position;
  final String? error;

  VideoEvent({
    required this.type,
    required this.cacheKey,
    required this.position,
    this.error,
  });
}

/// Widget for displaying cached video player with optimized streaming
class OptimizedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool loop;
  final bool showControls;
  final VoidCallback? onVideoComplete;
  final VoidCallback? onVideoTap;
  final double? aspectRatio;
  final BoxFit fit;

  const OptimizedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.loop = false,
    this.showControls = true,
    this.onVideoComplete,
    this.onVideoTap,
    this.aspectRatio,
    this.fit = BoxFit.contain,
  });

  @override
  State<OptimizedVideoPlayer> createState() => _OptimizedVideoPlayerState();
}

class _OptimizedVideoPlayerState extends State<OptimizedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showThumbnail = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoStreamingService().createOptimizedController(
        videoUrl: widget.videoUrl,
        autoPlay: widget.autoPlay,
        loop: widget.loop,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _showThumbnail = false;
        });

        // Listen for video completion
        _controller!.addListener(_onVideoChange);

        if (widget.autoPlay) {
          _controller!.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onVideoChange() {
    if (_controller == null) return;

    final value = _controller!.value;

    // Check for completion
    if (value.position >= value.duration && value.duration > Duration.zero) {
      if (!widget.loop) {
        widget.onVideoComplete?.call();
      }
    }

    // Update buffering state
    if (value.isBuffering != _isBuffering) {
      setState(() {
        _isBuffering = value.isBuffering;
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoChange);
    // Don't dispose here - let VideoStreamingService manage caching
    // Only dispose if explicitly needed
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
      setState(() => _showThumbnail = false);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onVideoTap?.call();
        if (widget.showControls) {
          _togglePlayPause();
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            if (_isInitialized && _controller != null)
              AspectRatio(
                aspectRatio: widget.aspectRatio ?? _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),

            // Thumbnail placeholder
            if (_showThumbnail && widget.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: widget.thumbnailUrl!,
                fit: widget.fit,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),

            // Loading indicator
            if (_isBuffering || (!_isInitialized && !_hasError))
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),

            // Error display
            if (_hasError)
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load video',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ),

            // Play button overlay
            if (_isInitialized && 
                !_controller!.value.isPlaying && 
                !_isBuffering && 
                widget.showControls)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
