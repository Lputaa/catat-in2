import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/constants/app_constants.dart';

/// Square icon button used in sheet headers (close / delete) with the
/// Neo-Brutal 3D press effect: a hard offset [BoxShadow] that collapses while
/// the button translates down-right on press.
///
/// The decoration keeps an opaque [fill] behind the icon so the shadow
/// composites correctly under Impeller — a transparent fill rasters the shadow
/// area as a dark block on the first frame until a repaint occurs.
class NeoHeaderButton extends StatefulWidget {
  const NeoHeaderButton({
    super.key,
    required this.icon,
    required this.borderColor,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final Color borderColor;

  /// Optional accent color for the border/icon (e.g. danger for delete).
  final Color? color;
  final VoidCallback onTap;

  @override
  State<NeoHeaderButton> createState() => _NeoHeaderButtonState();
}

class _NeoHeaderButtonState extends State<NeoHeaderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).brightness == Brightness.dark
        ? NeoBrutalColors.bgDark
        : NeoBrutalColors.bg;
    final edge = widget.color ?? widget.borderColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: edge, width: AppConstants.borderSecondary),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: edge,
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
        ),
        transform: _pressed
            ? (Matrix4.identity()..translateByDouble(2.0, 2.0, 0.0, 1.0))
            : Matrix4.identity(),
        child: Icon(widget.icon, size: 18, color: widget.color),
      ),
    );
  }
}
