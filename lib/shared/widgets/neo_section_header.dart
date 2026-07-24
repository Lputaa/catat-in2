import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/neo_brutal_colors.dart';

/// Consistent section header with color bar + optional icon
/// Style Guide compliant
class NeoSectionHeader extends StatelessWidget {
  const NeoSectionHeader({
    super.key,
    required this.title,
    this.color = NeoBrutalColors.primary,
    this.icon,
  });

  final String title;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 18, color: color),
        const SizedBox(width: 10),
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
        ],
        Text(
          title.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
