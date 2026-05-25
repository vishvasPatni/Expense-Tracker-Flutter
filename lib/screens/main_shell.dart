import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../constants/app_theme.dart';
import '../providers/connectivity_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/transaction_refresh.dart';
import 'budgets/budget_screen.dart';
import 'home/home_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import 'transactions/add_transaction_screen.dart';
import 'transactions/transaction_list_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_data_notifier.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.watch<NavigationNotifier>().currentIndex;
    final online = context.watch<ConnectivityNotifier>().isOnline;
    final nav = context.read<NavigationNotifier>();

    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Show exit confirmation dialog
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      body: Column(
        children: [
          if (!online)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.offlineBanner,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<ConnectivityNotifier>().recheck(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: index,
              children: const [
                HomeScreen(),
                ReportsScreen(),
                TransactionListScreen(),
                BudgetScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 96,
        decoration: BoxDecoration(
          color: dark
              ? cs.surfaceContainerHigh.withValues(alpha: 0.92)
              : cs.surfaceContainerHighest.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: dark
              ? editorialAmbientShadow(context)
              : const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 40,
                    offset: Offset(0, -4),
                  ),
                ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                label: 'HOME',
                selected: index == 0,
                icon: index == 0 ? Icons.home : Icons.home_outlined,
                onTap: () => nav.setIndex(0),
              ),
              _NavItem(
                label: 'INSIGHTS',
                selected: index == 1,
                icon: index == 1 ? Icons.insights : Icons.insights_outlined,
                onTap: () => nav.setIndex(1),
              ),
              _NavItem(
                label: 'TRANSACTIONS',
                selected: index == 2,
                icon: index == 2 ? Icons.receipt_long : Icons.receipt_long_outlined,
                onTap: () => nav.setIndex(2),
              ),
              _NavItem(
                label: 'BUDGETS',
                selected: index == 3,
                icon: index == 3 ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
                onTap: () => nav.setIndex(3),
              ),
              _NavItem(
                label: 'SETTINGS',
                selected: index == 4,
                icon: index == 4 ? Icons.settings : Icons.settings_outlined,
                onTap: () => nav.setIndex(4),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: index == 0 || index == 2 || index == 3
          ? FloatingActionButton(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(index == 0 ? 32 : 16),
              ),
              onPressed: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                )
                    .then((_) {
                  if (context.mounted) {
                    context.read<TransactionRefresh>().bump();
                  }
                });
              },
              tooltip: 'Add transaction',
              child: Icon(Icons.add, color: cs.onPrimaryContainer),
            )
          : null,
      floatingActionButtonLocation: index == 2 || index == 3
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer.withValues(alpha: 0.45) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 10,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shell entry for named routes: always shows [MainShell] with bottom navigation.
/// Use [initialTabIndex] so `/insights` and deep links open the correct tab without a duplicate full-screen flow.
class MainShellEntry extends StatefulWidget {
  const MainShellEntry({super.key, this.initialTabIndex});

  /// Bottom-nav index (0–4). When null, the current [NavigationNotifier] index is kept.
  final int? initialTabIndex;

  @override
  State<MainShellEntry> createState() => _MainShellEntryState();
}

class _MainShellEntryState extends State<MainShellEntry> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Hydrate settings if we arrived here directly (skipping splash)
    try {
      if (mounted) {
        await Future.wait<void>([
          context.read<ThemeNotifier>().hydrateFromRemote(),
          context.read<SettingsDataNotifier>().hydrateFromRemote(),
        ]);
      }
    } catch (_) {
      // Non-fatal if sync fails
    }

    if (!mounted) return;

    // 2. Handle initial tab
    final tab = widget.initialTabIndex;
    if (tab != null) {
      context.read<NavigationNotifier>().setIndex(tab);
    }
  }

  @override
  Widget build(BuildContext context) => const MainShell();
}
