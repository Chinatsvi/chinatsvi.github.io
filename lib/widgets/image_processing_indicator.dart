import 'package:flutter/material.dart';

/// Modern processing animation widget for image upload
/// Shows an animated pulse with processing text
class ImageProcessingIndicator extends StatefulWidget {
  final String message;
  final Color color;
  final double size;

  const ImageProcessingIndicator({
    super.key,
    this.message = 'Processing image...',
    this.color = Colors.green,
    this.size = 80,
  });

  @override
  State<ImageProcessingIndicator> createState() =>
      _ImageProcessingIndicatorState();
}

class _ImageProcessingIndicatorState extends State<ImageProcessingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Rotation animation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Dots animation for text
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated rings
          SizedBox(
            width: widget.size * 0.5,
            height: widget.size * 0.5,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width:
                          widget.size *
                          0.5 *
                          (0.8 + _pulseController.value * 0.2),
                      height:
                          widget.size *
                          0.5 *
                          (0.8 + _pulseController.value * 0.2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.color.withValues(
                            alpha: 0.3 + _pulseController.value * 0.3,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: widget.size * 0.35,
                      height: widget.size * 0.35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 0.1),
                      ),
                    ),
                    // Rotating icon
                    RotationTransition(
                      turns: _rotateController,
                      child: Icon(
                        Icons.image,
                        color: widget.color,
                        size: widget.size * 0.2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Animated text with dots
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _dotsController,
                builder: (context, child) {
                  final dots = '.' * ((_dotsController.value * 3).floor() + 1);
                  return Text(
                    widget.message + dots,
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Sending Image to Chinatsvi',
                style: TextStyle(
                  color: widget.color.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading effect for image messages
class ImageLoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ImageLoadingShimmer({
    super.key,
    this.width = 200,
    this.height = 150,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<ImageLoadingShimmer> createState() => _ImageLoadingShimmerState();
}

class _ImageLoadingShimmerState extends State<ImageLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[300]!, Colors.grey[200]!, Colors.grey[300]!],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, color: Colors.grey[400], size: 40),
                const SizedBox(height: 8),
                Text(
                  'Processing...',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Modern progress indicator with percentage
class UploadProgressIndicator extends StatelessWidget {
  final double progress;
  final String message;

  const UploadProgressIndicator({
    super.key,
    required this.progress,
    this.message = 'Uploading',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.green[100],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
