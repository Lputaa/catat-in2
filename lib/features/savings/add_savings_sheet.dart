import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/account_model.dart';
import '../../data/notifiers/savings_list_notifier.dart';
import '../../data/repositories/savings_goal_repo.dart';
import '../../data/repositories/account_repo.dart';
import '../../shared/widgets/neo_dialog.dart';
import '../../shared/widgets/neo_header_button.dart';

class AddSavingsSheet extends ConsumerStatefulWidget {
  const AddSavingsSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showNeoDialog<bool>(
      context: context,
      child: const AddSavingsSheet(),
    );
  }

  @override
  ConsumerState<AddSavingsSheet> createState() => _AddSavingsSheetState();
}

class _AddSavingsSheetState extends ConsumerState<AddSavingsSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _deadline;
  String? _accountId;
  List<AccountModel> _accounts = [];
  bool _loading = true;
  bool _saving = false;

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: NeoBrutalColors.secondary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _deadline = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (name.isEmpty || amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama dan target jumlah')),
      );
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = SavingsGoalRepo();
      final goal = SavingsGoalModel(
        id: repo.newGoalId(),
        name: name,
        targetAmount: amount,
        savedAmount: 0,
        deadline: _deadline,
        accountId: _accountId,
      );
      await ref.read(savingsListProvider.notifier).addGoal(goal);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 420,
      ),
      decoration: BoxDecoration(
        color: brightness == Brightness.light
            ? NeoBrutalColors.bg
            : NeoBrutalColors.bgDark,
        border: Border.all(
          color: borderColor,
          width: AppConstants.borderPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: AppConstants.shadowLarge,
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 8, color: NeoBrutalColors.secondary),
          _buildHeader(borderColor),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNameInput(borderColor),
                    const SizedBox(height: 20),
                    _buildAmountInput(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('TENGGAT (OPSIONAL)'),
                    const SizedBox(height: 10),
                    _buildDeadlinePicker(borderColor),
                    const SizedBox(height: 16),
                    _buildSectionTitle('AKUN TERKAIT (OPSIONAL)'),
                    const SizedBox(height: 10),
                    _buildAccountChips(borderColor),
                    const SizedBox(height: 24),
                    _buildSaveButton(borderColor),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color borderColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: AppConstants.borderSecondary,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NeoBrutalColors.secondary,
              border: Border.all(
                color: borderColor,
                width: AppConstants.borderSecondary,
              ),
            ),
            child: const Icon(
              Icons.savings_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'TARGET BARU',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          NeoHeaderButton(
            icon: Icons.close_rounded,
            borderColor: borderColor,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        color:
            (Theme.of(context).brightness == Brightness.dark
                    ? NeoBrutalColors.inkDark
                    : NeoBrutalColors.ink)
                .withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildNameInput(Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: NeoBrutalColors.surface,
        border: Border.all(
          color: borderColor,
          width: AppConstants.borderSecondary,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _nameController,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Contoh: Liburan Bali',
          hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: NeoBrutalColors.muted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          isDense: true,
        ),
        autofocus: true,
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: NeoBrutalColors.secondary,
          child: Text(
            'TARGET JUMLAH',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: NeoBrutalColors.surface,
            border: Border.all(
              color: NeoBrutalColors.ink,
              width: AppConstants.borderPrimary,
            ),
            boxShadow: [
              BoxShadow(
                color: NeoBrutalColors.ink,
                offset: AppConstants.shadowDefault,
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: NeoBrutalColors.muted, width: 2),
                  ),
                ),
                child: Text(
                  'Rp',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalColors.ink.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalColors.muted,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 4, color: NeoBrutalColors.secondary),
      ],
    );
  }

  Widget _buildDeadlinePicker(Color borderColor) {
    return GestureDetector(
      onTap: _pickDeadline,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: NeoBrutalColors.surface,
          border: Border.all(
            color: borderColor,
            width: AppConstants.borderSecondary,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _deadline != null
                    ? DateFormat('dd MMM yyyy').format(_deadline!)
                    : 'Pilih tanggal tenggat',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_deadline != null)
              GestureDetector(
                onTap: () => setState(() => _deadline = null),
                child: const Icon(Icons.close_rounded, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountChips(Color borderColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(
          'Tidak Ada',
          _accountId == null,
          () => setState(() => _accountId = null),
          borderColor,
        ),
        ..._accounts.map(
          (acc) => _buildChip(
            acc.name,
            _accountId == acc.id,
            () => setState(() => _accountId = acc.id),
            borderColor,
            activeColor: NeoBrutalColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    String label,
    bool isActive,
    VoidCallback onTap,
    Color borderColor, {
    Color? activeColor,
  }) {
    final color = activeColor ?? NeoBrutalColors.yellow;
    final inactiveBg = Theme.of(context).brightness == Brightness.dark
        ? NeoBrutalColors.bgDark
        : NeoBrutalColors.bg;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : inactiveBg,
          border: Border.all(
            color: borderColor,
            width: AppConstants.borderSecondary,
          ),
          boxShadow: isActive
              ? []
              : [
                  BoxShadow(
                    color: borderColor,
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
        ),
        transform: isActive
            ? (Matrix4.identity()..translateByDouble(1.5, 1.5, 0.0, 1.0))
            : Matrix4.identity(),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
            color: isActive
                ? (activeColor != null ? Colors.white : NeoBrutalColors.ink)
                : NeoBrutalColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(Color borderColor) {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: AnimatedContainer(
        duration: AppConstants.animButton,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _saving ? NeoBrutalColors.muted : NeoBrutalColors.success,
          border: Border.all(
            color: borderColor,
            width: AppConstants.borderPrimary,
          ),
          boxShadow: _saving
              ? []
              : [
                  BoxShadow(
                    color: borderColor,
                    offset: AppConstants.shadowDefault,
                    blurRadius: 0,
                  ),
                ],
        ),
        transform: _saving
            ? (Matrix4.identity()..translateByDouble(
                AppConstants.shadowDefault.dx / 2,
                AppConstants.shadowDefault.dy / 2,
                0.0,
                1.0,
              ))
            : Matrix4.identity(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_saving) ...[
              const Icon(Icons.savings_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              _saving ? 'MENYIMPAN...' : 'BUAT TARGET',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
