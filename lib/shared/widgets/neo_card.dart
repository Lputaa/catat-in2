import 'package:flutter/material.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';

/// Core container — 3px border + hard shadow + borderRadius 0
/// Style Guide §7.1
class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.borderOffset = AppConstants.shadowDefault,
    this.borderOn = true,
    this.padding = const EdgeInsets.all(AppConstants.spacing16),
    this.onTap,
  });

  final Widget child;
  final Color? color;
  final Offset borderOffset;
  final bool borderOn;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = color ?? NeoBrutalColors.surface;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    Widget container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        border: borderOn
            ? Border.all(color: borderColor, width: AppConstants.borderPrimary)
            : null,
        boxShadow: NeoBrutalTheme.hardShadow(
          offset: borderOffset,
          brightness: brightness,
        ),
      ),
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style.copyWith(
          color: _autoTextColor(bgColor),
        ),
        child: IconTheme(
          data: IconThemeData(color: _autoTextColor(bgColor)),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      container = GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }

  static Color _autoTextColor(Color bg) =>
      ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
          ? Colors.white
          : NeoBrutalColors.ink;
}
