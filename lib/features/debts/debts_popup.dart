import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/debt_payment_model.dart';
import '../../data/notifiers/debt_list_notifier.dart';
import '../../data/repositories/debt_repo.dart';
import 'add_debt_sheet.dart';

/// Popup daftar hutang/piutang, dibuka dari carousel dashboard.
/// Mengikuti pola popup "SEMUA TARGET" milik Target Menabung.
class DebtsListPopup extends ConsumerWidget {
  const DebtsListPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (_) => const DebtsListPopup());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debtListProvider);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    // Aktif dulu, yang lunas di bawah.
    final debts = [...state.debts]
      ..sort((a, b) {
        if (a.isSettled != b.isSettled) return a.isSettled ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });

    return Dialog(
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
                    'HUTANG & PIUTANG',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    AddDebtSheet.show(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: NeoBrutalColors.purple,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Ringkasan sisa hutang & piutang
            Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                    label: 'SISA HUTANG',
                    amount: state.totalHutang,
                    color: NeoBrutalColors.danger,
                    formatter: formatter,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryChip(
                    label: 'SISA PIUTANG',
                    amount: state.totalPiutang,
                    color: NeoBrutalColors.success,
                    formatter: formatter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (debts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Belum ada catatan.\nTap + untuk mencatat.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: NeoBrutalColors.muted,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: debts.length,
                  itemBuilder: (ctx, i) {
                    final debt = debts[i];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        // Popup detail di atas popup list.
                        DebtDetailPopup.show(context, debt);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _DebtRow(debt: debt, formatter: formatter),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.formatter,
  });

  final String label;
  final double amount;
  final Color color;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: NeoBrutalColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatter.format(amount),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.debt, required this.formatter});

  final DebtModel debt;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final isHutang = debt.type == DebtType.hutang;
    final typeColor = debt.isSettled
        ? NeoBrutalColors.muted
        : isHutang
        ? NeoBrutalColors.danger
        : NeoBrutalColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                border: Border.all(color: typeColor, width: 2),
              ),
              child: Icon(
                debt.isSettled
                    ? Icons.check_circle_rounded
                    : isHutang
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                size: 16,
                color: typeColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.counterpart.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    debt.isSettled
                        ? 'LUNAS'
                        : debt.isOverdue
                        ? 'JATUH TEMPO!'
                        : debt.dueDate != null
                        ? 'Tempo ${DateFormat('dd MMM yyyy').format(debt.dueDate!)}'
                        : debt.typeLabel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: debt.isOverdue && !debt.isSettled
                          ? NeoBrutalColors.danger
                          : NeoBrutalColors.ink.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              debt.isSettled
                  ? formatter.format(debt.amount)
                  : formatter.format(debt.remaining),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: typeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 8,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: NeoBrutalColors.muted,
                  border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: debt.percent.clamp(0, 1),
                child: Container(color: typeColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Popup detail satu catatan — tampil DI ATAS popup list.
class DebtDetailPopup extends ConsumerStatefulWidget {
  const DebtDetailPopup({super.key, required this.initialDebt});

  final DebtModel initialDebt;

  static Future<void> show(BuildContext context, DebtModel debt) {
    return showDialog(
      context: context,
      builder: (_) => DebtDetailPopup(initialDebt: debt),
    );
  }

  @override
  ConsumerState<DebtDetailPopup> createState() => _DebtDetailPopupState();
}

class _DebtDetailPopupState extends ConsumerState<DebtDetailPopup> {
  final _repo = DebtRepo();
  List<DebtPaymentModel> _payments = [];
  bool _loadingPayments = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments = await _repo.getPayments(widget.initialDebt.id);
    if (!mounted) return;
    setState(() {
      _payments = payments;
      _loadingPayments = false;
    });
  }

  void _showPaymentDialog(DebtModel debt, {double? prefill}) {
    final isHutang = debt.type == DebtType.hutang;
    final amountController = TextEditingController(
      text: prefill != null ? prefill.toStringAsFixed(0) : '',
    );
    final noteController = TextEditingController();
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    // Lapis ketiga: dialog bayar di atas popup detail.
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHutang ? 'BAYAR CICILAN' : 'CATAT PENERIMAAN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sisa: ${formatter.format(debt.remaining)}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(
                amountController.text.replaceAll('.', '').replaceAll(',', ''),
              );
              if (amount == null || amount <= 0) return;
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              await ref
                  .read(debtListProvider.notifier)
                  .addPayment(
                    DebtPaymentModel(
                      id: _repo.newPaymentId(),
                      debtId: debt.id,
                      amount: amount,
                      date: DateTime.now(),
                      note: noteController.text.isNotEmpty
                          ? noteController.text
                          : null,
                    ),
                  );
              if (mounted) _loadPayments();
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(DebtModel debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HAPUS CATATAN?'),
        content: Text(
          '${debt.typeLabel} "${debt.counterpart}" dan semua riwayat pembayaran akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(debtListProvider.notifier).deleteDebt(debt.id);
              HapticFeedback.mediumImpact();
              if (mounted) Navigator.pop(context); // tutup popup detail
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
    // Ambil data terbaru dari provider agar popup ikut ter-update.
    final state = ref.watch(debtListProvider);
    final debt = state.debts
        .where((d) => d.id == widget.initialDebt.id)
        .firstOrNull;
    if (debt == null) {
      // Sudah dihapus — tidak ada yang ditampilkan.
      return const SizedBox.shrink();
    }

    final isHutang = debt.type == DebtType.hutang;
    final typeColor = debt.isSettled
        ? NeoBrutalColors.success
        : isHutang
        ? NeoBrutalColors.danger
        : NeoBrutalColors.purple;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: badge + judul + aksi
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  color: typeColor,
                  child: Text(
                    debt.isSettled ? 'LUNAS' : debt.typeLabel.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    debt.counterpart.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    // Lapis ketiga: sheet edit di atas popup detail.
                    final result = await AddDebtSheet.show(
                      context,
                      editItem: debt,
                    );
                    if (result == true && mounted) _loadPayments();
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.edit_rounded, size: 20),
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmDelete(debt),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: NeoBrutalColors.danger,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Ringkasan jumlah + progress
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: typeColor,
                border: Border.all(color: NeoBrutalColors.ink, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL ${formatter.format(debt.amount)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isHutang ? 'Dibayar' : 'Diterima'}: ${formatter.format(debt.paidAmount)}'
                    ' • Sisa: ${formatter.format(debt.remaining)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 12,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: debt.percent.clamp(0, 1),
                          child: Container(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (debt.dueDate != null || debt.isOverdue) ...[
                    const SizedBox(height: 8),
                    Text(
                      debt.isOverdue
                          ? 'JATUH TEMPO ${DateFormat('dd MMM yyyy').format(debt.dueDate!).toUpperCase()}!'
                          : 'TEMPO ${DateFormat('dd MMM yyyy').format(debt.dueDate!).toUpperCase()}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  if (debt.note != null && debt.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      debt.note!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Aksi bayar/lunasi
            if (!debt.isSettled)
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: isHutang ? 'BAYAR' : 'TERIMA',
                      icon: Icons.add_card_rounded,
                      color: typeColor,
                      onTap: () => _showPaymentDialog(debt),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: 'LUNASI',
                      icon: Icons.done_all_rounded,
                      color: NeoBrutalColors.success,
                      onTap: () =>
                          _showPaymentDialog(debt, prefill: debt.remaining),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              'RIWAYAT PEMBAYARAN',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingPayments)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_payments.isEmpty)
              Text(
                'Belum ada pembayaran tercatat',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: NeoBrutalColors.muted,
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _payments.length,
                  itemBuilder: (ctx, i) {
                    final p = _payments[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 16,
                            color: typeColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy • HH:mm',
                                  ).format(p.date),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (p.note != null && p.note!.isNotEmpty)
                                  Text(
                                    p.note!,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: NeoBrutalColors.ink.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            formatter.format(p.amount),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
