import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_helper.dart';

/// Backup & Restore service for Catat-In.
/// Exports all financial data as a portable JSON file.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _backupVersion = 1;

  /// Export all data to a JSON file and open the share dialog.
  /// Returns the path of the exported file.
  Future<String> exportAndShare() async {
    final json = await _exportToJson();
    final dir = await getTemporaryDirectory();
    final now = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final filePath = join(dir.path, 'catat-in-backup_$now.json');
    final file = File(filePath);
    await file.writeAsString(json);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Catat-In Backup',
    );

    return filePath;
  }

  /// Export all data as a JSON string.
  Future<String> _exportToJson() async {
    final db = await DatabaseHelper.instance.database;

    final tables = [
      'categories',
      'accounts',
      'transactions',
      'budgets',
      'savings_goals',
      'savings_contributions',
      'recurring_transactions',
    ];

    final data = <String, dynamic>{
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'Catat-In',
    };

    for (final table in tables) {
      final rows = await db.query(table);
      data[table] = rows;
    }

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Restore data from a JSON string.
  /// Clears all existing data and replaces with backup contents.
  /// Returns the number of records restored.
  Future<int> restoreFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    // Validate structure
    if (data['app'] != 'Catat-In') {
      throw Exception('File backup tidak valid: bukan dari Catat-In');
    }

    final db = await DatabaseHelper.instance.database;
    int totalRecords = 0;

    await db.transaction((txn) async {
      // Clear all tables in reverse FK order
      await txn.delete('savings_contributions');
      await txn.delete('savings_goals');
      await txn.delete('recurring_transactions');
      await txn.delete('budgets');
      await txn.delete('transactions');
      await txn.delete('accounts');
      await txn.delete('categories');

      // Insert in FK order
      final tables = [
        'categories',
        'accounts',
        'transactions',
        'budgets',
        'savings_goals',
        'savings_contributions',
        'recurring_transactions',
      ];

      for (final table in tables) {
        final rows = data[table] as List<dynamic>?;
        if (rows != null) {
          for (final row in rows) {
            await txn.insert(table, Map<String, dynamic>.from(row as Map));
            totalRecords++;
          }
        }
      }
    });

    return totalRecords;
  }

  /// Validate a backup file's structure without restoring.
  /// Returns a summary string or throws on invalid format.
  Future<String> validate(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    if (data['app'] != 'Catat-In') {
      throw Exception('File bukan backup Catat-In');
    }

    final version = data['version'] as int? ?? 0;
    final exportedAt = data['exportedAt'] as String? ?? 'unknown';
    final txCount = (data['transactions'] as List?)?.length ?? 0;
    final catCount = (data['categories'] as List?)?.length ?? 0;
    final accCount = (data['accounts'] as List?)?.length ?? 0;

    return 'v$version, $txCount transaksi, $catCount kategori, $accCount akun\nDiekspor: $exportedAt';
  }
}
