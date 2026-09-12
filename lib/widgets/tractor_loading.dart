import 'package:flutter/material.dart';

class TractorLoading extends StatefulWidget {
  const TractorLoading({super.key});

  @override
  State<TractorLoading> createState() => _TractorLoadingState();
}

class _TractorLoadingState extends State<TractorLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Add minimum display time
  static const Duration _minDisplayTime = Duration(seconds: 6);
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Initialize with default value, will be updated in didChangeDependencies
    _animation = Tween<double>(
      begin: -100, // Start off-screen on the left
      end: 100, // Will be updated to screen width in didChangeDependencies
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update animation to go from screen start to screen end
    final screenWidth = MediaQuery.of(context).size.width;
    debugPrint('🚜 Screen width: ${screenWidth}px');
    debugPrint('🚜 Animation range: -100 to ${screenWidth + 100}px');

    _animation = Tween<double>(
      begin: -100, // Start off-screen on the left
      end: screenWidth + 100, // End off-screen on the right
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  // Check if minimum display time has passed
  bool _canHide() {
    return DateTime.now().difference(_startTime) >= _minDisplayTime;
  }

  @override
  Widget build(BuildContext context) {
    return _canHide()
        ? SizedBox.shrink()
        : SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Field line
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Container(height: 4, color: Colors.brown),
                ),

                // Moving tractor - moves from left to right horizontally
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final currentValue = _animation.value;
                    debugPrint(
                      '🚜 Current tractor position: ${currentValue.toStringAsFixed(1)}px',
                    );

                    return Transform.translate(
                      offset: Offset(currentValue, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tractor icon (using agricultural icon)
                          Icon(
                            Icons.agriculture,
                            size: 50,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Field decorations
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    width: 8,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 30,
                  child: Container(
                    width: 8,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 60,
                  child: Container(
                    width: 8,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade700,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
