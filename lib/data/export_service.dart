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

  /// Export all transactions to CSV and share
  static Future<String> exportTransactionsCsv({
    int? year,
    int? month,
  }) async {
    final txRepo = TransactionRepo();
    final catRepo = CategoryRepo();
    final accRepo = AccountRepo();

    final categories = await catRepo.getAll();
    final accounts = await accRepo.getAll();
    final catMap = {for (final c in categories) c.id: c};
    final accMap = {for (final a in accounts) a.id: a};

    List<TransactionModel> txs;
    String periodLabel;
    if (year != null && month != null) {
      txs = await txRepo.getByMonth(year, month);
      periodLabel = DateFormat('yyyy-MM').format(DateTime(year, month));
    } else {
      txs = await txRepo.getAll();
      periodLabel = 'semua';
    }

    final buffer = StringBuffer();
    // Header
    buffer.writeln('Tanggal,Tipe,Kategori,Akun,Jumlah,Catatan');

    // Rows
    for (final tx in txs) {
      final date = DateFormat('yyyy-MM-dd').format(tx.date);
      final type = tx.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran';
      final cat = catMap[tx.categoryId]?.name ?? tx.categoryId;
      final acc = accMap[tx.accountId]?.name ?? tx.accountId;
      final amount = tx.amount.toStringAsFixed(0);
      final note = tx.note != null ? '"${tx.note!.replaceAll('"', '""')}"' : '';
      buffer.writeln('$date,$type,$cat,$acc,$amount,$note');
    }

    // Summary
    final totalIncome = txs.where((t) => t.type == TransactionType.income).fold<double>(0, (a, t) => a + t.amount);
    final totalExpense = txs.where((t) => t.type == TransactionType.expense).fold<double>(0, (a, t) => a + t.amount);
    buffer.writeln();
    buffer.writeln('Total Pemasukan,,,,$totalIncome');
    buffer.writeln('Total Pengeluaran,,,,$totalExpense');
    buffer.writeln('Net,,,${totalIncome - totalExpense}');

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/catat_in_$periodLabel.csv');
    await file.writeAsString(buffer.toString(), encoding: const SystemEncoding());

    // Share
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Laporan Catat-In ($periodLabel)',
    );

    return file.path;
  }
}
