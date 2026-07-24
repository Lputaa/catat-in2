import 'package:flutter/material.dart';
import '../../core/theme/neo_brutal_colors.dart';

/// Hard-edge progress bar matching Neo-Brutal style
/// Replaces Material LinearProgressIndicator for consistency
class NeoProgressBar extends StatelessWidget {
  const NeoProgressBar({
    super.key,
    required this.progress,
    this.height = 10,
    this.color,
    this.backgroundColor = NeoBrutalColors.muted,
  });

  final double progress;
  final double height;
  final Color? color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _colorForProgress(progress);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: NeoBrutalColors.ink, width: 1),
            ),
          ),
          // Progress fill
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(color: effectiveColor),
          ),
        ],
      ),
    );
  }

  static Color _colorForProgress(double p) {
    if (p > 1.0) return NeoBrutalColors.danger;
    if (p >= 0.8) return NeoBrutalColors.orange;
    return NeoBrutalColors.success;
  }
}
