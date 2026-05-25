import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'providers/connectivity_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/settings_data_notifier.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_refresh.dart';
import 'providers/app_lock_provider.dart';
import 'providers/privacy_provider.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'services/settings_service.dart';
import 'widgets/lock_gate.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    if (AppConfig.hasSupabaseConfig) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedOut &&
            appNavigatorKey.currentState != null) {
          appNavigatorKey.currentState!.pushNamedAndRemoveUntil(
                '/sign-in',
                (_) => false,
              );
        }
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasSupabaseConfig) {
      return MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        home: const _MissingConfigScreen(),
      );
    }

    return MultiProvider(
      providers: [
        Provider<SettingsService>(create: (_) => SettingsService()),
        ChangeNotifierProvider<ThemeNotifier>(
          create: (ctx) => ThemeNotifier(ctx.read<SettingsService>()),
        ),
        ChangeNotifierProvider<SettingsDataNotifier>(
          create: (ctx) =>
              SettingsDataNotifier(ctx.read<SettingsService>()),
        ),
        ChangeNotifierProvider<ConnectivityNotifier>(
          create: (_) => ConnectivityNotifier(),
        ),
        ChangeNotifierProvider<NavigationNotifier>(
          create: (_) => NavigationNotifier(),
        ),
        ChangeNotifierProvider<TransactionRefresh>(
          create: (_) => TransactionRefresh(),
        ),
        ChangeNotifierProvider<AppLockProvider>(
          create: (_) => AppLockProvider()..initialize(),
        ),
        ChangeNotifierProvider<PrivacyProvider>(
          create: (_) => PrivacyProvider()..initialize(),
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, theme, _) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            themeMode: theme.themeMode,
            builder: (context, child) {
              return LockGate(child: child ?? const SizedBox.shrink());
            },
            initialRoute: Supabase.instance.client.auth.currentSession == null ? '/' : '/main',
            routes: {
              '/': (_) => const SplashScreen(),
              '/sign-in': (_) => const SignInScreen(),
              '/sign-up': (_) => const SignUpScreen(),
              // Same shell as /main; selects Insights tab (for web/deep links). Prefer setIndex(1) in-app.
              '/insights': (_) => const MainShellEntry(initialTabIndex: 1),
              '/main': (_) => const MainShellEntry(initialTabIndex: 0),
            },
          );
        },
      ),
    );
  }
}

class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Add your Supabase URL and anon key in assets/config/app.env (then '
          'rebuild), or pass --dart-define=SUPABASE_URL=… and '
          '--dart-define=SUPABASE_ANON_KEY=…. See README.md and env.example.',
        ),
      ),
    );
  }
}
