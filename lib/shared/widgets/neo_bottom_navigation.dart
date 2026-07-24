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
        border: Border(top: BorderSide(color: borderColor, width: AppConstants.borderPrimary)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < 2; i++) _buildTab(context, ref, i, currentIndex),
          // Center FAB
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  AddTransactionSheet.show(context);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  transform: Matrix4.identity()..translateByDouble(0.0, -12.0, 0.0, 1.0),
                  decoration: BoxDecoration(
                    color: NeoBrutalColors.yellow,
                    border: Border.all(color: borderColor, width: AppConstants.borderPrimary),
                    boxShadow: NeoBrutalTheme.hardShadow(
                      offset: AppConstants.shadowSmall,
                      brightness: brightness,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.add_rounded, size: 28, color: NeoBrutalColors.ink),
                  ),
                ),
              ),
            ),
          ),
          for (int i = 2; i < 4; i++) _buildTab(context, ref, i, currentIndex),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, WidgetRef ref, int index, int current) {
    final tab = _tabs[index];
    final selected = index == current;
    final brightness = Theme.of(context).brightness;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(navIndexProvider.notifier).state = index;
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppConstants.animSegmented,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? (brightness == Brightness.light
                        ? tab.color.withValues(alpha: 0.15)
                        : tab.color.withValues(alpha: 0.25))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radiusChip),
              ),
              child: Icon(
                tab.icon,
                size: 22,
                color: selected ? tab.color : NeoBrutalColors.muted,
              ),
            ),
            const SizedBox(height: 2),
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

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;
  const _NavItem(this.icon, this.label, this.color);
}
