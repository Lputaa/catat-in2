import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

/// Local notification wrapper for spending alerts & recurring reminders.
/// Best-effort: every call is guarded so notification failures never break
/// the main flow (e.g. on platforms without notification support).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Buka'),
        windows: WindowsInitializationSettings(
          appName: 'Catat-In',
          appUserModelId: 'com.example.catat_in2',
          guid: '8f7a1c9e-2b4d-4e6f-9a3b-5c7d8e9f0a1b',
        ),
      );
      _ready = await _plugin.initialize(settings: settings) ?? false;

      // Android 13+ runtime permission
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {
      _ready = false;
    }
  }

  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Budget hit the 80% warning threshold.
  Future<void> showBudgetWarning({
    required String categoryName,
    required double percent,
    required double remaining,
  }) {
    return _show(
      _stableId('warn_$categoryName'),
      'BUDGET HAMPIR HABIS',
      'Budget $categoryName sudah ${percent.toStringAsFixed(0)}% terpakai. '
          'Sisa ${_currency.format(remaining)}.',
    );
  }

  /// Budget exceeded (crossed 100%).
  Future<void> showBudgetExceeded({
    required String categoryName,
    required double over,
  }) {
    return _show(
      _stableId('over_$categoryName'),
      'BUDGET TERLAMPAUI!',
      'Budget $categoryName kelebihan ${_currency.format(over)}. '
          'Rem dulu pengeluarannya ya.',
    );
  }

  /// Recurring transactions due tomorrow.
  Future<void> showRecurringDueTomorrow({
    required int count,
    required String names,
  }) {
    return _show(
      _stableId('recurring_tomorrow'),
      'TAGIHAN JATUH TEMPO BESOK',
      count == 1
          ? '$names jatuh tempo besok. Siapkan dananya!'
          : '$count transaksi berulang jatuh tempo besok: $names',
    );
  }

  /// Debts (hutang/piutang) due today or tomorrow.
  Future<void> showDebtDueSoon({required int count, required String names}) {
    return _show(
      _stableId('debt_due_soon'),
      'HUTANG/PIUTANG JATUH TEMPO',
      count == 1
          ? '$names segera jatuh tempo. Jangan lupa diselesaikan!'
          : '$count catatan segera jatuh tempo: $names',
    );
  }

  /// Result of a data operation (CSV export, backup, restore).
  Future<void> showDataOperation({
    required String title,
    required String body,
  }) {
    return _show(_stableId('data_$title'), title, body);
  }

  Future<void> _show(int id, String title, String body) async {
    if (!_ready) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'catat_in_alerts',
          'Peringatan Keuangan',
          channelDescription:
              'Peringatan budget dan pengingat transaksi berulang',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {
      // Notifications are best-effort only.
    }
  }

  /// Stable non-negative notification id from a string key.
  int _stableId(String key) => key.hashCode & 0x7fffffff;
}
