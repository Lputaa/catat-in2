import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/notifiers/dashboard_providers.dart';
import '../../data/repositories/recurring_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/neo_card.dart';
import 'add_recurring_screen.dart';

final recurringListProvider = FutureProvider<List<RecurringTransactionModel>>((ref) {
  return RecurringRepo().getAll();
});

final _categoryMapProvider = FutureProvider<Map<String, CategoryModel>>((ref) async {
  final cats = await CategoryRepo().getAll();
  return {for (final c in cats) c.id: c};
});

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  @override
  void initState() {
    super.initState();
    _processDue();
  }

  Future<void> _processDue() async {
    final manual = await RecurringRepo().processDueTransactions();
    if (manual.isNotEmpty && mounted) {
      for (final rt in manual) {
        _showDueDialog(rt);
      }
    }
  }

  void _showDueDialog(RecurringTransactionModel rt) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('TRANSAKSI JATUH TEMPO'),
        content: Text(
          '${rt.note ?? "Transaksi berulang"} sebesar ${formatter.format(rt.amount)} sudah jatuh tempo. Catat sekarang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('NANTI'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await RecurringRepo().recordAndAdvance(rt);
              HapticFeedback.mediumImpact();
              ref.invalidate(recurringListProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaksi dicatat')),
                );
              }
            },
            child: const Text('CATAT', style: TextStyle(color: NeoBrutalColors.success)),
          ),
        ],
      ),
    );
  }

  void _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddRecurringScreen()),
    );
    if (result == true) {
      ref.invalidate(recurringListProvider);
      ref.invalidate(_categoryMapProvider);
      ref.invalidate(upcomingRecurringProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(recurringListProvider);
    final catMap = ref.watch(_categoryMapProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Transaksi Berulang'),
      body: list.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyStateWithTemplates(onAdd: _openAdd);
          }

          final cats = catMap.valueOrNull ?? {};
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final rt = items[i];
              final cat = cats[rt.categoryId];
              final isDue = rt.nextDate.isBefore(DateTime.now()) && rt.active;
              final isIncome = rt.transactionType == 'income';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey(rt.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: NeoBrutalColors.danger,
                    child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                  ),
                  confirmDismiss: (_) async {
                    HapticFeedback.mediumImpact();
                    return true;
                  },
                  onDismissed: (_) async {
                    await RecurringRepo().delete(rt.id);
                    ref.invalidate(recurringListProvider);
                    ref.invalidate(upcomingRecurringProvider);
                    ref.invalidate(totalBalanceProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaksi berulang dihapus')),
                      );
                    }
                  },
                  child: GestureDetector(
                    onTap: () => _openEdit(context, ref, rt),
                    child: NeoCard(
                    color: isDue ? NeoBrutalColors.yellow.withValues(alpha: 0.3) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (isIncome ? NeoBrutalColors.success : NeoBrutalColors.danger).withValues(alpha: 0.15),
                            border: Border.all(
                              color: isIncome ? NeoBrutalColors.success : NeoBrutalColors.danger,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.repeat_rounded,
                            size: 20,
                            color: isIncome ? NeoBrutalColors.success : NeoBrutalColors.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rt.note ?? 'Transaksi Berulang',
                                style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (cat != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: cat.colorValue, width: 1.5),
                                      ),
                                      child: Text(
                                        cat.name.toUpperCase(),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                          color: cat.colorValue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    '${rt.frequencyLabel} • ${DateFormat('dd MMM').format(rt.nextDate)}',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w500),
                                  ),
                                ],
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
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isIncome ? NeoBrutalColors.success : NeoBrutalColors.danger,
                              ),
                            ),
                            if (!rt.active)
                              Text(
                                'NONAKTIF',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: NeoBrutalColors.muted,
                                ),
                              ),
                            if (isDue)
                              Text(
                                'JATUH TEMPO',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: NeoBrutalColors.orange,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NeoBrutalColors.yellow,
        onPressed: _openAdd,
        child: const Icon(Icons.add_rounded, color: NeoBrutalColors.ink),
      ),
    );
  }

  void _openEdit(BuildContext context, WidgetRef ref, RecurringTransactionModel rt) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddRecurringScreen(editTransaction: rt)),
    );
    if (result == true) {
      ref.invalidate(recurringListProvider);
      ref.invalidate(_categoryMapProvider);
    }
  }
}

// ── Empty State with Templates ──
class _EmptyStateWithTemplates extends StatelessWidget {
  const _EmptyStateWithTemplates({required this.onAdd});
  final VoidCallback onAdd;

  static const _templates = [
    _RecurringTemplate('Listrik', 'Tagihan', Icons.bolt_rounded, 200000, RecurrenceFrequency.monthly),
    _RecurringTemplate('Internet / WiFi', 'Tagihan', Icons.wifi_rounded, 300000, RecurrenceFrequency.monthly),
    _RecurringTemplate('Air / PDAM', 'Tagihan', Icons.water_drop_rounded, 100000, RecurrenceFrequency.monthly),
    _RecurringTemplate('Pulsa / Paket Data', 'Keseharian', Icons.phone_android_rounded, 100000, RecurrenceFrequency.monthly),
    _RecurringTemplate('Netflix', 'Hiburan', Icons.movie_rounded, 65000, RecurrenceFrequency.monthly),
    _RecurringTemplate('Spotify', 'Hiburan', Icons.music_note_rounded, 55000, RecurrenceFrequency.monthly),
    _RecurringTemplate('Gaji', 'Gaji', Icons.work_rounded, 5000000, RecurrenceFrequency.monthly),
  ];

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.repeat_rounded, size: 48, color: NeoBrutalColors.muted),
          const SizedBox(height: 12),
          Text(
            'BELUM ADA TRANSAKSI BERULANG',
            style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih template di bawah atau buat manual',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          ..._templates.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () async {
                final repo = RecurringRepo();
                await repo.insert(RecurringTransactionModel(
                  id: repo.newId(),
                  transactionType: t.category == 'Gaji' ? 'income' : 'expense',
                  amount: t.amount,
                  categoryId: _guessCategoryId(t.category),
                  accountId: 'acc_tunai',
                  note: t.name,
                  frequency: t.frequency,
                  startDate: DateTime.now(),
                  nextDate: DateTime.now(),
                  autoRecord: false,
                ));
                HapticFeedback.mediumImpact();
                // ignore: use_build_context_synchronously
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${t.name} ditambahkan')),
                  );
                }
              },
              child: NeoCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderOffset: const Offset(4, 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: NeoBrutalColors.orange.withValues(alpha: 0.15),
                        border: Border.all(color: NeoBrutalColors.orange, width: 2),
                      ),
                      child: Icon(t.icon, size: 18, color: NeoBrutalColors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700)),
                          Text('${t.category} • ${formatter.format(t.amount)}/bulan',
                            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const Icon(Icons.add_circle_outline_rounded, size: 22, color: NeoBrutalColors.orange),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onAdd,
            child: Text(
              'Atau buat transaksi berulang manual',
              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  static String _guessCategoryId(String category) {
    switch (category) {
      case 'Tagihan': return 'cat_tagihan';
      case 'Hiburan': return 'cat_hiburan';
      case 'Keseharian': return 'cat_makanan';
      case 'Gaji': return 'cat_gaji';
      default: return 'cat_lainnya_exp';
    }
  }
}

class _RecurringTemplate {
  final String name;
  final String category;
  final IconData icon;
  final double amount;
  final RecurrenceFrequency frequency;
  const _RecurringTemplate(this.name, this.category, this.icon, this.amount, this.frequency);
}
