import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'repositories/transaction_repo.dart';
import 'repositories/category_repo.dart';
import 'settings_service.dart';

class AiService {
  AiService._();

  static String? _apiKey;
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';

  static String? get apiKey => _apiKey;

  /// Load persisted API key from Hive. Call once on app start.
  static Future<void> init() async {
    _apiKey = SettingsService.instance.apiKey;
  }

  /// Set API key and persist to Hive.
  static Future<void> setApiKey(String? key) async {
    _apiKey = key;
    await SettingsService.instance.setApiKey(key);
  }

  /// Generate monthly financial insight
  static Future<String> generateMonthlyInsight({
    required int year,
    required int month,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key belum diatur. Masukkan di Settings > API Key.');
    }

    final txRepo = TransactionRepo();
    final catRepo = CategoryRepo();

    // Gather data
    final txs = await txRepo.getByMonth(year, month);
    final summary = await txRepo.getMonthSummary(year, month);
    final catBreakdown = await txRepo.getCategoryBreakdown(year: year, month: month);
    final categories = await catRepo.getAll();
    final catMap = {for (final c in categories) c.id: c};

    final income = summary['income'] ?? 0;
    final expense = summary['expense'] ?? 0;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    // Build expense breakdown text
    final breakdownLines = <String>[];
    final sortedCats = catBreakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sortedCats) {
      final catName = catMap[e.key]?.name ?? e.key;
      breakdownLines.add('- $catName: ${formatter.format(e.value)}');
    }

    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));

    // Previous month for comparison
    final prevMonth = DateTime(year, month - 1);
    final prevSummary = await txRepo.getMonthSummary(prevMonth.year, prevMonth.month);
    final prevIncome = prevSummary['income'] ?? 0;
    final prevExpense = prevSummary['expense'] ?? 0;

    final prompt = '''Kamu adalah asisten keuangan pribadi. Berikan ringkasan dan insight tentang kondisi keuangan pengguna untuk bulan $monthName dalam bahasa Indonesia.

Data keuangan:
- Total pemasukan: ${formatter.format(income)}
- Total pengeluaran: ${formatter.format(expense)}
- Net: ${formatter.format(income - expense)}
- Jumlah transaksi: ${txs.length}

Breakdown pengeluaran per kategori:
${breakdownLines.join('\n')}

Perbandingan bulan lalu:
- Pemasukan bulan lalu: ${formatter.format(prevIncome)}
- Pengeluaran bulan lalu: ${formatter.format(prevExpense)}

Buat ringkasan naratif yang:
1. Jelaskan kondisi keuangan secara umum
2. Highlight kategori pengeluaran terbesar
3. Bandingkan dengan bulan lalu jika ada data
4. Berikan 2-3 saran umum (non-preskriptif) untuk pengelolaan keuangan

Gunakan bahasa yang profesional namun mudah dipahami. Maksimal 200 kata.''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey!,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 512,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['content'] as List;
    if (content.isEmpty) throw Exception('Respons kosong dari API');
    return content.first['text'] as String;
  }
}
