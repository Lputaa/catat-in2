import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../data/models/account_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/notifiers/budget_list_notifier.dart';
import '../../data/notifiers/dashboard_providers.dart';
import '../../data/repositories/account_repo.dart';
import '../../data/repositories/budget_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../data/settings_service.dart';
import '../../shared/widgets/dot_pattern_background.dart';
import '../../shared/widgets/neo_button.dart';
import '../transactions/add_transaction_sheet.dart';

/// First-launch wizard — FUTURE-DEVELOPMENT.md §6
/// 4 halaman: Welcome → Catat transaksi → Atur budget → Sesuaikan wallet.
/// Flag `onboarding_completed` disimpan di Hive via SettingsService.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  static const _pageCount = 4;

  // Page 1 — first transaction
  bool _txAdded = false;

  // Page 2 — quick budget
  List<CategoryModel> _expenseCategories = [];
  CategoryModel? _budgetCategory;
  final _budgetController = TextEditingController();
  bool _budgetSaved = false;

  // Page 3 — wallet names
  List<AccountModel> _accounts = [];
  final Map<String, TextEditingController> _accountControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await CategoryRepo().getByType(CategoryType.expense);
    final accs = await AccountRepo().getAll();
    if (!mounted) return;
    setState(() {
      _expenseCategories = cats;
      _budgetCategory = cats.firstOrNull;
      _accounts = accs;
      for (final acc in accs) {
        _accountControllers[acc.id] = TextEditingController(text: acc.name);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _budgetController.dispose();
    for (final c in _accountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Navigation ──

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page < _pageCount - 1) {
      _goTo(_page + 1);
    } else {
      _finish();
    }
  }

  void _back() {
    HapticFeedback.selectionClick();
    if (_page > 0) _goTo(_page - 1);
  }

  Future<void> _skip() async {
    HapticFeedback.selectionClick();
    await _complete();
  }

  Future<void> _finish() async {
    // Persist renamed wallets (only changed, non-empty)
    for (final acc in _accounts) {
      final name = _accountControllers[acc.id]?.text.trim() ?? '';
      if (name.isNotEmpty && name != acc.name && name.length <= 30) {
        await AccountRepo().update(acc.copyWith(name: name));
      }
    }
    await _complete();
  }

  Future<void> _complete() async {
    await SettingsService.instance.setOnboardingCompleted(true);
    if (!mounted) return;
    // Refresh providers touched during onboarding (accounts, budgets)
    ref.invalidate(accountsProvider);
    ref.invalidate(budgetListProvider);
    ref.read(onboardingCompletedProvider.notifier).state = true;
  }

  // ── Page actions ──

  Future<void> _tryAddTransaction() async {
    final saved = await AddTransactionSheet.show(context);
    if (saved == true && mounted) {
      setState(() => _txAdded = true);
    }
  }

  Future<void> _saveBudget() async {
    final cat = _budgetCategory;
    if (cat == null) return;
    final raw = _budgetController.text.replaceAll('.', '');
    final amount = double.tryParse(raw) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi nominal budget dulu')));
      return;
    }

    final repo = BudgetRepo();
    final now = DateTime.now();
    final existing = await repo.getByCategoryAndMonth(
      cat.id,
      now.year,
      now.month,
    );
    if (existing != null) {
      await repo.update(existing.copyWith(limitAmount: amount));
    } else {
      await repo.insert(
        BudgetModel(
          id: repo.newId(),
          categoryId: cat.id,
          limitAmount: amount,
          year: now.year,
          month: now.month,
        ),
      );
    }

    HapticFeedback.mediumImpact();
    if (mounted) setState(() => _budgetSaved = true);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? NeoBrutalColors.bgDark : NeoBrutalColors.bg;
    final inkColor = isDark ? NeoBrutalColors.inkDark : NeoBrutalColors.ink;

    return Scaffold(
      backgroundColor: bgColor,
      body: DotPatternBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(inkColor),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _buildWelcomePage(inkColor),
                    _buildTransactionPage(inkColor),
                    _buildBudgetPage(inkColor, brightness),
                    _buildWalletPage(inkColor, brightness),
                  ],
                ),
              ),
              _buildBottomBar(brightness, inkColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Color inkColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: NeoBrutalColors.yellow,
            child: Text(
              'CATAT-IN',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: NeoBrutalColors.ink,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _skip,
            child: Text(
              'LEWATI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: inkColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 0: Welcome ──

  Widget _buildWelcomePage(Color inkColor) {
    return _PageScaffold(
      badge: '01',
      badgeColor: NeoBrutalColors.primary,
      title: 'SELAMAT DATANG!',
      description:
          'Catat-In bantu kamu catat pengeluaran, atur budget, dan pantau '
          'keuangan — semua tersimpan di HP kamu, tanpa akun.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _featureRow(
            Icons.receipt_long_rounded,
            NeoBrutalColors.primary,
            'Catat transaksi harian dalam hitungan detik',
            inkColor,
          ),
          const SizedBox(height: AppConstants.spacing12),
          _featureRow(
            Icons.pie_chart_rounded,
            NeoBrutalColors.secondary,
            'Budget bulanan per kategori dengan progress bar',
            inkColor,
          ),
          const SizedBox(height: AppConstants.spacing12),
          _featureRow(
            Icons.savings_rounded,
            NeoBrutalColors.success,
            'Target tabungan & laporan visual',
            inkColor,
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, Color color, String text, Color inkColor) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              color.withValues(alpha: 0.15),
              NeoBrutalColors.surface,
            ),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: inkColor,
            ),
          ),
        ),
      ],
    );
  }

  // ── Page 1: First transaction ──

  Widget _buildTransactionPage(Color inkColor) {
    return _PageScaffold(
      badge: '02',
      badgeColor: NeoBrutalColors.danger,
      title: 'CATAT PENGELUARAN PERTAMAMU',
      description:
          'Beli kopi tadi pagi? Ongkos ojek? Coba catat sekarang — '
          'pilih kategori, isi nominal, selesai.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_txAdded)
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  NeoBrutalColors.success.withValues(alpha: 0.15),
                  NeoBrutalColors.surface,
                ),
                border: Border.all(
                  color: NeoBrutalColors.success,
                  width: AppConstants.borderSecondary,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: NeoBrutalColors.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mantap! Transaksi pertamamu sudah tercatat.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NeoBrutalColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            NeoButton(
              label: 'Coba Catat Sekarang',
              icon: Icons.add_rounded,
              color: NeoBrutalColors.primary,
              onTap: _tryAddTransaction,
            ),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            _txAdded
                ? 'Kamu bisa lanjut ke langkah berikutnya.'
                : 'Bisa dilewati — tombol + di tengah bawah selalu siap kapan saja.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: inkColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Quick budget ──

  Widget _buildBudgetPage(Color inkColor, Brightness brightness) {
    return _PageScaffold(
      badge: '03',
      badgeColor: NeoBrutalColors.secondary,
      title: 'ATUR BUDGET BULANAN',
      description:
          'Tentukan batas pengeluaran untuk satu kategori dulu. '
          'Sisanya bisa diatur nanti di tab Laporan.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KATEGORI',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: inkColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppConstants.spacing8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _expenseCategories.map((cat) {
              final selected = _budgetCategory?.id == cat.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _budgetCategory = cat;
                    _budgetSaved = false;
                  });
                },
                child: AnimatedContainer(
                  duration: AppConstants.animSegmented,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? NeoBrutalColors.secondary
                        : NeoBrutalColors.surface,
                    border: Border.all(
                      color: NeoBrutalTheme.borderColor(brightness),
                      width: AppConstants.borderSecondary,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusChip,
                    ),
                  ),
                  child: Text(
                    cat.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : NeoBrutalColors.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            'NOMINAL PER BULAN',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: inkColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppConstants.spacing8),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ThousandsFormatter(),
            ],
            onChanged: (_) {
              if (_budgetSaved) setState(() => _budgetSaved = false);
            },
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              hintText: '500.000',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: AppConstants.spacing8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [300000, 500000, 1000000, 2000000].map((preset) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _budgetController.text = NumberFormat(
                    '#,###',
                    'id_ID',
                  ).format(preset);
                  setState(() => _budgetSaved = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: NeoBrutalColors.muted,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusChip,
                    ),
                  ),
                  child: Text(
                    NumberFormat.compactCurrency(
                      locale: 'id_ID',
                      symbol: '',
                      decimalDigits: 0,
                    ).format(preset).trim(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: NeoBrutalColors.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.spacing16),
          if (_budgetSaved)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: NeoBrutalColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Budget tersimpan!',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NeoBrutalColors.success,
                  ),
                ),
              ],
            )
          else
            NeoButton(
              label: 'Simpan Budget',
              icon: Icons.flag_rounded,
              color: NeoBrutalColors.secondary,
              onTap: _saveBudget,
            ),
        ],
      ),
    );
  }

  // ── Page 3: Wallet names ──

  Widget _buildWalletPage(Color inkColor, Brightness brightness) {
    return _PageScaffold(
      badge: '04',
      badgeColor: NeoBrutalColors.success,
      title: 'SESUAIKAN WALLET-MU',
      description:
          'Ganti nama wallet sesuai kebiasaanmu — misal "BCA", "GoPay", '
          'atau "Dompet Kos". Bisa ditambah lagi nanti di Settings.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _accounts.map((acc) {
          final icon = switch (acc.type) {
            AccountType.cash => Icons.payments_rounded,
            AccountType.bank => Icons.account_balance_rounded,
            AccountType.ewallet => Icons.wallet_rounded,
            AccountType.paylater => Icons.credit_card_rounded,
            AccountType.other => Icons.account_balance_wallet_rounded,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacing12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      NeoBrutalColors.success.withValues(alpha: 0.15),
                      NeoBrutalColors.surface,
                    ),
                    border: Border.all(
                      color: NeoBrutalColors.success,
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, size: 20, color: NeoBrutalColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _accountControllers[acc.id],
                    maxLength: 30,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      labelText: acc.typeLabel.toUpperCase(),
                      labelStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: inkColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Bottom bar ──

  Widget _buildBottomBar(Brightness brightness, Color inkColor) {
    final isLast = _page == _pageCount - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: NeoBrutalTheme.borderColor(brightness),
            width: AppConstants.borderPrimary,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button (hidden on first page)
          SizedBox(
            width: 44,
            child: _page > 0
                ? IconButton(
                    onPressed: _back,
                    icon: Icon(Icons.arrow_back_rounded, color: inkColor),
                  )
                : null,
          ),
          const Spacer(),
          // Page dots — Neo squares
          Row(
            children: List.generate(_pageCount, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: AppConstants.animSegmented,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 22 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: active ? NeoBrutalColors.primary : Colors.transparent,
                  border: Border.all(
                    color: NeoBrutalTheme.borderColor(brightness),
                    width: AppConstants.borderSecondary,
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          NeoButton(
            label: isLast ? 'Mulai!' : 'Lanjut',
            color: isLast ? NeoBrutalColors.success : NeoBrutalColors.yellow,
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            onTap: _next,
          ),
        ],
      ),
    );
  }
}

/// Shared page layout: numbered badge + title + description + content.
class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.description,
    required this.child,
  });

  final String badge;
  final Color badgeColor;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final inkColor = isDark ? NeoBrutalColors.inkDark : NeoBrutalColors.ink;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              border: Border.all(
                color: NeoBrutalTheme.borderColor(brightness),
                width: AppConstants.borderSecondary,
              ),
              boxShadow: NeoBrutalTheme.hardShadow(
                offset: AppConstants.shadowSmall,
                brightness: brightness,
              ),
            ),
            child: Text(
              badge,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color:
                    ThemeData.estimateBrightnessForColor(badgeColor) ==
                        Brightness.dark
                    ? Colors.white
                    : NeoBrutalColors.ink,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacing20),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.15,
              letterSpacing: -0.5,
              color: inkColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacing12),
          Text(
            description,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              height: 1.5,
              color: inkColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),
          child,
        ],
      ),
    );
  }
}

/// Thousands separator (id_ID style: 1.000.000) for budget input.
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final formatted = NumberFormat('#,###', 'id_ID').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
