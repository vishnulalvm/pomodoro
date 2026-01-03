import 'package:flutter/material.dart';

class HueCycleBackground extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const HueCycleBackground({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 70), // Slower cycle
  });

  @override
  State<HueCycleBackground> createState() => _HueCycleBackgroundState();
}

class _HueCycleBackgroundState extends State<HueCycleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defined Rainbow Colors (Darker/More Intense for White Text Contrast)
    final List<Color> rainbowColors = [
      const Color(0xFF0D47A1), // Dark Blue
      const Color(0xFF01579B), // Dark Cyan Blue
      const Color(0xFF1A237E), // Dark Indigo
      const Color(0xFF311B92), // Dark Violet
      const Color(0xFF4A148C), // Dark Purple
      const Color(0xFF880E4F), // Dark Pink/Magenta
      const Color(0xFFB71C1C), // Dark Red
      const Color(0xFFE65100), // Dark Orange
      const Color(0xFFF57F17), // Dark Yellow/Gold
      const Color(0xFF827717), // Dark Lime
      const Color(0xFF1B5E20), // Dark Green
      const Color(0xFF004D40), // Dark Teal
      const Color(0xFF006064), // Dark Cyan
      const Color(0xFF0D47A1), // Cycle back to Dark Blue
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate current position in the color array
        final int totalSegments = rainbowColors.length - 1;
        final double currentPos = _controller.value * totalSegments;
        final int currentIndex = currentPos.floor();
        final int nextIndex = (currentIndex + 1) % rainbowColors.length;
        final double t = currentPos - currentIndex;

        // Smoothly interpolate between current and next color
        final Color? color = Color.lerp(
          rainbowColors[currentIndex],
          rainbowColors[nextIndex],
          t,
        );

        return Container(
          decoration: BoxDecoration(color: color ?? rainbowColors[0]),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
