import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';

/// Full-width button for dialogs, consistent styling
class NeoDialogButton extends StatefulWidget {
  const NeoDialogButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = NeoBrutalColors.primary,
    this.textColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color? textColor;

  @override
  State<NeoDialogButton> createState() => _NeoDialogButtonState();
}

class _NeoDialogButtonState extends State<NeoDialogButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);
    final txtColor = widget.textColor ?? Colors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: _pressed
              ? []
              : NeoBrutalTheme.hardShadow(
                  offset: const Offset(3, 3),
                  brightness: brightness,
                ),
        ),
        transform: _pressed
            ? (Matrix4.identity()..translateByDouble(1.5, 1.5, 0.0, 1.0))
            : Matrix4.identity(),
        child: Center(
          child: Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: txtColor,
            ),
          ),
        ),
      ),
    );
  }
}
