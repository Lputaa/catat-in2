import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/constants/app_constants.dart';

/// Animated logo + double-stacked title
/// Style Guide §7.2
class CatatInAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CatatInAppBar({super.key, this.subtitle, this.actions});

  final String? subtitle;
  final List<Widget>? actions;

  @override
  State<CatatInAppBar> createState() => _CatatInAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

class _CatatInAppBarState extends State<CatatInAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: AppConstants.animLogo,
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing16,
          vertical: AppConstants.spacing8,
        ),
        child: Row(
          children: [
            // Back button (only shown on pushed routes)
            if (Navigator.of(context).canPop()) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? NeoBrutalColors.surfaceDark
                        : NeoBrutalColors.surface,
                    border: Border.all(
                      color: isDark
                          ? NeoBrutalColors.darkLine
                          : NeoBrutalColors.ink,
                      width: AppConstants.borderSecondary,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: isDark
                        ? NeoBrutalColors.inkDark
                        : NeoBrutalColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacing12),
            ],
            // Animated logo
            ScaleTransition(
              scale: _logoScale,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: NeoBrutalColors.primary,
                  border: Border.all(
                    color: isDark
                        ? NeoBrutalColors.darkLine
                        : NeoBrutalColors.ink,
                    width: AppConstants.borderSecondary,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'C',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            // Stacked title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Catat-In',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? NeoBrutalColors.inkDark
                        : NeoBrutalColors.ink,
                  ),
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isDark
                          ? NeoBrutalColors.inkDark.withValues(alpha: 0.6)
                          : NeoBrutalColors.ink.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            if (widget.actions != null) ...widget.actions!,
          ],
        ),
      ),
    );
  }
}
