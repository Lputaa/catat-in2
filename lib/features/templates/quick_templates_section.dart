import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/theme/neo_brutal_theme.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_template_model.dart';
import '../../data/notifiers/dashboard_providers.dart';
import '../../data/notifiers/transaction_list_notifier.dart';
import '../../data/repositories/account_repo.dart';
import '../../data/repositories/category_repo.dart';
import '../../data/repositories/template_repo.dart';
import '../../data/repositories/transaction_repo.dart';
import 'template_form_sheet.dart';

/// Dashboard section: horizontal quick-entry template shortcuts.
/// Tap a template → confirm → transaction recorded (2 taps total).
class QuickTemplatesSection extends ConsumerWidget {
  const QuickTemplatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider).valueOrNull ?? [];
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 18),
            const SizedBox(width: 6),
            Text(
              'QUICK ENTRY',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 74,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final t in templates) ...[
                _TemplateCard(template: t, brightness: brightness),
                const SizedBox(width: 10),
              ],
              _AddTemplateCard(brightness: brightness),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template, required this.brightness});

  final TransactionTemplateModel template;
  final Brightness brightness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = template.type == TransactionType.expense;
    final accent = isExpense ? NeoBrutalColors.danger : NeoBrutalColors.success;
    final baseBg = brightness == Brightness.dark
        ? NeoBrutalColors.bgDark
        : NeoBrutalColors.bg;
    final formatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: () => _confirmRecord(context, ref),
      onLongPress: () => _confirmDelete(context, ref),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // Impeller-safe: pre-blend translucent accent onto opaque bg
          color: Color.alphaBlend(accent.withValues(alpha: 0.10), baseBg),
          border: Border.all(
            color: NeoBrutalTheme.borderColor(brightness),
            width: 2,
          ),
          boxShadow: NeoBrutalTheme.hardShadow(
            offset: const Offset(3, 3),
            brightness: brightness,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  isExpense
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 13,
                  color: accent,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    template.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formatter.format(template.amount),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRecord(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final category = await CategoryRepo().getById(template.categoryId);
    final accounts = await AccountRepo().getAll();
    final account = accounts.where((a) => a.id == template.accountId).toList();
    if (!context.mounted) return;
    if (category == null || account.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori/wallet template sudah dihapus')),
      );
      return;
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CATAT TRANSAKSI?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Nama', template.name),
            _detailRow('Jumlah', formatter.format(template.amount)),
            _detailRow('Kategori', category.name),
            _detailRow('Wallet', account.first.name),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'CATAT',
              style: TextStyle(color: NeoBrutalColors.success),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final repo = TransactionRepo();
    final tx = TransactionModel(
      id: repo.newId(),
      type: template.type,
      amount: template.amount,
      categoryId: template.categoryId,
      accountId: template.accountId,
      date: DateTime.now(),
      note: template.note ?? template.name,
    );
    await ref.read(transactionListProvider.notifier).addTransaction(tx);
    HapticFeedback.mediumImpact();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dicatat: ${template.name}')));
    }
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HAPUS TEMPLATE?'),
        content: Text('Template "${template.name}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
    );
    if (confirmed != true) return;
    await TemplateRepo().delete(template.id);
    ref.invalidate(templatesProvider);
  }
}

class _AddTemplateCard extends ConsumerWidget {
  const _AddTemplateCard({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final saved = await TemplateFormSheet.show(context);
        if (saved == true) ref.invalidate(templatesProvider);
      },
      child: Container(
        width: 74,
        decoration: BoxDecoration(
          border: Border.all(
            color: NeoBrutalTheme.borderColor(brightness),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 22),
            const SizedBox(height: 2),
            Text(
              'TEMPLATE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
