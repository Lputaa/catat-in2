import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_dialog.dart';
import '../../shared/widgets/neo_icon_container.dart';
import '../../shared/widgets/neo_section_header.dart';
import '../../data/export_service.dart';
import '../../data/backup_service.dart';
import '../../data/database_helper.dart';
import '../../data/notification_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'category_management_screen.dart';
import 'account_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: const CatatInAppBar(subtitle: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme section
            const NeoSectionHeader(title: 'TAMPILAN'),
            const SizedBox(height: 8),
            _ThemeSelector(
              current: themeMode,
              onChanged: (mode) =>
                  ref.read(themeModeProvider.notifier).setMode(mode),
            ),
            const SizedBox(height: 24),

            // Data section
            const NeoSectionHeader(title: 'DATA'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.category_rounded,
              iconColor: NeoBrutalColors.primary,
              title: 'Kelola Kategori',
              subtitle: 'Tambah, edit, atau hapus kategori',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoryManagementScreen(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.account_balance_wallet_rounded,
              iconColor: NeoBrutalColors.secondary,
              title: 'Kelola Akun',
              subtitle: 'Atur dompet dan rekening',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountManagementScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Export section
            const NeoSectionHeader(title: 'EKSPOR'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.table_chart_rounded,
              iconColor: NeoBrutalColors.success,
              title: 'Ekspor CSV',
              subtitle: 'Unduh laporan transaksi bulan ini',
              onTap: () async {
                final now = DateTime.now();
                final messenger = ScaffoldMessenger.of(context);
                final targetPath = await ExportService.csvTargetPath(
                  year: now.year,
                  month: now.month,
                );
                final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(now);

                if (!context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('EKSPOR CSV?'),
                    content: Text(
                      'Laporan transaksi $monthLabel akan disimpan di:\n\n'
                      '$targetPath\n\n'
                      'Setelah itu dialog share akan terbuka. Lanjutkan?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('BATAL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('EKSPOR'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;

                messenger.showSnackBar(
                  const SnackBar(content: Text('Mengekspor...')),
                );
                try {
                  final path = await ExportService.exportTransactionsCsv(
                    year: now.year,
                    month: now.month,
                  );
                  await NotificationService.instance.showDataOperation(
                    title: 'EKSPOR CSV BERHASIL',
                    body: 'Laporan tersimpan di: $path',
                  );
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Tersimpan: $path')),
                  );
                } catch (e) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
            const SizedBox(height: 24),

            // Backup section
            const NeoSectionHeader(title: 'BACKUP & RESTORE'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.backup_rounded,
              iconColor: NeoBrutalColors.cyan,
              title: 'Backup Data',
              subtitle: 'Backup data ke perangkat',
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('BACKUP DATA?'),
                    content: const Text(
                      'Semua data (transaksi, wallet, budget, target, hutang) '
                      'akan diekspor ke satu file JSON.\n\n'
                      'Kamu akan memilih sendiri folder & nama file lewat '
                      'dialog "Simpan sebagai". Lanjutkan?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('BATAL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('BACKUP'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;

                try {
                  // User picks the save location via system dialog
                  final path = await BackupService.instance.exportWithPicker();
                  if (path == null) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Backup dibatalkan')),
                    );
                    return;
                  }
                  await NotificationService.instance.showDataOperation(
                    title: 'BACKUP BERHASIL',
                    body: 'Data tersimpan di: $path',
                  );
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Backup tersimpan: $path')),
                  );
                } catch (e) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Backup gagal: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.restore_rounded,
              iconColor: NeoBrutalColors.orange,
              title: 'Restore Data',
              subtitle: 'Pulihkan data dari file backup',
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result == null || result.files.single.path == null) {
                    return;
                  }

                  final file = File(result.files.single.path!);
                  final json = await file.readAsString();

                  // Validate first
                  final summary = await BackupService.instance.validate(json);

                  if (!context.mounted) return;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('RESTORE DATA?'),
                      content: Text(
                        'File backup:\n${file.path}\n\n'
                        'Semua data saat ini akan diganti dengan:\n\n$summary\n\nLanjutkan?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('BATAL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'RESTORE',
                            style: TextStyle(color: NeoBrutalColors.danger),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Merestore data...')),
                    );
                    final count = await BackupService.instance.restoreFromJson(
                      json,
                    );
                    await NotificationService.instance.showDataOperation(
                      title: 'RESTORE BERHASIL',
                      body:
                          '$count data dipulihkan. Restart aplikasi untuk '
                          'melihat hasilnya.',
                    );
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Berhasil restore $count data. Restart app.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Restore gagal: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.delete_forever_rounded,
              iconColor: NeoBrutalColors.danger,
              title: 'Hapus Semua Data',
              subtitle: 'Reset aplikasi ke kondisi awal',
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('HAPUS SEMUA DATA?'),
                    content: const Text(
                      'Semua transaksi, wallet, budget, target, dan hutang akan '
                      'dihapus permanen. Kategori & wallet bawaan akan dibuat ulang.\n\n'
                      'Tindakan ini TIDAK bisa dibatalkan. Backup dulu jika ragu.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('BATAL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'HAPUS SEMUA',
                          style: TextStyle(color: NeoBrutalColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;

                messenger.showSnackBar(
                  const SnackBar(content: Text('Menghapus data...')),
                );
                try {
                  await DatabaseHelper.instance.wipeAllData();
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Semua data terhapus. Restart aplikasi.'),
                    ),
                  );
                } catch (e) {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal menghapus data: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // About
            const NeoSectionHeader(title: 'TENTANG'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.volunteer_activism_rounded,
              iconColor: NeoBrutalColors.orange,
              title: 'Support Me',
              subtitle: 'Traktir Gwehh lewat Saweria ☕',
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final uri = Uri.parse('https://saweria.co/Lputaa');
                try {
                  final ok = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!ok) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Gagal membuka Saweria. Coba lagi ya!'),
                      ),
                    );
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal membuka Saweria: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            NeoCard(
              padding: const EdgeInsets.all(16),
              onTap: () => showNeoDialog<void>(
                context: context,
                child: const _AboutDialog(),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: NeoBrutalColors.primary,
                      border: Border.all(color: NeoBrutalColors.ink, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catat-In',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Financial Tracker v1.0.0 · ketuk untuk info',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.info_outline_rounded, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onChanged});
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ThemeOption(
            icon: Icons.light_mode_rounded,
            label: 'Terang',
            selected: current == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _ThemeOption(
            icon: Icons.dark_mode_rounded,
            label: 'Gelap',
            selected: current == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
          _ThemeOption(
            icon: Icons.phone_android_rounded,
            label: 'Sistem',
            selected: current == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? NeoBrutalColors.yellow : Colors.transparent,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? NeoBrutalColors.ink : NeoBrutalColors.muted,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: 0.8,
                  color: selected ? NeoBrutalColors.ink : NeoBrutalColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: onTap,
      borderOffset: AppConstants.shadowSmall,
      child: Row(
        children: [
          NeoIconContainer(
            icon: icon,
            color: iconColor,
            size: NeoIconSize.medium,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 22),
        ],
      ),
    );
  }
}

/// Playful Neo-Brutal "about" popup for the TENTANG card.
class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  static const _quotes = [
    'Mencatat pengeluaran itu gratis. Nangisnya belakangan.',
    'Saldo tidak bertambah hanya dengan dilihat. Sudah kami coba.',
    'Budgeting itu seperti diet: mulai Senin, bocor Selasa.',
    'ngopi mah ga salah. Yang salah frekuensinya.',
    'Dompet aman bukan karena tebal, tapi karena dicatat.',
    'Uang bisa hilang. Catatannya? tinggal disini.',
  ];

  @override
  Widget build(BuildContext context) {
    final quote = _quotes[math.Random().nextInt(_quotes.length)];

    return NeoCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header band
          Container(
            decoration: const BoxDecoration(
              color: NeoBrutalColors.primary,
              border: Border(
                bottom: BorderSide(color: NeoBrutalColors.ink, width: 3),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: -16,
                  top: -18,
                  child: Icon(
                    Icons.savings_rounded,
                    size: 96,
                    color: NeoBrutalColors.ink.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: NeoBrutalColors.ink,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: NeoBrutalColors.ink,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'C',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: NeoBrutalColors.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CATAT-IN',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: NeoBrutalColors.ink,
                            ),
                          ),
                          Text(
                            'FINANCIAL TRACKER · v1.1.0',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: NeoBrutalColors.ink.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Random quote of the day
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      NeoBrutalColors.primary.withValues(alpha: 0.12),
                      Theme.of(context).brightness == Brightness.dark
                          ? NeoBrutalColors.surfaceDark
                          : NeoBrutalColors.surface,
                    ),
                    border: Border.all(color: NeoBrutalColors.ink, width: 2),
                  ),
                  child: Text(
                    '“$quote”',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _AboutFactRow(
                  icon: Icons.wifi_off_rounded,
                  color: NeoBrutalColors.success,
                  text: '100% offline. onlinenya when-when aja yhh.',
                ),
                const SizedBox(height: 8),
                const _AboutFactRow(
                  icon: Icons.block_rounded,
                  color: NeoBrutalColors.danger,
                  text: 'Tanpa iklan, tanpa login, tinggal pake wehh.',
                ),
                const SizedBox(height: 8),
                const _AboutFactRow(
                  icon: Icons.favorite_rounded,
                  color: NeoBrutalColors.orange,
                  text: 'guehh gabutt, dibuat dengan niat 50%.',
                ),
                const SizedBox(height: 16),
                // Developer credit
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: NeoBrutalColors.ink,
                    border: Border.all(color: NeoBrutalColors.ink, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoBrutalColors.primary,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DEVELOP BY LAPUTAA',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'katanya sih ngoding dari kastil di atas awan ☁',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: NeoBrutalColors.primary,
                      border: Border.all(color: NeoBrutalColors.ink, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoBrutalColors.ink,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'SIP, LANJUT NABUNG!',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: NeoBrutalColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutFactRow extends StatelessWidget {
  const _AboutFactRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: NeoBrutalColors.ink, width: 2),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
