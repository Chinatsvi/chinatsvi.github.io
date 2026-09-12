import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostVideoPlayer extends StatefulWidget {
  final String url;
  final double height;

  const PostVideoPlayer({
    super.key,
    required this.url,
    this.height = 220,
  });

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
      }).catchError((e) {
        debugPrint('Video init error: $e');
        if (!mounted) return;
        setState(() => _hasError = true);
      });
  }

  @override
  void didUpdateWidget(covariant PostVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller.dispose();
      _initialized = false;
      _hasError = false;
      _initController();
    }
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_hasError) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Video failed to load',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (!_initialized) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final aspect =
        _controller.value.aspectRatio > 0 ? _controller.value.aspectRatio : 16 / 9;

    return SizedBox(
      height: widget.height,
      child: AspectRatio(
        aspectRatio: aspect,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller),
            VideoProgressIndicator(_controller, allowScrubbing: true),
            Positioned(
              right: 8,
              bottom: 8,
              child: IconButton(
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  size: 36,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}