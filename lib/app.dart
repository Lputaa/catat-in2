import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/neo_brutal_theme.dart';
import 'data/settings_service.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/transactions/transaction_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/widgets/dot_pattern_background.dart';
import 'shared/widgets/neo_bottom_navigation.dart';

// ── Theme Mode Provider ──
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(SettingsService.instance.themeMode);

  void setMode(ThemeMode mode) {
    state = mode;
    SettingsService.instance.setThemeMode(mode);
  }
}

// ── Navigation Index Provider ──
final navIndexProvider = StateProvider<int>((ref) => 0);

class CatatInApp extends ConsumerWidget {
  const CatatInApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Catat-In',
      debugShowCheckedModeBanner: false,
      theme: NeoBrutalTheme.light(),
      darkTheme: NeoBrutalTheme.dark(),
      themeMode: themeMode,
      home: const _AppShell(),
    );
  }
}

class _AppShell extends ConsumerWidget {
  const _AppShell();

  static const _screens = <Widget>[
    DashboardScreen(),
    TransactionScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);

    return Scaffold(
      body: DotPatternBackground(
        child: IndexedStack(
          index: index,
          children: _screens,
        ),
      ),
      bottomNavigationBar: const NeoBottomNavigation(),
    );
  }
}
