import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/neo_brutal_colors.dart';
import 'neo_button.dart';

/// Consistent empty state widget with icon, title, subtitle, and optional CTA
class NeoEmptyState extends StatelessWidget {
  const NeoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.ctaColor = NeoBrutalColors.primary,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final Color ctaColor;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: NeoBrutalColors.muted),
            const SizedBox(height: 16),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: NeoBrutalColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 20),
              NeoButton(
                label: ctaLabel!,
                color: ctaColor,
                onTap: onCta,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
