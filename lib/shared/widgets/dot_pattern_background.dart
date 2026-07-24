import 'package:flutter/material.dart';
import '../../core/theme/neo_brutal_colors.dart';

/// Dot grid pattern background for Neo-Brutalism style
/// Uses RepaintBoundary + GridView for reliable rendering
class DotPatternBackground extends StatelessWidget {
  const DotPatternBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? NeoBrutalColors.bgDark : NeoBrutalColors.bg;
    final dotColor = isDark ? Colors.white : NeoBrutalColors.ink;

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // Dot pattern layer
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: DotPainter(dotColor: dotColor),
                size: Size.infinite,
              ),
            ),
          ),
          // Content layer
          child,
        ],
      ),
    );
  }
}

class DotPainter extends CustomPainter {
  DotPainter({required this.dotColor});

  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const radius = 2.0;

    // Start from top-left corner
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor;
  }
}
