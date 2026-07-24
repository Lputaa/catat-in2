import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'data/database_helper.dart';
import 'data/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for Indonesian date formatting
  await initializeDateFormatting('id_ID', '');

  // Initialize services
  await SettingsService.instance.init();
  // Touch DB to trigger creation + seed
  await DatabaseHelper.instance.database;

  runApp(const ProviderScope(child: CatatInApp()));
}
