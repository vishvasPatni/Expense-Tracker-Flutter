import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_data_notifier.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../constants/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton.dart';

enum _ReportPeriod { week, month, year }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _tx = TransactionService();
  final _cat = CategoryService();
  RealtimeChannel? _channel;
  Timer? _debounce;

  _ReportPeriod _period = _ReportPeriod.week;
  bool _loading = true;
  String? _error;

  List<TransactionModel> _periodTransactions = [];
  List<CategoryModel> _categories = [];
  double _prevPeriodExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final channel = _channel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  void _setupRealtime() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _channel = Supabase.instance.client.channel('insights-realtime-$uid')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (_) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            if (mounted) _load(silent: true);
          });
        },
      )
      ..subscribe();
  }

  (DateTime, DateTime) _range() {
    final now = DateTime.now();
    switch (_period) {
      case _ReportPeriod.week:
        return weekRangeContaining(now);
      case _ReportPeriod.month:
        return (startOfMonth(now), endOfMonth(now));
      case _ReportPeriod.year:
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31, 23, 59, 59));
    }
  }

  String _periodName(_ReportPeriod p) {
    switch (p) {
      case _ReportPeriod.week: return 'week';
      case _ReportPeriod.month: return 'month';
      case _ReportPeriod.year: return 'year';
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _loading = true);
    final (start, end) = _range();
    
    DateTime pStart, pEnd;
    if (_period == _ReportPeriod.week) {
       pStart = start.subtract(const Duration(days: 7));
       pEnd = start.subtract(const Duration(milliseconds: 1));
    } else if (_period == _ReportPeriod.month) {
       pStart = DateTime(start.year, start.month - 1, 1);
       pEnd = DateTime(start.year, start.month, 0);
    } else {
       pStart = DateTime(start.year - 1, 1, 1);
       pEnd = DateTime(start.year - 1, 12, 31, 23, 59, 59);
    }

    try {
      final results = await Future.wait([
        _tx.fetchAll(dateFrom: start, dateTo: end),
        _cat.fetchCategories(),
      ]);
      final prevResults = await _tx.fetchAll(dateFrom: pStart, dateTo: pEnd);
      
      if (!mounted) return;
      setState(() {
        _periodTransactions = results[0] as List<TransactionModel>;
        _categories = results[1] as List<CategoryModel>;
        _prevPeriodExpense = prevResults.where((t) => t.isExpense).fold<double>(0, (a, b) => a + b.amount);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _loading = false;
          _error = 'load';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sym = context.watch<SettingsDataNotifier>().currencySymbol;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '?';
    final initial = email.isNotEmpty ? email.substring(0, 1).toUpperCase() : '?';
    
    final expenses = _periodTransactions.where((t) => t.isExpense).toList();
    final totalOutflow = expenses.fold<double>(0, (a, t) => a + t.amount);

    // Compute Cat Sums
    Map<String, double> catSums = {};
    for (var t in expenses) {
      catSums[t.categoryId] = (catSums[t.categoryId] ?? 0) + t.amount;
    }
    String topCatId = '';
    double topCatAmt = 0;
    catSums.forEach((k, v) {
      if (v > topCatAmt) {
        topCatAmt = v;
        topCatId = k;
      }
    });
    String topCatName = 'Unknown Category';
    if (topCatId.isNotEmpty) {
      final cat = _categories.where((c) => c.id == topCatId).toList();
      if (cat.isNotEmpty) topCatName = cat.first.name;
    }

    // Advice text
    String advice = topCatAmt > 0 
      ? "Based on your trend, reducing your $topCatName expenses by 10% next ${_periodName(_period)} could save you ${_money(sym, topCatAmt * 0.1)}."
      : "You are doing great! Consider keeping up this momentum and allocating saved funds to an Emergency Reserve.";

    // Savings insight
    final diff = _prevPeriodExpense - totalOutflow;
    String savingTitle = diff >= 0 ? 'Enhanced Savings' : 'Increased Spending';
    String savingText = diff >= 0 
      ? 'You saved ${_money(sym, diff)} compared to last ${_periodName(_period)}.'
      : 'You spent ${_money(sym, -diff)} more than last ${_periodName(_period)}.';
    Color savingColor = diff >= 0 ? cs.primary : const Color(0xFFF9A0A0); // Slightly customized error tint so it fits dark/light gracefully
    Color savingBgColor = diff >= 0 ? cs.primary.withValues(alpha: 0.14) : const Color(0xFF3C0000).withValues(alpha: 0.3);
    if (Theme.of(context).brightness == Brightness.light) {
      savingColor = diff >= 0 ? cs.primary : cs.error;
      savingBgColor = diff >= 0 ? cs.primary.withValues(alpha: 0.12) : cs.errorContainer;
    }

    // Category Insight
    String catTitle = topCatAmt > 0 ? 'Highest Outflow' : 'Zero Outflow';
    String catText = topCatAmt > 0 
      ? 'Your highest spending was in $topCatName (${_money(sym, topCatAmt)}).'
      : 'You have no recorded expenses for this period.';

    return Scaffold(
      backgroundColor: cs.surface,
      body: _loading
          ? const StatsScreenSkeleton()
          : _error != null
              ? ListView(
                  children: [
                    EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: 'Could not load insights',
                      subtitle: 'Please try again.',
                      actionLabel: 'Retry',
                      onAction: _load,
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.of(context).size.width * 0.04,
                      MediaQuery.of(context).size.height * 0.10,
                      MediaQuery.of(context).size.width * 0.04,
                      120 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Spndly',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Transactions',
                            onPressed: () => context.read<NavigationNotifier>().setIndex(2),
                            icon: Icon(Icons.search, size: 16, color: cs.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PERFORMANCE DASHBOARD',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 1,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analytics &\nFinancial Pulse',
                        style: TextStyle(
                          height: 1.05,
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _pill(cs, 'Week', _period == _ReportPeriod.week, () => setState(() => _period = _ReportPeriod.week)),
                            _pill(cs, 'Month', _period == _ReportPeriod.month, () => setState(() => _period = _ReportPeriod.month)),
                            _pill(cs, 'Year', _period == _ReportPeriod.year, () => setState(() => _period = _ReportPeriod.year)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _velocityCard(context, cs, sym, totalOutflow),
                      const SizedBox(height: 12),
                      _insightCard(
                        cs,
                        icon: diff >= 0 ? Icons.volunteer_activism_outlined : Icons.trending_up,
                        title: savingTitle,
                        text: savingText,
                        bg: savingBgColor,
                        fg: savingColor,
                      ),
                      const SizedBox(height: 8),
                      _insightCard(
                        cs,
                        icon: Icons.category_outlined,
                        title: catTitle,
                        text: catText,
                        bg: cs.surfaceContainerHigh,
                        fg: cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      _allocationCard(cs, catSums, topCatAmt > 0),
                      const SizedBox(height: 10),
                      _merchantCard(cs, sym),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [cs.primary, cs.primaryContainer]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: editorialAmbientShadow(context),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Spndly’s Advice",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              advice,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed: () =>
                                  context.read<NavigationNotifier>().setIndex(3),
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.surfaceContainerHighest,
                                foregroundColor: cs.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              ),
                              child: const Text('View Budgets'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _pill(ColorScheme cs, String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: () {
          onTap();
          _load();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _velocityCard(BuildContext context, ColorScheme cs, String sym, double outflow) {
    List<double> values = [];
    final now = DateTime.now();
    
    if (_period == _ReportPeriod.week) {
        values = List.filled(7, 0.0);
        for(var t in _periodTransactions.where((e)=>e.isExpense)){
          values[t.dateTime.weekday - 1] += t.amount;
        }
    } else if (_period == _ReportPeriod.month) {
        values = List.filled(5, 0.0);
        for(var t in _periodTransactions.where((e)=>e.isExpense)){
          int w = (t.dateTime.day - 1) ~/ 7;
          if (w > 4) w = 4;
          values[w] += t.amount;
        }
    } else {
        values = List.filled(12, 0.0);
        for(var t in _periodTransactions.where((e)=>e.isExpense)){
          values[t.dateTime.month - 1] += t.amount;
        }
    }
    
    final max = values.fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = max <= 0 ? 1.0 : max;
    
    final bars = List.generate(values.length, (i) {
        bool isHighlight = false;
        if (_period == _ReportPeriod.week) {
          isHighlight = i == now.weekday - 1;
        } else if (_period == _ReportPeriod.month) {
          isHighlight = i == (now.day - 1) ~/ 7;
        } else {
          isHighlight = i == now.month - 1;
        }
        
        final h = (values[i] / safeMax) * 100;
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: h,
              width: _period == _ReportPeriod.month ? 24 : 14,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              color: isHighlight ? cs.primary : cs.surfaceContainerHigh,
            )
          ],
        );
    });

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: editorialAmbientShadow(context),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending Velocity',
                      style: TextStyle(fontSize: 18, color: cs.onSurface),
                    ),
                    Text(
                      'Net outflow tracking',
                      style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                _money(sym, outflow),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        String txt = '';
                        bool isHighlight = false;
                        if (_period == _ReportPeriod.week) {
                            const d = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                            if (i >= 0 && i < d.length) txt = d[i];
                            isHighlight = i == now.weekday - 1;
                        } else if (_period == _ReportPeriod.month) {
                            txt = 'W${i+1}';
                            isHighlight = i == (now.day - 1) ~/ 7;
                        } else {
                            const mths = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                            if (i >= 0 && i < mths.length) txt = mths[i];
                            isHighlight = i == now.month - 1;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            txt,
                            style: TextStyle(
                              fontSize: _period == _ReportPeriod.week ? 8 : 10,
                              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                              color: isHighlight ? cs.primary : cs.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: bars,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 14, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _allocationCard(ColorScheme cs, Map<String, double> catSums, bool hasData) {
    final total = catSums.values.fold<double>(0, (a, b) => a + b);
    final sorted = catSums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final list = sorted.take(3).toList();
    final colors = [cs.primary, cs.secondary, cs.tertiary];
    
    final sections = sorted.asMap().entries.map((e) {
      final amt = e.value.value;
      final pct = total > 0 ? (amt / total * 100).toStringAsFixed(0) : '0';
      final showTitle = (amt / total) > 0.05;
      return PieChartSectionData(
        value: total <= 0 ? 1 : amt,
        color: colors[e.key % colors.length],
        title: showTitle ? '$pct%' : '',
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        radius: 30, // Increased radius for better visibility
      );
    }).toList();

    if (sections.isEmpty) {
       sections.add(PieChartSectionData(value: 1, color: cs.surfaceContainerHighest, title: '', radius: 30));
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capital Allocation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.25,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 16, // Adjusted center space
                    sectionsSpace: 2,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hasData ? Column(
                  children: List.generate(list.length, (i) {
                    final m = list[i];
                    final catName = _categories.where((c) => c.id == m.key).toList();
                    final name = catName.isNotEmpty ? catName.first.name : 'Unknown';
                    final pct = total > 0 ? ((m.value / total) * 100).round() : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(fontSize: 10, color: cs.onSurface),
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ) : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('No allocations recorded', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _merchantCard(ColorScheme cs, String sym) {
    final expenses = _periodTransactions.where((t) => t.isExpense).toList()..sort((a, b) => b.amount.compareTo(a.amount));
    final top = expenses.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Merchant Outflow',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'For this ${_periodName(_period)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.read<NavigationNotifier>().setIndex(2),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...top.map((t) {
            final c = _categories.where((x) => x.id == t.categoryId).toList();
            final name = t.notes?.trim().isNotEmpty == true ? t.notes!.trim() : (c.isNotEmpty ? c.first.name : 'Merchant');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.store_mall_directory_outlined,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          t.accountType,
                          style: TextStyle(
                            fontSize: 9,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _money(sym, t.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No merchant data for this period',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  String _money(String sym, double amount) {
    if (amount < 0) {
      return '0';
    }
    final fixed = amount.toStringAsFixed(0);
    final comma = fixed.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$sym$comma';
  }
}
