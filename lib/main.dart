import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'data/database_helper.dart';
import 'data/settings_service.dart';
import 'data/ai_service.dart';
import 'data/repositories/recurring_repo.dart';
import 'data/models/recurring_transaction_model.dart';

/// Result of processing due recurring transactions on app startup.
class StartupRecurringResult {
  final int autoRecorded;
  final List<RecurringTransactionModel> needsConfirm;

  const StartupRecurringResult({
    this.autoRecorded = 0,
    this.needsConfirm = const [],
  });

  bool get hasResult => autoRecorded > 0 || needsConfirm.isNotEmpty;
}

/// Holds the result of startup recurring processing.
/// Set once in main(), read by dashboard.
final startupRecurringProvider = StateProvider<StartupRecurringResult>(
  (ref) => const StartupRecurringResult(),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for Indonesian date formatting
  await initializeDateFormatting('id_ID', '');

  // Initialize services
  await SettingsService.instance.init();
  await AiService.init();
  // Touch DB to trigger creation + seed
  await DatabaseHelper.instance.database;

  // Process due recurring transactions
  final dueItems = await RecurringRepo().getDue();
  int autoRecorded = 0;
  final needsConfirm = <RecurringTransactionModel>[];

  for (final rt in dueItems) {
    if (rt.autoRecord) {
      await RecurringRepo().recordAndAdvance(rt);
      autoRecorded++;
    } else {
      needsConfirm.add(rt);
    }
  }

  final recurringResult = StartupRecurringResult(
    autoRecorded: autoRecorded,
    needsConfirm: needsConfirm,
  );

  runApp(
    ProviderScope(
      overrides: [
        startupRecurringProvider.overrideWith((ref) => recurringResult),
      ],
      child: const CatatInApp(),
    ),
  );
}
