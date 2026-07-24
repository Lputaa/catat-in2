import 'package:flutter/material.dart';
import '../../core/theme/neo_brutal_colors.dart';

/// Standardized icon container with 3 size variants
/// Follows Neo-Brutal design: 2px border, hard edges
class NeoIconContainer extends StatelessWidget {
  const NeoIconContainer({
    super.key,
    required this.icon,
    required this.color,
    this.size = NeoIconSize.medium,
  });

  final IconData icon;
  final Color color;
  final NeoIconSize size;

  double get _dimension {
    switch (size) {
      case NeoIconSize.small:
        return 32;
      case NeoIconSize.medium:
        return 36;
      case NeoIconSize.large:
        return 44;
    }
  }

  double get _iconSize {
    switch (size) {
      case NeoIconSize.small:
        return 16;
      case NeoIconSize.medium:
        return 18;
      case NeoIconSize.large:
        return 22;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, size: _iconSize, color: color),
    );
  }
}

enum NeoIconSize {
  small,   // 32×32, icon 16
  medium,  // 36×36, icon 18
  large,   // 44×44, icon 22
}
