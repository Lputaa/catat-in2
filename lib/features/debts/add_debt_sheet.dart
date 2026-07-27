import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/debt_model.dart';
import '../../data/notifiers/debt_list_notifier.dart';
import '../../data/repositories/debt_repo.dart';
import '../../shared/widgets/neo_dialog.dart';
import '../../shared/widgets/neo_header_button.dart';

class AddDebtSheet extends ConsumerStatefulWidget {
  const AddDebtSheet({super.key, this.editItem});

  final DebtModel? editItem;
  bool get isEdit => editItem != null;

  static Future<bool?> show(BuildContext context, {DebtModel? editItem}) {
    return showNeoDialog<bool>(
      context: context,
      child: AddDebtSheet(editItem: editItem),
    );
  }

  @override
  ConsumerState<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends ConsumerState<AddDebtSheet> {
  DebtType _type = DebtType.hutang;
  final _counterpartController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      final d = widget.editItem!;
      _type = d.type;
      _counterpartController.text = d.counterpart;
      _amountController.text = d.amount.toStringAsFixed(0);
      _noteController.text = d.note ?? '';
      _dueDate = d.dueDate;
    }
  }

  @override
  void dispose() {
    _counterpartController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color get _typeColor => _type == DebtType.hutang
      ? NeoBrutalColors.danger
      : NeoBrutalColors.success;

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    final counterpart = _counterpartController.text.trim();
    final amount = double.tryParse(
      _amountController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    if (counterpart.isEmpty || amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama pihak & jumlah dengan benar')),
      );
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final notifier = ref.read(debtListProvider.notifier);
      if (widget.isEdit) {
        await notifier.updateDebt(
          widget.editItem!.copyWith(
            type: _type,
            counterpart: counterpart,
            amount: amount,
            dueDate: _dueDate,
            clearDueDate: _dueDate == null,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
          ),
        );
      } else {
        await notifier.addDebt(
          DebtModel(
            id: DebtRepo().newDebtId(),
            type: _type,
            counterpart: counterpart,
            amount: amount,
            dueDate: _dueDate,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
            createdAt: DateTime.now(),
          ),
        );
      }

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
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderColor = NeoBrutalTheme.borderColor(brightness);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
          Container(height: 8, color: _typeColor),
          _buildHeader(borderColor),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeSelector(borderColor),
                  const SizedBox(height: 8),
                  Text(
                    _type == DebtType.hutang
                        ? 'Kamu berhutang ke seseorang'
                        : 'Seseorang berhutang ke kamu',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _typeColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                    _type == DebtType.hutang ? 'HUTANG KEPADA' : 'PIUTANG KE',
                  ),
                  const SizedBox(height: 10),
                  _buildCounterpartInput(borderColor),
                  const SizedBox(height: 20),
                  _buildAmountInput(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('DETAIL'),
                  const SizedBox(height: 10),
                  _buildDueDateRow(borderColor),
                  const SizedBox(height: 12),
                  _buildNoteInput(borderColor),
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
              color: _typeColor,
              border: Border.all(
                color: borderColor,
                width: AppConstants.borderSecondary,
              ),
            ),
            child: const Icon(
              Icons.handshake_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isEdit ? 'EDIT CATATAN' : 'HUTANG / PIUTANG',
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

  Widget _buildTypeSelector(Color borderColor) {
    return Row(
      children: [
        _buildFilterChip(
          'Hutang',
          _type == DebtType.hutang,
          () {
            HapticFeedback.selectionClick();
            setState(() => _type = DebtType.hutang);
          },
          borderColor,
          activeColor: NeoBrutalColors.danger,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          'Piutang',
          _type == DebtType.piutang,
          () {
            HapticFeedback.selectionClick();
            setState(() => _type = DebtType.piutang);
          },
          borderColor,
          activeColor: NeoBrutalColors.success,
        ),
      ],
    );
  }

  Widget _buildCounterpartInput(Color borderColor) {
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
        controller: _counterpartController,
        maxLength: 60,
        textCapitalization: TextCapitalization.words,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: _type == DebtType.hutang
              ? 'cth: Budi, Kak Rina...'
              : 'cth: Andi, Kak Sarah...',
          hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: NeoBrutalColors.muted,
          ),
          prefixIcon: const Icon(Icons.person_rounded, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          isDense: true,
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: _typeColor,
          child: Text(
            'TOTAL JUMLAH',
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
        Container(height: 4, color: _typeColor),
      ],
    );
  }

  Widget _buildDueDateRow(Color borderColor) {
    return GestureDetector(
      onTap: _pickDueDate,
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
            const Icon(Icons.event_rounded, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _dueDate != null
                    ? 'Jatuh tempo: ${DateFormat('dd MMM yyyy').format(_dueDate!)}'
                    : 'Jatuh tempo (opsional)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _dueDate != null
                      ? NeoBrutalColors.ink
                      : NeoBrutalColors.muted,
                ),
              ),
            ),
            if (_dueDate != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _dueDate = null);
                },
                child: const Icon(Icons.close_rounded, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteInput(Color borderColor) {
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
        controller: _noteController,
        maxLength: 500,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Catatan (cth: cicilan HP 3 bulan)...',
          hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: NeoBrutalColors.muted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildFilterChip(
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
      onTap: onTap,
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
            color: isActive ? Colors.white : NeoBrutalColors.ink,
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
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _saving ? 'MENYIMPAN...' : 'SIMPAN',
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
