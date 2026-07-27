import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/neo_brutal_theme.dart';
import 'data/settings_service.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
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

// ── Onboarding Completed Provider ──
// Initialized from Hive; set true by OnboardingScreen when finished/skipped.
final onboardingCompletedProvider = StateProvider<bool>(
  (ref) => SettingsService.instance.onboardingCompleted,
);

class CatatInApp extends ConsumerWidget {
  const CatatInApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final onboardingDone = ref.watch(onboardingCompletedProvider);

    return MaterialApp(
      title: 'Catat-In',
      debugShowCheckedModeBanner: false,
      theme: NeoBrutalTheme.light(),
      darkTheme: NeoBrutalTheme.dark(),
      themeMode: themeMode,
      home: onboardingDone ? const _AppShell() : const OnboardingScreen(),
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
        child: _LazyIndexedStack(index: index, children: _screens),
      ),
      bottomNavigationBar: const NeoBottomNavigation(),
    );
  }
}

/// IndexedStack that builds each tab only after its first visit.
/// Keeps state alive afterwards — FUTURE-DEVELOPMENT.md §9 (startup perf).
class _LazyIndexedStack extends StatefulWidget {
  const _LazyIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final List<bool> _activated = List.filled(widget.children.length, false);

  @override
  Widget build(BuildContext context) {
    _activated[widget.index] = true;
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _activated[i] ? widget.children[i] : const SizedBox.shrink(),
      ],
    );
  }
}
