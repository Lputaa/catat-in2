import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_icon_container.dart';
import '../../shared/widgets/neo_section_header.dart';
import '../../data/export_service.dart';
import '../../data/backup_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../insight/insight_screen.dart';
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
              onChanged: (mode) => ref.read(themeModeProvider.notifier).setMode(mode),
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
                MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
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
                MaterialPageRoute(builder: (_) => const AccountManagementScreen()),
              ),
            ),
            const SizedBox(height: 24),

            // Export & Insight section
            const NeoSectionHeader(title: 'EKSPOR & INSIGHT'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.table_chart_rounded,
              iconColor: NeoBrutalColors.success,
              title: 'Ekspor CSV',
              subtitle: 'Unduh laporan transaksi bulan ini',
              onTap: () async {
                final now = DateTime.now();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mengekspor...')),
                );
                try {
                  final path = await ExportService.exportTransactionsCsv(
                    year: now.year,
                    month: now.month,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tersimpan: $path')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.auto_awesome_rounded,
              iconColor: NeoBrutalColors.purple,
              title: 'Insight AI',
              subtitle: 'Ringkasan keuangan otomatis (Claude)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InsightScreen()),
              ),
            ),
            const SizedBox(height: 24),

            // Backup section
            const NeoSectionHeader(title: 'BACKUP & RESTORE'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.backup_rounded,
              iconColor: NeoBrutalColors.cyan,
              title: 'Backup Data',
              subtitle: 'Ekspor semua data ke file JSON',
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Membuat backup...')),
                );
                try {
                  final path = await BackupService.instance.exportAndShare();
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
                  if (result == null || result.files.single.path == null) return;

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
                    final count = await BackupService.instance.restoreFromJson(json);
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      SnackBar(content: Text('Berhasil restore $count data. Restart app.')),
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
            const SizedBox(height: 24),

            // About
            const NeoSectionHeader(title: 'TENTANG'),
            const SizedBox(height: 8),
            NeoCard(
              padding: const EdgeInsets.all(16),
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
                      child: Text('C', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catat-In',
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Financial Tracker v1.0.0',
                          style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
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
              Icon(icon, size: 20, color: selected ? NeoBrutalColors.ink : NeoBrutalColors.muted),
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
                  style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500),
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
