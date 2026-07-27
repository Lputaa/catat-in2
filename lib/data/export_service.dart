import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'models/transaction_model.dart';
import 'repositories/transaction_repo.dart';
import 'repositories/category_repo.dart';
import 'repositories/account_repo.dart';

class ExportService {
  ExportService._();

  static String _periodLabel(int? year, int? month) {
    if (year != null && month != null) {
      return DateFormat('yyyy-MM').format(DateTime(year, month));
    }
    return 'semua';
  }

  /// The path where [exportTransactionsCsv] will write the CSV file.
  /// Used to show the target location in the confirmation dialog.
  static Future<String> csvTargetPath({int? year, int? month}) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/catat_in_${_periodLabel(year, month)}.csv';
  }

  /// Export all transactions to CSV and share
  static Future<String> exportTransactionsCsv({int? year, int? month}) async {
    final txRepo = TransactionRepo();
    final catRepo = CategoryRepo();
    final accRepo = AccountRepo();

    final categories = await catRepo.getAll();
    final accounts = await accRepo.getAll();
    final catMap = {for (final c in categories) c.id: c};
    final accMap = {for (final a in accounts) a.id: a};

    List<TransactionModel> txs;
    if (year != null && month != null) {
      txs = await txRepo.getByMonth(year, month);
    } else {
      txs = await txRepo.getAll();
    }
    final periodLabel = _periodLabel(year, month);

    if (txs.isEmpty) {
      throw Exception('Tidak ada transaksi untuk diekspor');
    }

    final buffer = StringBuffer();
    // Header
    buffer.writeln('Tanggal,Tipe,Kategori,Akun,Jumlah,Catatan');

    // Rows
    for (final tx in txs) {
      final date = DateFormat('yyyy-MM-dd').format(tx.date);
      final type = tx.type == TransactionType.income
          ? 'Pemasukan'
          : 'Pengeluaran';
      final cat = catMap[tx.categoryId]?.name ?? tx.categoryId;
      final acc = accMap[tx.accountId]?.name ?? tx.accountId;
      final amount = tx.amount.toStringAsFixed(0);
      final note = tx.note != null ? '"${tx.note!.replaceAll('"', '""')}"' : '';
      buffer.writeln('$date,$type,$cat,$acc,$amount,$note');
    }

    // Summary
    final totalIncome = txs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (a, t) => a + t.amount);
    final totalExpense = txs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (a, t) => a + t.amount);
    buffer.writeln();
    buffer.writeln('Total Pemasukan,,,,$totalIncome');
    buffer.writeln('Total Pengeluaran,,,,$totalExpense');
    buffer.writeln('Net,,,${totalIncome - totalExpense}');

    // Save file
    final file = File(await csvTargetPath(year: year, month: month));
    await file.writeAsString(
      buffer.toString(),
      encoding: const SystemEncoding(),
    );

    // Share
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Laporan Catat-In ($periodLabel)');

    return file.path;
  }
}
