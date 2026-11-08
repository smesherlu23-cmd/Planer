import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/database.dart';
import 'services/notifications.dart';
import 'ui/common.dart';
import 'ui/habits_screen.dart';
import 'ui/money_screen.dart';
import 'ui/more_screen.dart';
import 'ui/setup_screen.dart';
import 'ui/today_screen.dart';
import 'ui/workouts_screen.dart';

class PlanerApp extends StatelessWidget {
  const PlanerApp({super.key, required this.db, required this.notifications});

  final AppDatabase db;
  final NotificationService notifications;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2E7D6B);
    return AppScope(
      db: db,
      notifications: notifications,
      child: MaterialApp(
        title: 'Planer',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: _theme(ColorScheme.fromSeed(seedColor: seed)),
        darkTheme: _theme(ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark)),
        home: const _Root(),
      ),
    );
  }

  ThemeData _theme(ColorScheme scheme) => ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
  );
}

/// Показывает первый запуск или главный экран.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: context.db.watchSetting('setup_done'),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == null) return const SetupScreen();
        return const HomeShell();
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  static const _pages = <Widget>[TodayScreen(), HabitsScreen(), MoneyScreen(), WorkoutsScreen(), MoreScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Сегодня'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Привычки'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Деньги',
          ),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Спорт'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Ещё'),
        ],
      ),
    );
  }
}
