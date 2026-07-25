import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_brutal_colors.dart';
import '../../data/ai_service.dart';
import '../../shared/widgets/catat_in_app_bar.dart';
import '../../shared/widgets/dot_pattern_background.dart';
import '../../shared/widgets/neo_card.dart';
import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/neo_text_field.dart';

class InsightScreen extends ConsumerStatefulWidget {
  const InsightScreen({super.key});

  @override
  ConsumerState<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends ConsumerState<InsightScreen> {
  String? _insight;
  bool _loading = false;
  String? _error;
  final _apiKeyController = TextEditingController();
  bool _showApiKeyInput = AiService.apiKey == null;

  @override
  void initState() {
    super.initState();
    if (AiService.apiKey != null) {
      _apiKeyController.text = AiService.apiKey!;
    }
  }

  Future<void> _generate() async {
    if (AiService.apiKey == null || AiService.apiKey!.isEmpty) {
      setState(() => _showApiKeyInput = true);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _insight = null;
    });

    try {
      final now = DateTime.now();
      final result = await AiService.generateMonthlyInsight(
        year: now.year,
        month: now.month,
      );
      setState(() {
        _insight = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;
    await AiService.setApiKey(key);
    setState(() => _showApiKeyInput = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API Key tersimpan')));
    }
  }

  Future<void> _clearApiKey() async {
    await AiService.setApiKey(null);
    _apiKeyController.clear();
    setState(() {
      _showApiKeyInput = true;
      _insight = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API Key dihapus')));
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? NeoBrutalColors.bgDark
          : NeoBrutalColors.bg,
      appBar: const CatatInAppBar(subtitle: 'Insight AI'),
      body: DotPatternBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Key input
            if (_showApiKeyInput) ...[
              NeoCard(
                color: Color.alphaBlend(
                  NeoBrutalColors.yellow.withValues(alpha: 0.2),
                  NeoBrutalColors.bg,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.key_rounded,
                          size: 20,
                          color: NeoBrutalColors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'API KEY DIPERLUKAN',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masukkan Anthropic API Key untuk menggunakan fitur ini.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeoTextField(
                      controller: _apiKeyController,
                      hint: 'sk-ant-...',
                      prefixIcon: Icons.lock_rounded,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: NeoButton(
                        label: 'SIMPAN KEY',
                        icon: Icons.check_rounded,
                        color: NeoBrutalColors.success,
                        fontSize: 12,
                        onTap: _saveApiKey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Generate button
            if (AiService.apiKey != null && !_showApiKeyInput) ...[
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _clearApiKey,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: NeoBrutalColors.muted,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.key_off_rounded,
                          size: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? NeoBrutalColors.inkDark.withValues(alpha: 0.6)
                              : NeoBrutalColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'HAPUS API KEY',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? NeoBrutalColors.inkDark.withValues(alpha: 0.6)
                                : NeoBrutalColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            NeoCard(
              color: NeoBrutalColors.purple,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'INSIGHT $now'.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ringkasan keuangan otomatis berdasarkan data transaksi bulan ini.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: NeoButton(
                      label: _loading ? 'MENGANALISIS...' : 'GENERATE INSIGHT',
                      icon: _loading ? null : Icons.auto_awesome_rounded,
                      color: NeoBrutalColors.yellow,
                      onTap: _loading ? null : _generate,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Loading
            if (_loading)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Claude sedang menganalisis keuanganmu...',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Error
            if (_error != null)
              NeoCard(
                color: Color.alphaBlend(
                  NeoBrutalColors.danger.withValues(alpha: 0.1),
                  NeoBrutalColors.bg,
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: NeoBrutalColors.danger,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: NeoBrutalColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Result
            if (_insight != null) ...[
              Text(
                'HASIL INSIGHT',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              NeoCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: NeoBrutalColors.purple.withValues(
                              alpha: 0.15,
                            ),
                            border: Border.all(
                              color: NeoBrutalColors.purple,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: NeoBrutalColors.purple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'CLAUDE INSIGHT',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: NeoBrutalColors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _insight!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Disclaimer
              Text(
                'Insight dihasilkan oleh AI dan bersifat umum. Bukan nasihat keuangan profesional.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: NeoBrutalColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
