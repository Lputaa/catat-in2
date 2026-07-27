import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/notifiers/dashboard_providers.dart';
import '../templates/quick_templates_section.dart';
import '../../data/notifiers/budget_list_notifier.dart';
import '../../data/notifiers/recurring_list_notifier.dart';
import '../../data/notifiers/savings_list_notifier.dart';
import '../../data/notifiers/debt_list_notifier.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/savings_contribution_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/repositories/savings_goal_repo.dart';
import '../../data/repositories/recurring_repo.dart';
import '../../data/notifiers/transaction_list_notifier.dart';
import '../../main.dart' show startupRecurringProvider, StartupRecurringResult;
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_icon_container.dart';
import '../../shared/widgets/neo_progress_bar.dart';
import '../../shared/widgets/neo_dialog_button.dart';
import '../../shared/widgets/neo_button.dart';
import '../budget/add_budget_sheet.dart';
import '../recurring/add_recurring_sheet.dart';
import '../savings/add_savings_sheet.dart';
import '../debts/add_debt_sheet.dart';
import '../debts/debts_popup.dart';
import '../transactions/add_transaction_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringResult = ref.watch(startupRecurringProvider);

    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Startup recurring banner
            if (recurringResult.hasResult) ...[
              _RecurringStartupBanner(result: recurringResult),
              const SizedBox(height: 12),
            ],
            _WalletCarousel(),
            const SizedBox(height: 20),
            // Finance sections - vertical scrollable
            _FinanceSectionsScrollable(),
            const SizedBox(height: 20),
            // Quick-entry templates (2-tap recording)
            const QuickTemplatesSection(),
            const SizedBox(height: 20),
            _RecentTransactionsSection(),
          ],
        ),
      ),
    );
  }
}

/// Banner shown on dashboard when app starts with due recurring transactions.
class _RecurringStartupBanner extends ConsumerStatefulWidget {
  const _RecurringStartupBanner({required this.result});
  final StartupRecurringResult result;

  @override
  ConsumerState<_RecurringStartupBanner> createState() =>
      _RecurringStartupBannerState();
}

class _RecurringStartupBannerState
    extends ConsumerState<_RecurringStartupBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final result = widget.result;
    final hasAuto = result.autoRecorded > 0;
    final hasManual = result.needsConfirm.isNotEmpty;

    return NeoCard(
      color: hasManual
          ? NeoBrutalColors.orange.withValues(alpha: 0.15)
          : NeoBrutalColors.success.withValues(alpha: 0.15),
      borderOffset: const Offset(3, 3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasManual
                    ? Icons.notification_important_rounded
                    : Icons.check_circle_outline_rounded,
                size: 20,
                color: hasManual
                    ? NeoBrutalColors.orange
                    : NeoBrutalColors.success,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasManual
                      ? 'TAGIHAN JATUH TEMPO'
                      : 'TRANSAKSI BERULANG DICATAT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: hasManual
                        ? NeoBrutalColors.orange
                        : NeoBrutalColors.success,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                child: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasAuto)
            Text(
              '${result.autoRecorded} transaksi berulang telah dicatat otomatis.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (hasManual) ...[
            if (hasAuto) const SizedBox(height: 4),
            Text(
              '${result.needsConfirm.length} tagihan menunggu konfirmasi.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            // List each manual item with confirm button
            ...result.needsConfirm.map(
              (rt) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${rt.note ?? "Transaksi"} — ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(rt.amount)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await RecurringRepo().recordAndAdvance(rt);
                        if (!context.mounted) return;
                        HapticFeedback.mediumImpact();
                        setState(() {
                          result.needsConfirm.remove(rt);
                        });
                        ref.read(transactionListProvider.notifier).refresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Dicatat: ${rt.note ?? "Transaksi"}'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        color: NeoBrutalColors.success,
                        child: Text(
                          'CATAT',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Confirm all button
            if (result.needsConfirm.length > 1)
              GestureDetector(
                onTap: () async {
                  final count = result.needsConfirm.length;
                  for (final rt in List.of(result.needsConfirm)) {
                    await RecurringRepo().recordAndAdvance(rt);
                  }
                  if (!context.mounted) return;
                  HapticFeedback.mediumImpact();
                  setState(() => _dismissed = true);
                  ref.read(transactionListProvider.notifier).refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count transaksi dicatat')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: NeoBrutalColors.orange,
                  child: Center(
                    child: Text(
                      'CATAT SEMUA',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── 3D Vertical Wallet Carousel ──
class _WalletCarousel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WalletCarousel> createState() => _WalletCarouselState();
}

class _WalletCarouselState extends ConsumerState<_WalletCarousel> {
  late PageController _pageController;
  double _currentPage = 10000;
  Timer? _autoScrollTimer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: 10000,
    );
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_userInteracting && _pageController.hasClients) {
        final nextPage = _currentPage.round() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onUserInteraction() {
    setState(() => _userInteracting = true);
    _autoScrollTimer?.cancel();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _userInteracting = false);
        _startAutoScroll();
      }
    });
  }

  // Jump to the nearest page that shows item [target] (0-based) within the
  // infinite carousel, keeping the current scroll direction natural.
  void _jumpToIndex(int target, int len) {
    if (!_pageController.hasClients) return;
    final base = _currentPage.round();
    final currentMod = ((base % len) + len) % len;
    if (target == currentMod) return;
    _onUserInteraction();
    _pageController.animateToPage(
      base + (target - currentMod),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final balances = ref.watch(accountBalancesProvider); // Now sync Provider
    final totalBalance = ref.watch(totalBalanceProvider); // Now sync Provider
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return accounts.when(
      data: (accs) {
        if (accs.isEmpty) {
          return NeoCard(
            color: NeoBrutalColors.primary,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'BELUM ADA DOMPET',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          );
        }

        // balances is now Map<String, double> directly (not AsyncValue)
        final balMap = balances;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total balance — solid hero banner (danger red when net negative)
            Builder(
              builder: (context) {
                final isNegative = totalBalance < 0;
                final bg = isNegative
                    ? NeoBrutalColors.danger
                    : NeoBrutalColors.primary;
                final fg = isNegative ? Colors.white : NeoBrutalColors.ink;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: NeoBrutalColors.ink, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoBrutalColors.ink,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        right: -14,
                        top: -10,
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 84,
                          color: fg.withValues(alpha: 0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: NeoBrutalColors.ink,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: NeoBrutalColors.ink,
                                    offset: Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isNegative
                                    ? Icons.trending_down_rounded
                                    : Icons.account_balance_wallet_rounded,
                                size: 19,
                                color: isNegative
                                    ? NeoBrutalColors.danger
                                    : NeoBrutalColors.ink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'TOTAL SALDO',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      color: fg.withValues(alpha: 0.75),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      formatter.format(totalBalance),
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                        color: fg,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: NeoBrutalColors.ink,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                isNegative
                                    ? '⚠ MINUS'
                                    : '${accs.length} WALLET',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: isNegative
                                      ? NeoBrutalColors.danger
                                      : NeoBrutalColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // 3D Vertical carousel
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Only real user drags pause the auto-scroll; programmatic
                // page animations have a null dragDetails.
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _onUserInteraction();
                }
                return false;
              },
              child: SizedBox(
                height: 170,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: null,
                  itemBuilder: (context, i) {
                    final acc = accs[i % accs.length];
                    final balance = balMap[acc.id] ?? 0;
                    final icon = _iconForType(acc.type);
                    final color = _colorForType(acc.type);

                    // 3D perspective calculation
                    final diff = (i - _currentPage).abs();
                    final scale = (1 - (diff * 0.15)).clamp(0.75, 1.0);
                    final translateY = diff * 20;
                    final opacity = (1 - (diff * 0.3)).clamp(0.4, 1.0);

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002) // perspective
                        ..translateByDouble(
                          0.0,
                          translateY * (i > _currentPage ? 1 : -1),
                          0.0,
                          1.0,
                        )
                        ..scaleByDouble(scale, scale, scale, 1.0),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: NeoCard(
                            color: color,
                            padding: EdgeInsets.zero,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                // Oversized watermark icon (depth accent)
                                Positioned(
                                  right: -12,
                                  bottom: -20,
                                  child: Icon(
                                    icon,
                                    size: 100,
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top: icon box + type chip
                                      Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: NeoBrutalColors.ink,
                                                width: 2,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: NeoBrutalColors.ink,
                                                  offset: Offset(2, 2),
                                                  blurRadius: 0,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              icon,
                                              size: 16,
                                              color: color,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: NeoBrutalColors.ink,
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              acc.isCredit
                                                  ? 'KREDIT'
                                                  : acc.typeLabel.toUpperCase(),
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.8,
                                                color: acc.isCredit
                                                    ? NeoBrutalColors.danger
                                                    : NeoBrutalColors.ink,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      // Bottom: name + balance
                                      Text(
                                        acc.name.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                formatter.format(balance),
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (acc.isCredit && balance < 0)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              child: Text(
                                                'HUTANG',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.0,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ), // Close NotificationListener
            // Page dots
            if (accs.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(accs.length, (j) {
                    final isActive = j == _currentPage.round() % accs.length;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _jumpToIndex(j, accs.length),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive
                                ? NeoBrutalColors.primary
                                : NeoBrutalColors.muted,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(height: 170),
      error: (_, _) => const SizedBox(height: 170),
    );
  }

  static IconData _iconForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.ewallet:
        return Icons.account_balance_wallet_rounded;
      case AccountType.paylater:
        return Icons.credit_card_rounded;
      case AccountType.other:
        return Icons.wallet_rounded;
    }
  }

  static Color _colorForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return NeoBrutalColors.primary;
      case AccountType.bank:
        return NeoBrutalColors.secondary;
      case AccountType.ewallet:
        return NeoBrutalColors.purple;
      case AccountType.paylater:
        return NeoBrutalColors.danger;
      case AccountType.other:
        return NeoBrutalColors.ink;
    }
  }
}

// ── Budget Overview Widget ──

// ── Budget Overview Widget ──
// ── Shared Dashboard Section Widget ──
class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.color,
    required this.icon,
    required this.title,
    required this.child,
    this.onTap,
    this.trailing,
  });

  final Color color;
  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Subtle opaque tint of the section color (Impeller-safe, no alpha fill).
    final tintedBg = Color.alphaBlend(
      color.withValues(alpha: 0.06),
      NeoBrutalColors.surface,
    );

    return GestureDetector(
      onTap: onTap,
      child: NeoCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Solid color header band
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
              decoration: BoxDecoration(
                color: color,
                border: const Border(
                  bottom: BorderSide(color: NeoBrutalColors.ink, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: NeoBrutalColors.surface,
                      border: Border.all(color: NeoBrutalColors.ink, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoBrutalColors.ink,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 15, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: trailing != null
                        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                        : const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: NeoBrutalColors.surface,
                      border: Border.all(color: NeoBrutalColors.ink, width: 2),
                    ),
                    child:
                        trailing ??
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: NeoBrutalColors.ink,
                        ),
                  ),
                ],
              ),
            ),
            // Body: tinted surface + oversized watermark icon
            Expanded(
              child: Container(
                color: tintedBg,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      right: -8,
                      bottom: -14,
                      child: Icon(
                        icon,
                        size: 76,
                        color: color.withValues(alpha: 0.10),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Chunky bottom accent strip
            Container(height: 5, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Empty Section Placeholder ──
class _EmptySectionPlaceholder extends StatelessWidget {
  const _EmptySectionPlaceholder({
    required this.message,
    required this.ctaLabel,
    required this.color,
  });
  final String message;
  final String ctaLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: NeoBrutalColors.ink, width: 2),
            boxShadow: const [
              BoxShadow(
                color: NeoBrutalColors.ink,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            ctaLabel.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Finance Sections - Vertical Scrollable with Auto Scroll ──
class _FinanceSectionsScrollable extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FinanceSectionsScrollable> createState() =>
      _FinanceSectionsScrollableState();
}

class _FinanceSectionsScrollableState
    extends ConsumerState<_FinanceSectionsScrollable> {
  late PageController _pageController;
  double _currentPage = 10000;
  Timer? _autoScrollTimer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 10000,
    );
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_userInteracting && _pageController.hasClients) {
        final nextPage = _currentPage.round() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onUserInteraction() {
    setState(() => _userInteracting = true);
    _autoScrollTimer?.cancel();
    // Resume auto scroll after 5 seconds of no interaction
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _userInteracting = false);
        _startAutoScroll();
      }
    });
  }

  // Jump to the nearest page that shows item [target] (0-based) within the
  // infinite carousel, keeping the current scroll direction natural.
  void _jumpToIndex(int target, int len) {
    if (!_pageController.hasClients) return;
    final base = _currentPage.round();
    final currentMod = ((base % len) + len) % len;
    if (target == currentMod) return;
    _onUserInteraction();
    _pageController.animateToPage(
      base + (target - currentMod),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widgets = [
      _BudgetOverviewWidget(),
      _UpcomingRecurringWidget(),
      _SavingsProgressWidget(),
      _DebtsOverviewWidget(),
    ];

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Only real user drags pause the auto-scroll; programmatic page
        // animations have a null dragDetails.
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _onUserInteraction();
        }
        return false;
      },
      child: Column(
        children: [
          SizedBox(
            height: 196,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: null,
              itemBuilder: (context, i) {
                final index = i % widgets.length;
                final diff = (i - _currentPage).abs();
                final scale = (1 - (diff * 0.08)).clamp(0.9, 1.0);
                final opacity = (1 - (diff * 0.3)).clamp(0.5, 1.0);

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..scaleByDouble(scale, scale, scale, 1.0),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: opacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      child: widgets[index],
                    ),
                  ),
                );
              },
            ),
          ),
          // Page dots
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widgets.length, (j) {
                final isActive = j == _currentPage.round() % widgets.length;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _jumpToIndex(j, widgets.length),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 8,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? NeoBrutalColors.secondary
                            : NeoBrutalColors.muted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Budget Overview Widget (Summary Only) ──
class _BudgetOverviewWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(budgetOverviewProvider);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    if (list.isEmpty) {
      return _DashboardSection(
        color: NeoBrutalColors.green,
        icon: Icons.account_balance_wallet_rounded,
        title: 'BUDGET BULAN INI',
        onTap: () => AddBudgetSheet.show(
          context,
          year: DateTime.now().year,
          month: DateTime.now().month,
        ),
        child: const _EmptySectionPlaceholder(
          message: 'Atur budget untuk kontrol pengeluaran',
          ctaLabel: 'Atur →',
          color: NeoBrutalColors.green,
        ),
      );
    }

    double totalLimit = 0;
    double totalSpent = 0;
    for (final b in list) {
      totalLimit += b.effectiveLimit;
      totalSpent += b.spent;
    }
    final totalPercent = totalLimit > 0 ? totalSpent / totalLimit : 0.0;
    final totalColor = totalPercent > 1.0
        ? NeoBrutalColors.danger
        : totalPercent >= 0.8
        ? NeoBrutalColors.orange
        : NeoBrutalColors.success;
    final warnings = list.where((b) => b.percent >= 0.8).length;

    return _DashboardSection(
      color: totalColor,
      icon: Icons.account_balance_wallet_rounded,
      title: 'BUDGET BULAN INI',
      onTap: () => _showBudgetDetail(context, ref, list),
      trailing: Text(
        '${(totalPercent * 100).toStringAsFixed(0)}%',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: totalColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: NeoBrutalColors.muted,
                    border: Border.all(color: NeoBrutalColors.ink, width: 1),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: totalPercent.clamp(0, 1),
                  child: Container(color: totalColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatter.format(totalSpent)} / ${formatter.format(totalLimit)}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          // Summary text
          Text(
            'Anda memiliki ${list.length} budget bulan ini'
            '${warnings > 0 ? ', $warnings di antaranya mendekati/melebihi batas' : ''}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: NeoBrutalColors.ink.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDetail(
    BuildContext context,
    WidgetRef ref,
    List<BudgetWithDetails> list,
  ) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'SEMUA BUDGET',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final w = list[i];
                    final itemColor = w.isOver
                        ? NeoBrutalColors.danger
                        : w.isWarning
                        ? NeoBrutalColors.orange
                        : NeoBrutalColors.success;
                    return Dismissible(
                      key: ValueKey(w.budget.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        color: NeoBrutalColors.secondary,
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: NeoBrutalColors.danger,
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        HapticFeedback.mediumImpact();
                        if (direction == DismissDirection.startToEnd) {
                          _showEditBudgetDialog(context, ref, w);
                          return false;
                        }
                        return await _confirmDelete(
                          context,
                          'Budget ${w.category.name}',
                        );
                      },
                      onDismissed: (_) {
                        ref
                            .read(budgetListProvider.notifier)
                            .deleteBudget(w.budget.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  color: itemColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    w.category.name,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(w.percent * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w900,
                                    color: itemColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            NeoProgressBar(
                              progress: w.percent,
                              color: itemColor,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${formatter.format(w.spent)} / ${formatter.format(w.effectiveLimit)}',
                              style: GoogleFonts.spaceGrotesk(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              NeoDialogButton(
                label: '+ Tambah Budget',
                color: NeoBrutalColors.green,
                onTap: () {
                  Navigator.pop(ctx);
                  AddBudgetSheet.show(
                    context,
                    year: DateTime.now().year,
                    month: DateTime.now().month,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    BudgetWithDetails item,
  ) {
    final controller = TextEditingController(
      text: item.budget.limitAmount.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('EDIT BUDGET ${item.category.name.toUpperCase()}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Limit Baru (Rp)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(
                controller.text.replaceAll('.', ''),
              );
              if (amount != null && amount > 0) {
                ref
                    .read(budgetListProvider.notifier)
                    .updateBudget(item.budget.copyWith(limitAmount: amount));
                Navigator.pop(ctx);
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('HAPUS $name?'),
            content: const Text('Item ini akan dihapus permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('BATAL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'HAPUS',
                  style: TextStyle(color: NeoBrutalColors.danger),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Upcoming Recurring Widget (Summary Only) ──
class _UpcomingRecurringWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(upcomingRecurringProvider);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    if (list.isEmpty) {
      return _DashboardSection(
        color: NeoBrutalColors.orange,
        icon: Icons.repeat_rounded,
        title: 'TAGIHAN BERULANG',
        onTap: () => AddRecurringSheet.show(context),
        child: const _EmptySectionPlaceholder(
          message: 'Atur tagihan & pemasukan rutin',
          ctaLabel: 'Atur →',
          color: NeoBrutalColors.orange,
        ),
      );
    }

    final dueCount = list
        .where((rt) => rt.nextDate.isBefore(DateTime.now()))
        .length;
    final totalAmount = list.fold<double>(0, (sum, rt) => sum + rt.amount);

    return _DashboardSection(
      color: dueCount > 0 ? NeoBrutalColors.danger : NeoBrutalColors.orange,
      icon: Icons.repeat_rounded,
      title: 'TAGIHAN BERULANG',
      onTap: () => _showRecurringDetail(context, ref, list),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anda memiliki ${list.length} tagihan berulang',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${formatter.format(totalAmount)}/bulan'
            '${dueCount > 0 ? '\n$dueCount tagihan sudah jatuh tempo!' : ''}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: dueCount > 0
                  ? NeoBrutalColors.danger
                  : NeoBrutalColors.ink.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecurringDetail(
    BuildContext context,
    WidgetRef ref,
    List<RecurringTransactionModel> list,
  ) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'SEMUA TAGIHAN',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final rt = list[i];
                    final isDue = rt.nextDate.isBefore(DateTime.now());
                    final isIncome = rt.transactionType == 'income';
                    final daysUntil = rt.nextDate
                        .difference(DateTime.now())
                        .inDays;
                    String dueText = isDue
                        ? 'JATUH TEMPO'
                        : daysUntil == 0
                        ? 'Hari ini'
                        : daysUntil == 1
                        ? 'Besok'
                        : '$daysUntil hari lagi';

                    return Dismissible(
                      key: ValueKey(rt.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        color: NeoBrutalColors.secondary,
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: NeoBrutalColors.danger,
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        HapticFeedback.mediumImpact();
                        if (direction == DismissDirection.startToEnd) {
                          Navigator.pop(ctx);
                          await AddRecurringSheet.show(context, editItem: rt);
                          return false;
                        }
                        return await _confirmDelete(
                          context,
                          rt.note ?? 'Transaksi Berulang',
                        );
                      },
                      onDismissed: (_) {
                        ref
                            .read(recurringListProvider.notifier)
                            .deleteRecurring(rt.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            NeoIconContainer(
                              icon: isDue
                                  ? Icons.warning_amber_rounded
                                  : Icons.repeat_rounded,
                              color: isDue
                                  ? NeoBrutalColors.danger
                                  : NeoBrutalColors.orange,
                              size: NeoIconSize.small,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rt.note ?? 'Transaksi Berulang',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${rt.frequencyLabel} • ${DateFormat('dd MMM').format(rt.nextDate)}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'}${formatter.format(rt.amount)}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isIncome
                                        ? NeoBrutalColors.success
                                        : NeoBrutalColors.danger,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDue
                                                ? NeoBrutalColors.danger
                                                : NeoBrutalColors.orange)
                                            .withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: isDue
                                          ? NeoBrutalColors.danger
                                          : NeoBrutalColors.orange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    dueText,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isDue
                                          ? NeoBrutalColors.danger
                                          : NeoBrutalColors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              NeoDialogButton(
                label: '+ Tambah Tagihan',
                color: NeoBrutalColors.orange,
                onTap: () {
                  Navigator.pop(ctx);
                  AddRecurringSheet.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('HAPUS $name?'),
            content: const Text('Item ini akan dihapus permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('BATAL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'HAPUS',
                  style: TextStyle(color: NeoBrutalColors.danger),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Savings Progress Widget (Summary Only) ──
class _SavingsProgressWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(savingsGoalsDashboardProvider);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    if (list.isEmpty) {
      return _DashboardSection(
        color: NeoBrutalColors.secondary,
        icon: Icons.savings_rounded,
        title: 'TARGET MENABUNG',
        onTap: () => AddSavingsSheet.show(context),
        child: const _EmptySectionPlaceholder(
          message: 'Buat target untuk capai tujuanmu',
          ctaLabel: 'Buat →',
          color: NeoBrutalColors.secondary,
        ),
      );
    }

    final completedCount = list.where((g) => g.isComplete).length;
    final totalSaved = list.fold<double>(0, (sum, g) => sum + g.savedAmount);
    final totalTarget = list.fold<double>(0, (sum, g) => sum + g.targetAmount);

    return _DashboardSection(
      color: NeoBrutalColors.secondary,
      icon: Icons.savings_rounded,
      title: 'TARGET MENABUNG',
      onTap: () => _showSavingsDetail(context, ref, list),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anda memiliki ${list.length} target menabung',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Terkumpul: ${formatter.format(totalSaved)} / ${formatter.format(totalTarget)}'
            '${completedCount > 0 ? '\n$completedCount target sudah tercapai!' : ''}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: completedCount > 0
                  ? NeoBrutalColors.success
                  : NeoBrutalColors.ink.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showSavingsDetail(
    BuildContext context,
    WidgetRef ref,
    List<SavingsGoalModel> list,
  ) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'SEMUA TARGET',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final goal = list[i];
                    final statusColor = goal.isComplete
                        ? NeoBrutalColors.success
                        : goal.percent >= 0.8
                        ? NeoBrutalColors.orange
                        : NeoBrutalColors.secondary;

                    return Dismissible(
                      key: ValueKey(goal.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        color: NeoBrutalColors.success,
                        child: const Icon(
                          Icons.savings_rounded,
                          color: Colors.white,
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: NeoBrutalColors.danger,
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        HapticFeedback.mediumImpact();
                        if (direction == DismissDirection.startToEnd) {
                          Navigator.pop(ctx);
                          _showContributionDialog(context, ref, goal);
                          return false;
                        }
                        return await _confirmDelete(context, goal.name);
                      },
                      onDismissed: (_) {
                        ref
                            .read(savingsListProvider.notifier)
                            .deleteGoal(goal.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                NeoIconContainer(
                                  icon: goal.isComplete
                                      ? Icons.check_circle_rounded
                                      : Icons.savings_rounded,
                                  color: statusColor,
                                  size: NeoIconSize.small,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal.name,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${formatter.format(goal.savedAmount)} / ${formatter.format(goal.targetAmount)}',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${(goal.percent * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            NeoProgressBar(
                              progress: goal.percent,
                              color: statusColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              NeoDialogButton(
                label: '+ Buat Target',
                color: NeoBrutalColors.secondary,
                onTap: () {
                  Navigator.pop(ctx);
                  AddSavingsSheet.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('HAPUS TARGET "$name"?'),
            content: const Text(
              'Target dan semua kontribusi akan dihapus permanen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('BATAL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'HAPUS',
                  style: TextStyle(color: NeoBrutalColors.danger),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showContributionDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoalModel goal,
  ) {
    final controller = TextEditingController();
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final remaining = goal.targetAmount - goal.savedAmount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('TAMBAH TABUNGAN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.name,
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Sisa: ${formatter.format(remaining)}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: NeoBrutalColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(
                controller.text.replaceAll('.', ''),
              );
              if (amount != null && amount > 0) {
                final repo = SavingsGoalRepo();
                ref
                    .read(savingsListProvider.notifier)
                    .addContribution(
                      SavingsContributionModel(
                        id: repo.newContribId(),
                        goalId: goal.id,
                        amount: amount,
                        date: DateTime.now(),
                      ),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Berhasil menambah ${formatter.format(amount)}',
                    ),
                  ),
                );
              }
            },
            child: const Text('TAMBAH'),
          ),
        ],
      ),
    );
  }
}

// ── Debts Overview Widget (Hutang & Piutang) ──
class _DebtsOverviewWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debtListProvider);
    final active = state.debts.where((d) => !d.isSettled).toList();
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    if (active.isEmpty) {
      return _DashboardSection(
        color: NeoBrutalColors.purple,
        icon: Icons.handshake_rounded,
        title: 'HUTANG & PIUTANG',
        onTap: () => AddDebtSheet.show(context),
        child: const _EmptySectionPlaceholder(
          message: 'Catat pinjaman atau piutang antar orang',
          ctaLabel: 'Catat →',
          color: NeoBrutalColors.purple,
        ),
      );
    }

    final hutangCount = active.where((d) => d.type == DebtType.hutang).length;
    final piutangCount = active.length - hutangCount;
    final overdueCount = active.where((d) => d.isOverdue).length;

    final parts = <String>[
      if (hutangCount > 0)
        '$hutangCount hutang (${formatter.format(state.totalHutang)})',
      if (piutangCount > 0)
        '$piutangCount piutang (${formatter.format(state.totalPiutang)})',
    ];

    return _DashboardSection(
      color: NeoBrutalColors.purple,
      icon: Icons.handshake_rounded,
      title: 'HUTANG & PIUTANG',
      onTap: () => DebtsListPopup.show(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anda memiliki ${active.length} catatan aktif',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${parts.join(' • ')}'
            '${overdueCount > 0 ? '\n$overdueCount sudah jatuh tempo!' : ''}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: overdueCount > 0
                  ? NeoBrutalColors.danger
                  : NeoBrutalColors.ink.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Transactions ──
class _RecentTransactionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(recentTransactionsProvider); // Now sync Provider
    final txState = ref.watch(transactionListProvider);
    final hasAnyTransaction =
        txState.isLoading || txState.transactions.isNotEmpty;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRANSAKSI TERBARU',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (txs.isEmpty && !hasAnyTransaction)
          // First-time empty state — guide user to their first record
          NeoCard(
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 48,
                  color: NeoBrutalColors.muted,
                ),
                const SizedBox(height: 12),
                Text(
                  'MULAI CATAT PENGELUARAN PERTAMAMU',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Kopi tadi pagi? Ongkos? Catat biar nggak lupa.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                NeoButton(
                  label: 'Catat Sekarang',
                  icon: Icons.add_rounded,
                  color: NeoBrutalColors.primary,
                  onTap: () => AddTransactionSheet.show(context),
                ),
              ],
            ),
          )
        else if (txs.isEmpty)
          NeoCard(
            child: Center(
              child: Text(
                'Belum ada transaksi hari ini',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          Column(
            children: txs
                .map(
                  (tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NeoCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tx.type == TransactionType.transfer
                                ? Icons.swap_horiz_rounded
                                : tx.type == TransactionType.income
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: tx.type == TransactionType.transfer
                                ? NeoBrutalColors.secondary
                                : tx.type == TransactionType.income
                                ? NeoBrutalColors.success
                                : NeoBrutalColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.note ??
                                      (tx.type == TransactionType.transfer
                                          ? 'Transfer'
                                          : 'Transaksi'),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy').format(tx.date),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            tx.type == TransactionType.transfer
                                ? formatter.format(tx.amount)
                                : '${tx.type == TransactionType.income ? '+' : '-'}${formatter.format(tx.amount)}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: tx.type == TransactionType.transfer
                                  ? NeoBrutalColors.secondary
                                  : tx.type == TransactionType.income
                                  ? NeoBrutalColors.success
                                  : NeoBrutalColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
