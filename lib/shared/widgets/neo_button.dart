import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';

/// Pressable button with hard shadow animation
/// On press: shadow disappears, translate offset/2 down-right
/// Style Guide §7.1
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.textColor,
    this.icon,
    this.borderOffset = AppConstants.shadowSmall,
    this.fontSize,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppConstants.spacing24,
      vertical: AppConstants.spacing12,
    ),
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final Offset borderOffset;
  final double? fontSize;
  final EdgeInsets padding;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = widget.color ?? NeoBrutalColors.primary;
    final txtColor = widget.textColor ??
        (ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
            ? Colors.white
            : NeoBrutalColors.ink);
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        curve: Curves.linear,
        transform: _pressed
            ? (Matrix4.identity()
              ..translateByDouble(
                widget.borderOffset.dx / 2,
                widget.borderOffset.dy / 2,
                0.0,
                1.0,
              ))
            : Matrix4.identity(),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: AppConstants.borderPrimary),
          boxShadow: _pressed
              ? []
              : NeoBrutalTheme.hardShadow(
                  offset: widget.borderOffset,
                  brightness: brightness,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: txtColor, size: 20),
              const SizedBox(width: AppConstants.spacing8),
            ],
            Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: widget.fontSize ?? 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: txtColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
