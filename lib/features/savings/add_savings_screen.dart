import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/savings_goal_repo.dart';
import '../../data/repositories/account_repo.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/dot_pattern_background.dart';
import '../../shared/widgets/neo_text_field.dart';

class AddSavingsScreen extends StatefulWidget {
  const AddSavingsScreen({super.key});

  @override
  State<AddSavingsScreen> createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends State<AddSavingsScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _deadline;
  String? _accountId;
  List<AccountModel> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accs = await AccountRepo().getAll();
    setState(() {
      _accounts = accs;
      _loading = false;
    });
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama dan target jumlah')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final repo = SavingsGoalRepo();
    await repo.insert(
      SavingsGoalModel(
        id: repo.newGoalId(),
        name: name,
        targetAmount: amount,
        savedAmount: 0,
        deadline: _deadline,
        accountId: _accountId,
      ),
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Buat Target'),
      body: DotPatternBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeoTextField(
                controller: _nameController,
                label: 'Nama Target',
                hint: 'Contoh: Liburan Bali',
                prefixIcon: Icons.flag_rounded,
              ),
              const SizedBox(height: 16),
              NeoTextField(
                controller: _amountController,
                label: 'Target Jumlah (Rp)',
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_rounded,
              ),
              const SizedBox(height: 16),
              // Deadline
              Text(
                'TENGGAT (OPSIONAL)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: NeoBrutalColors.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: NeoBrutalColors.surface,
                    border: Border.all(color: NeoBrutalColors.ink, width: 3),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _deadline != null
                              ? DateFormat('dd MMM yyyy').format(_deadline!)
                              : 'Pilih tanggal tenggat',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: const Icon(Icons.close_rounded, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Account (optional)
              Text(
                'AKUN TERKAIT (OPSIONAL)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: NeoBrutalColors.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AccountChip(
                    name: 'Tidak Ada',
                    selected: _accountId == null,
                    onTap: () => setState(() => _accountId = null),
                  ),
                  ..._accounts.map(
                    (a) => _AccountChip(
                      name: a.name,
                      selected: _accountId == a.id,
                      onTap: () => setState(() => _accountId = a.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  label: 'BUAT TARGET',
                  icon: Icons.savings_rounded,
                  color: NeoBrutalColors.success,
                  onTap: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? NeoBrutalColors.yellow : NeoBrutalColors.surface,
          border: Border.all(
            color: NeoBrutalColors.ink,
            width: selected ? 3 : 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: NeoBrutalColors.ink,
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          name.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
