import 'dart:async';
import 'package:flutter/material.dart';

/// Animated thinking indicator for AI responses
class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Timer _messageTimer;

  final List<String> _messages = [
    'Diving',
    'Thinking',
    'Analyzing',
    'Meditating',
    'Planning',
    'Evaluating',
    'Organising',
  ];
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);

    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _messageTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Falls back to a fresh agri-green if the theme has no primary color set.
    final Color themeGreen =
        Theme.of(context).colorScheme.primary != Colors.blue
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFF2E7D32);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingOrb(controller: _pulseController, color: themeGreen),
        const SizedBox(width: 8),
        _ShimmerText(
          key: ValueKey(_currentMessageIndex),
          text: _messages[_currentMessageIndex],
          controller: _shimmerController,
          baseColor: themeGreen,
        ),
      ],
    );
  }
}

/// Text with a soft light sweeping across it in the theme's green tone,
/// with a subtle fade-in when the message changes.
class _ShimmerText extends StatelessWidget {
  const _ShimmerText({
    super.key,
    required this.text,
    required this.controller,
    required this.baseColor,
  });

  final String text;
  final AnimationController controller;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    final Color dim = baseColor.withOpacity(0.45);
    final Color mid = baseColor;
    final Color bright = Color.lerp(baseColor, Colors.white, 0.55)!;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: AnimatedBuilder(
        key: ValueKey(text),
        animation: controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              final t = controller.value;
              return LinearGradient(
                colors: [dim, mid, bright, mid, dim],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                begin: Alignment(-1.5 + 3 * t, 0),
                end: Alignment(0.5 + 3 * t, 0),
              ).createShader(bounds);
            },
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A small breathing orb with a soft green glow, replacing the 3 dots.
class _PulsingOrb extends StatelessWidget {
  const _PulsingOrb({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color lightGreen = Color.lerp(color, Colors.lightGreenAccent, 0.4)!;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 0.75 + 0.25 * Curves.easeInOut.transform(controller.value);
        final glow = 0.15 + 0.35 * controller.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(glow),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cardless thinking message bubble
class ThinkingMessageBubble extends StatelessWidget {
  const ThinkingMessageBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'Chinatsvi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          ThinkingIndicator(),
        ],
      ),
    );
  }
}