import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/savings_contribution_model.dart';
import '../../data/repositories/savings_goal_repo.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/dot_pattern_background.dart';

class SavingsDetailScreen extends StatefulWidget {
  const SavingsDetailScreen({super.key, required this.goal});
  final SavingsGoalModel goal;

  @override
  State<SavingsDetailScreen> createState() => _SavingsDetailScreenState();
}

class _SavingsDetailScreenState extends State<SavingsDetailScreen> {
  late SavingsGoalModel _goal;
  List<SavingsContributionModel> _contributions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _load();
  }

  Future<void> _load() async {
    final repo = SavingsGoalRepo();
    final goal = await repo.getById(_goal.id);
    final contribs = await repo.getContributions(_goal.id);
    setState(() {
      if (goal != null) _goal = goal;
      _contributions = contribs;
      _loading = false;
    });
  }

  void _openAddContribution() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? NeoBrutalColors.bgDark
                : NeoBrutalColors.bg,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? NeoBrutalColors.darkLine
                    : NeoBrutalColors.ink,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TAMBAH KONTRIBUSI',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  label: 'TAMBAH',
                  icon: Icons.add_circle_outline_rounded,
                  color: NeoBrutalColors.success,
                  onTap: () async {
                    final amount = double.tryParse(
                      amountController.text
                          .replaceAll('.', '')
                          .replaceAll(',', ''),
                    );
                    if (amount == null || amount <= 0) return;

                    HapticFeedback.mediumImpact();
                    final repo = SavingsGoalRepo();
                    await repo.addContribution(
                      SavingsContributionModel(
                        id: repo.newContribId(),
                        goalId: _goal.id,
                        amount: amount,
                        date: DateTime.now(),
                        note: noteController.text.isNotEmpty
                            ? noteController.text
                            : null,
                      ),
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      _load();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editGoal() {
    final nameController = TextEditingController(text: _goal.name);
    final amountController = TextEditingController(
      text: _goal.targetAmount.toStringAsFixed(0),
    );
    DateTime? deadline = _goal.deadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark
                  ? NeoBrutalColors.bgDark
                  : NeoBrutalColors.bg,
              border: Border(
                top: BorderSide(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? NeoBrutalColors.darkLine
                      : NeoBrutalColors.ink,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EDIT TARGET',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nama Target',
                    prefixIcon: Icon(Icons.flag_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Target Jumlah (Rp)',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          deadline ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setSheetState(() => deadline = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: NeoBrutalColors.surface,
                      border: Border.all(color: NeoBrutalColors.ink, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            deadline != null
                                ? DateFormat('dd MMM yyyy').format(deadline!)
                                : 'Tenggat (opsional)',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (deadline != null)
                          GestureDetector(
                            onTap: () => setSheetState(() => deadline = null),
                            child: const Icon(Icons.close_rounded, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: NeoButton(
                    label: 'SIMPAN PERUBAHAN',
                    icon: Icons.check_circle_outline_rounded,
                    color: NeoBrutalColors.success,
                    onTap: () async {
                      final name = nameController.text.trim();
                      final amount = double.tryParse(
                        amountController.text
                            .replaceAll('.', '')
                            .replaceAll(',', ''),
                      );
                      if (name.isEmpty || amount == null || amount <= 0) return;
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      await SavingsGoalRepo().update(
                        _goal.copyWith(
                          name: name,
                          targetAmount: amount,
                          deadline: deadline,
                        ),
                      );
                      if (mounted) {
                        _load();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HAPUS TARGET?'),
        content: Text(
          'Target "${_goal.name}" dan semua kontribusi akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SavingsGoalRepo().delete(_goal.id);
              HapticFeedback.mediumImpact();
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text(
              'HAPUS',
              style: TextStyle(color: NeoBrutalColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final statusColor = _goal.isComplete
        ? NeoBrutalColors.success
        : _goal.percent >= 0.8
        ? NeoBrutalColors.orange
        : NeoBrutalColors.secondary;

    return Scaffold(
      appBar: CatatInAppBar(
        subtitle: _goal.name,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit_rounded,
              size: 22,
              color: Theme.of(context).brightness == Brightness.dark
                  ? NeoBrutalColors.inkDark
                  : NeoBrutalColors.ink,
            ),
            onPressed: _editGoal,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: NeoBrutalColors.danger,
            ),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: DotPatternBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card
              NeoCard(
                color: statusColor,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TARGET',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      formatter.format(_goal.targetAmount),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TERKUMPUL',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      formatter.format(_goal.savedAmount),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 14,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: _goal.percent.clamp(0, 1),
                            child: Container(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_goal.percent * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (_goal.deadline != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tenggat: ${DateFormat('dd MMM yyyy').format(_goal.deadline!)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Add contribution button
              if (!_goal.isComplete)
                SizedBox(
                  width: double.infinity,
                  child: NeoButton(
                    label: 'TAMBAH KONTRIBUSI',
                    icon: Icons.add_rounded,
                    color: NeoBrutalColors.yellow,
                    onTap: _openAddContribution,
                  ),
                ),
              const SizedBox(height: 24),

              // Contribution history
              Text(
                'RIWAYAT KONTRIBUSI',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              if (_contributions.isEmpty)
                NeoCard(
                  child: Center(
                    child: Text(
                      'Belum ada kontribusi',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                ..._contributions.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NeoCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      borderOffset: const Offset(4, 4),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: NeoBrutalColors.success.withValues(
                                alpha: 0.15,
                              ),
                              border: Border.all(
                                color: NeoBrutalColors.success,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: NeoBrutalColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.note ?? 'Kontribusi',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy').format(c.date),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${formatter.format(c.amount)}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: NeoBrutalColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
