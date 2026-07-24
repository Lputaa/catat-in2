import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/notifiers/dashboard_providers.dart';
import '../../data/repositories/savings_goal_repo.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/neo_card.dart';
import 'add_savings_screen.dart';
import 'savings_detail_screen.dart';

final savingsListProvider = FutureProvider<List<SavingsGoalModel>>((ref) {
  return SavingsGoalRepo().getAll();
});

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsListProvider);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Target Menabung'),
      body: goals.when(
        data: (list) {
          if (list.isEmpty) {
            return _SavingsEmptyWithTemplates(onAdd: () => _openAdd(context, ref));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final goal = list[i];
              final statusColor = goal.isComplete
                  ? NeoBrutalColors.success
                  : goal.percent >= 0.8
                      ? NeoBrutalColors.orange
                      : NeoBrutalColors.secondary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _openDetail(context, ref, goal),
                  child: NeoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                border: Border.all(color: statusColor, width: 2),
                              ),
                              child: Icon(
                                goal.isComplete ? Icons.check_circle_rounded : Icons.savings_rounded,
                                size: 22,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name.toUpperCase(),
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (goal.deadline != null)
                                    Text(
                                      'Tenggat: ${DateFormat('dd MMM yyyy').format(goal.deadline!)}',
                                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${(goal.percent * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        SizedBox(
                          height: 12,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: NeoBrutalColors.muted,
                                  border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: goal.percent.clamp(0, 1),
                                child: Container(color: statusColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${formatter.format(goal.savedAmount)} / ${formatter.format(goal.targetAmount)}',
                              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'SISA ${formatter.format(goal.remaining > 0 ? goal.remaining : 0)}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
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
        onPressed: () => _openAdd(context, ref),
        child: const Icon(Icons.add_rounded, color: NeoBrutalColors.ink),
      ),
    );
  }

  void _openAdd(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddSavingsScreen()),
    );
    if (result == true) {
      ref.invalidate(savingsListProvider);
      ref.invalidate(savingsGoalsDashboardProvider);
    }
  }

  void _openDetail(BuildContext context, WidgetRef ref, SavingsGoalModel goal) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SavingsDetailScreen(goal: goal)),
    );
    if (changed == true) {
      ref.invalidate(savingsListProvider);
      ref.invalidate(savingsGoalsDashboardProvider);
      ref.invalidate(totalBalanceProvider);
    }
  }
}

// ── Savings Empty State with Templates ──
class _SavingsEmptyWithTemplates extends StatelessWidget {
  const _SavingsEmptyWithTemplates({required this.onAdd});
  final VoidCallback onAdd;

  static const _templates = [
    _SavingsTemplate('Liburan', Icons.flight_rounded, 5000000, 'Saatnya recharge!'),
    _SavingsTemplate('Gadget Baru', Icons.phone_iphone_rounded, 3000000, 'Upgrade device'),
    _SavingsTemplate('Dana Darurat', Icons.shield_rounded, 10000000, '3-6x pengeluaran bulanan'),
    _SavingsTemplate('DP Rumah', Icons.home_rounded, 50000000, 'Investasi jangka panjang'),
  ];

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.savings_rounded, size: 48, color: NeoBrutalColors.muted),
          const SizedBox(height: 12),
          Text(
            'BELUM ADA TARGET',
            style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih target populer atau buat sendiri',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _templates.map((t) {
              return GestureDetector(
                onTap: () async {
                  final repo = SavingsGoalRepo();
                  await repo.insert(SavingsGoalModel(
                    id: repo.newGoalId(),
                    name: t.name,
                    targetAmount: t.amount,
                    savedAmount: 0,
                  ));
                  HapticFeedback.mediumImpact();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Target "${t.name}" dibuat')),
                    );
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width / 2 - 22,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: NeoBrutalColors.surface,
                    border: Border.all(color: NeoBrutalColors.ink, width: 2),
                    boxShadow: const [BoxShadow(color: NeoBrutalColors.ink, offset: Offset(3, 3), blurRadius: 0)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(t.icon, size: 28, color: NeoBrutalColors.secondary),
                      const SizedBox(height: 8),
                      Text(t.name.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(formatter.format(t.amount),
                        style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w800, color: NeoBrutalColors.secondary),
                      ),
                      Text(t.hint, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onAdd,
            child: Text(
              'Atau buat target sendiri',
              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingsTemplate {
  final String name;
  final IconData icon;
  final double amount;
  final String hint;
  const _SavingsTemplate(this.name, this.icon, this.amount, this.hint);
}
