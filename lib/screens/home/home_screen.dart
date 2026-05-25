import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_data_notifier.dart';
import '../../providers/transaction_refresh.dart';
import '../../services/budget_service.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../constants/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/privacy_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tx = TransactionService();
  final _cat = CategoryService();
  final _budgetSvc = BudgetService();

  final DateTime _month = DateTime.now();
  bool _loading = true;
  String? _error;
  int _selectedRange = 0;

  double _income = 0;
  double _expense = 0;
  List<TransactionModel> _recent = [];
  List<Map<String, dynamic>> _categorySlices = [];
  double? _budgetAmount;
  double _spent = 0;

  TransactionRefresh? _refreshBus;
  bool _refreshListening = false;
  RealtimeChannel? _homeChannel;
  Timer? _realtimeDebounce;
  bool _liveConnected = false;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    // Initial skeleton for curated feel
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _refresh();
    });
  }

  void _onGlobalRefresh() {
    if (mounted) _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bus = context.read<TransactionRefresh>();
    if (!_refreshListening) {
      bus.addListener(_onGlobalRefresh);
      _refreshBus = bus;
      _refreshListening = true;
    }
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    final channel = _homeChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    if (_refreshListening) {
      _refreshBus?.removeListener(_onGlobalRefresh);
    }
    super.dispose();
  }

  void _setupRealtime() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final channel = Supabase.instance.client.channel('home-live-$uid')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (_) => _scheduleRefresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'categories',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (_) => _scheduleRefresh(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'budgets',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (_) => _scheduleRefresh(),
      )
      ..subscribe((status, [error]) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _liveConnected = status == RealtimeSubscribeStatus.subscribed;
          });
        });
      });

    _homeChannel = channel;
  }

  void _scheduleRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _refresh(silent: true);
    });
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      // Calculate date range based on selected filter
      DateTime rangeStart;
      DateTime rangeEnd;
      
      switch (_selectedRange) {
        case 0: // Today
          final now = DateTime.now();
          rangeStart = DateTime(now.year, now.month, now.day);
          rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 1: // Week
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          rangeStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
          rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 2: // Month
          rangeStart = startOfMonth(_month);
          rangeEnd = endOfMonth(_month);
          break;
        case 3: // Custom (default to current month for now)
          rangeStart = startOfMonth(_month);
          rangeEnd = endOfMonth(_month);
          break;
        default:
          rangeStart = startOfMonth(_month);
          rangeEnd = endOfMonth(_month);
      }
      
      final results = await Future.wait([
        _tx.fetchAll(dateFrom: rangeStart, dateTo: rangeEnd),
        _cat.fetchCategories(),
        _tx.categoryExpenseTotals(start: rangeStart, end: rangeEnd),
        _budgetSvc.fetchOverallForMonth(_month),
        _budgetSvc.monthlyExpenseTotal(_month),
      ]);

      if (!mounted) return;
      
      final transactions = results[0] as List<TransactionModel>;
      final slices = results[2] as List<Map<String, dynamic>>;
      final BudgetModel? budget = results[3] as BudgetModel?;
      final double spent = results[4] as double;
      
      // Calculate income and expense from transactions
      double income = 0;
      double expense = 0;
      for (var tx in transactions) {
        if (tx.isIncome) {
          income += tx.amount;
        } else if (tx.isExpense) {
          expense += tx.amount;
        }
      }
      
      // Get recent transactions (last 5)
      final recent = transactions.take(5).toList();

      setState(() {
        _income = income;
        _expense = expense;
        _recent = recent;
        _categorySlices = slices;
        _budgetAmount = budget?.amount;
        _spent = spent;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted && !silent) {
        setState(() {
          _error = 'load';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = context.watch<SettingsDataNotifier>().currencySymbol;
    final balance = _income - _expense;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '?';
    final initial = email.isNotEmpty ? email.substring(0, 1).toUpperCase() : '?';
    final spentPct = (_budgetAmount ?? 0) > 0
        ? ((_spent / _budgetAmount!) * 100).clamp(0.0, 100.0).toDouble()
        : 62.8;
    final topSlices = _topCategorySlices(cs);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? const HomeScreenSkeleton()
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Text('Could not load dashboard.'),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.of(context).size.width * 0.06,
                      MediaQuery.of(context).size.height * 0.10,
                      MediaQuery.of(context).size.width * 0.06,
                      MediaQuery.of(context).size.height * 0.15,
                    ),
                    children: [
                      _header(context, initial),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hi, ${email.split("@").first}',
                        style: TextStyle(
                          fontSize: 40,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.02 * 16,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _heroBalance(context, balance, currency),
                      const SizedBox(height: 24),
                      _rangeFilters(context),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              context,
                              title: 'TOTAL INCOME',
                              value: _income,
                              symbol: currency,
                              icon: Icons.account_balance_wallet_outlined,
                              color: cs.primary,
                              iconBg: cs.primary.withValues(alpha: 0.12),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _summaryCard(
                              context,
                              title: 'TOTAL EXPENSES',
                              value: _expense,
                              symbol: currency,
                              icon: Icons.receipt_long_outlined,
                              color: cs.secondary,
                              iconBg: cs.secondary.withValues(alpha: 0.18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _savingsCard(context, balance, currency, spentPct),
                      const SizedBox(height: 16),
                      _insightCard(context),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Spending by category',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.read<NavigationNotifier>().setIndex(1),
                            icon: Icon(Icons.insights, color: cs.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _donutCard(context, topSlices, currency, cs),
                      if (_recent.isEmpty) ...[
                        const SizedBox(height: 20),
                        const EmptyStateWidget(
                          icon: Icons.receipt_long,
                          title: 'No transactions this month',
                          subtitle: 'Add transactions to populate this dashboard.',
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _header(BuildContext context, String initial) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: cs.primaryContainer,
          child: Text(
            initial,
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Spndly',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: cs.onSurface,
            ),
          ),
        ),
        Icon(
          _liveConnected ? Icons.wifi_tethering : Icons.sync_problem,
          size: 18,
          color: cs.primary,
        ),
      ],
    );
  }

  Widget _heroBalance(BuildContext context, double balance, String currency) {
    final cs = Theme.of(context).colorScheme;
    return PrivacyRevealButton(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary, cs.primaryContainer],
          ),
          boxShadow: editorialAmbientShadow(context),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          children: [
            const Text(
              'TOTAL BALANCE',
              style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.4),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: MaskedMoneyText(
                amount: formatMoney(balance, currency).replaceAll('.00', ''),
                currency: currency,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2.8,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chipTotal('↑', _income, currency),
                const SizedBox(width: 12),
                _chipTotal('↓', _expense, currency),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeFilters(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labels = ['Today', 'Week', 'Month', 'Custom'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _selectedRange == i;
          return Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
            child: FilterChip(
              showCheckmark: false,
              selected: selected,
              selectedColor: cs.primary,
              backgroundColor: cs.surfaceContainerLow,
              label: Text(
                labels[i],
                style: TextStyle(
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              onSelected: (_) {
                setState(() => _selectedRange = i);
                _refresh(); // Refresh data when range changes
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _chipTotal(String arrow, double value, String currency) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            arrow,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          MaskedMoneyText(
            amount: formatMoney(value, currency).replaceAll('.00', ''),
            currency: currency,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    required double value,
    required String symbol,
    required IconData icon,
    required Color color,
    required Color iconBg,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: editorialAmbientShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          MaskedMoneyText(
            amount: formatMoney(value, symbol).replaceAll('.00', ''),
            currency: symbol,
            style: TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _savingsCard(BuildContext context, double balance, String currency, double spentPct) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: editorialAmbientShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.savings_outlined, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAVINGS GOAL',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                MaskedMoneyText(
                  amount: formatMoney(balance, currency).replaceAll('.00', ''),
                  currency: currency,
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${spentPct.toStringAsFixed(1)}% achieved',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 96,
                height: 6,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (spentPct / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insightCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    String insightText = "Welcome to your financial dashboard. Start adding transactions to see insights.";
    String topCat = "spending";
    if (_categorySlices.isNotEmpty) {
      final top = _categorySlices.first;
      topCat = top['name']?.toString() ?? 'spending';
      insightText = "Your highest spending is in $topCat. Review your transactions to optimize your budget.";
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border(
          left: BorderSide(color: cs.primary, width: 4),
        ),
        boxShadow: editorialAmbientShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: cs.primary.withValues(alpha: 0.22),
            child: Icon(Icons.tips_and_updates_outlined, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Smart Insight",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insightText,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.55,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _donutCard(
    BuildContext context,
    List<Map<String, Object>> slices,
    String currency,
    ColorScheme cs,
  ) {
    final hasData = slices.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
        boxShadow: editorialAmbientShadow(context),
      ),
      child: Column(
        children: [
          Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: hasData ? cs.primary : cs.surfaceContainerHighest,
                width: 8,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MaskedMoneyText(
                  amount: formatMoney(_expense, currency).replaceAll('.00', ''),
                  currency: currency,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'SPENT',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (hasData)
            Wrap(
              spacing: 28,
              runSpacing: 16,
              children: slices
                  .map(
                    (slice) => _legendItem(
                      cs: cs,
                      color: slice['color']! as Color,
                      label: '${slice['name']} (${slice['percent']}%)',
                    ),
                  )
                  .toList(),
            )
          else
            Text(
              'No allocations to split yet',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendItem({required ColorScheme cs, required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Map<String, Object>> _topCategorySlices(ColorScheme cs) {
    final total = _categorySlices.fold<double>(
      0,
      (a, m) => a + TransactionService.parseNum(m['total_amount']),
    );
    if (total <= 0) return [];

    final sorted = [..._categorySlices];
    sorted.sort(
      (a, b) => TransactionService.parseNum(b['total_amount'])
          .compareTo(TransactionService.parseNum(a['total_amount'])),
    );
    final colors = [cs.primary, cs.secondary, cs.tertiary, cs.surfaceContainerHigh];

    final out = <Map<String, Object>>[];
    for (var i = 0; i < sorted.length && i < 4; i++) {
      final m = sorted[i];
      final amt = TransactionService.parseNum(m['total_amount']);
      out.add({
        'name': (m['name'] as String?) ?? 'Other',
        'percent': ((amt / total) * 100).round(),
        'color': colors[i],
      });
    }
    return out;
  }
}
