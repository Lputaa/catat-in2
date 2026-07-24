import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repo.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/neo_text_field.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/dot_pattern_background.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  List<AccountModel> _accounts = [];
  Map<String, double> _balances = {};
  bool _loading = true;
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = AccountRepo();
    final accs = await repo.getAll();
    final balances = <String, double>{};
    for (final a in accs) {
      balances[a.id] = await repo.getBalance(a.id);
    }
    setState(() {
      _accounts = accs;
      _balances = balances;
      _loading = false;
    });
  }

  void _openForm({AccountModel? edit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountFormSheet(
        account: edit,
        onSaved: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  void _confirmDelete(AccountModel acc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('HAPUS AKUN?'),
        content: Text(
          'Akun "${acc.name}" akan dihapus. Transaksi terkait tidak terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AccountRepo().delete(acc.id);
              HapticFeedback.mediumImpact();
              _load();
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
    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Kelola Akun'),
      body: DotPatternBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _accounts.length,
                itemBuilder: (context, i) {
                  final acc = _accounts[i];
                  final balance = _balances[acc.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NeoCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      onTap: () => _openForm(edit: acc),
                      borderOffset: AppConstants.shadowSmall,
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: NeoBrutalColors.secondary.withValues(
                                alpha: 0.15,
                              ),
                              border: Border.all(
                                color: NeoBrutalColors.secondary,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _iconForType(acc.type),
                              size: 20,
                              color: NeoBrutalColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc.name,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  acc.typeLabel,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
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
                                formatter.format(balance),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: balance >= 0
                                      ? NeoBrutalColors.success
                                      : NeoBrutalColors.danger,
                                ),
                              ),
                              Text(
                                'Saldo',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: NeoBrutalColors.danger,
                            ),
                            onPressed: () => _confirmDelete(acc),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NeoBrutalColors.yellow,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded, color: NeoBrutalColors.ink),
      ),
    );
  }

  IconData _iconForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.ewallet:
        return Icons.account_balance_wallet_rounded;
      case AccountType.other:
        return Icons.wallet_rounded;
    }
  }
}

class _AccountFormSheet extends StatefulWidget {
  const _AccountFormSheet({this.account, required this.onSaved});
  final AccountModel? account;
  final VoidCallback onSaved;

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  AccountType _type = AccountType.cash;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.initialBalance.toStringAsFixed(
        0,
      );
      _type = widget.account!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama tidak boleh kosong')));
      return;
    }
    final balance =
        double.tryParse(
          _balanceController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;

    final repo = AccountRepo();
    if (widget.account != null) {
      await repo.update(
        widget.account!.copyWith(
          name: name,
          initialBalance: balance,
          type: _type,
        ),
      );
    } else {
      await repo.insert(
        AccountModel(
          id: repo.newId(),
          name: name,
          initialBalance: balance,
          type: _type,
        ),
      );
    }

    HapticFeedback.mediumImpact();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.account != null;
    return Padding(
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
              width: AppConstants.borderPrimary,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'EDIT AKUN' : 'TAMBAH AKUN',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 20),
            NeoTextField(
              controller: _nameController,
              label: 'Nama Akun',
              hint: 'Contoh: BCA',
            ),
            const SizedBox(height: 16),
            NeoTextField(
              controller: _balanceController,
              label: 'Saldo Awal',
              hint: '0',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_rounded,
            ),
            const SizedBox(height: 16),
            Text(
              'TIPE AKUN',
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
              children: AccountType.values.map((t) {
                final selected = _type == t;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? NeoBrutalColors.yellow
                          : NeoBrutalColors.surface,
                      border: Border.all(
                        color: NeoBrutalColors.ink,
                        width: selected ? 3 : 2,
                      ),
                    ),
                    child: Text(
                      _labelForType(t).toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: NeoButton(
                label: isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAH AKUN',
                icon: Icons.check_circle_outline_rounded,
                color: NeoBrutalColors.success,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForType(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return 'Tunai';
      case AccountType.bank:
        return 'Rekening Bank';
      case AccountType.ewallet:
        return 'E-Wallet';
      case AccountType.other:
        return 'Lainnya';
    }
  }
}
