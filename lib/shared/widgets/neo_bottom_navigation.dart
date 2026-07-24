import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../features/transactions/add_transaction_sheet.dart';

/// 4-tab bottom nav + center-docked FAB
/// Style Guide §10.2
class NeoBottomNavigation extends ConsumerWidget {
  const NeoBottomNavigation({super.key});

  static const _tabs = [
    _NavItem(Icons.dashboard_rounded, 'Home', NeoBrutalColors.primary),
    _NavItem(Icons.receipt_long_rounded, 'Transaksi', NeoBrutalColors.cyan),
    _NavItem(Icons.bar_chart_rounded, 'Laporan', NeoBrutalColors.green),
    _NavItem(Icons.settings_rounded, 'Settings', NeoBrutalColors.purple),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);
    final bg = brightness == Brightness.light
        ? NeoBrutalColors.surface
        : NeoBrutalColors.surfaceDark;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: AppConstants.navBarHeight + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: AppConstants.borderPrimary,
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < 2; i++)
            _buildTab(context, ref, i, currentIndex, borderColor),
          // Center FAB (docked, 3D press)
          Expanded(
            child: Center(
              child: _NavCenterButton(
                borderColor: borderColor,
                brightness: brightness,
              ),
            ),
          ),
          for (int i = 2; i < 4; i++)
            _buildTab(context, ref, i, currentIndex, borderColor),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    WidgetRef ref,
    int index,
    int current,
    Color borderColor,
  ) {
    final tab = _tabs[index];
    final selected = index == current;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (selected) return;
          HapticFeedback.lightImpact();
          ref.read(navIndexProvider.notifier).state = index;
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator: solid Neo-Brutal block (opaque fill keeps the
            // hard shadow crisp under Impeller). Border width is kept for both
            // states so switching tabs never shifts the layout.
            AnimatedContainer(
              duration: AppConstants.animSegmented,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? tab.color : Colors.transparent,
                border: Border.all(
                  color: selected ? borderColor : Colors.transparent,
                  width: AppConstants.borderSecondary,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusChip),
                boxShadow: [
                  BoxShadow(
                    color: selected ? borderColor : Colors.transparent,
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                tab.icon,
                size: 22,
                color: selected ? Colors.white : NeoBrutalColors.muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tab.label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 0.8,
                color: selected ? tab.color : NeoBrutalColors.muted,
                fontFamily: 'Space Grotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Center-docked "add transaction" button with the shared Neo-Brutal 3D press
/// effect: the hard shadow collapses and the block translates into it on press.
class _NavCenterButton extends StatefulWidget {
  const _NavCenterButton({required this.borderColor, required this.brightness});

  final Color borderColor;
  final Brightness brightness;

  @override
  State<_NavCenterButton> createState() => _NavCenterButtonState();
}

class _NavCenterButtonState extends State<_NavCenterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Base docking offset lifts the button above the bar; the press nudges it
    // toward the shadow (down-right) while the shadow disappears.
    const dock = -12.0;
    final press = AppConstants.shadowSmall;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.mediumImpact();
        AddTransactionSheet.show(context);
      },
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        width: 56,
        height: 56,
        transform: _pressed
            ? (Matrix4.identity()
                ..translateByDouble(press.dx, dock + press.dy, 0.0, 1.0))
            : (Matrix4.identity()..translateByDouble(0.0, dock, 0.0, 1.0)),
        decoration: BoxDecoration(
          color: NeoBrutalColors.yellow,
          border: Border.all(
            color: widget.borderColor,
            width: AppConstants.borderPrimary,
          ),
          boxShadow: _pressed
              ? const []
              : NeoBrutalTheme.hardShadow(
                  offset: press,
                  brightness: widget.brightness,
                ),
        ),
        child: const Center(
          child: Icon(Icons.add_rounded, size: 28, color: NeoBrutalColors.ink),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;
  const _NavItem(this.icon, this.label, this.color);
}
