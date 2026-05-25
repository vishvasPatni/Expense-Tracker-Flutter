import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_strings.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/settings_data_notifier.dart';
import '../../services/budget_service.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _svc = BudgetService();
  final _catSvc = CategoryService();
  final _txSvc = TransactionService();

  final DateTime _month = DateTime.now();
  BudgetModel? _budget;
  double _spent = 0;
  List<CategoryModel> _categories = [];
  Map<String, double> _categorySpending = {}; // Track spending per category
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final monthStart = startOfMonth(_month);
      final monthEnd = endOfMonth(_month);
      
      final b = await _svc.fetchOverallForMonth(_month);
      final s = await _svc.monthlyExpenseTotal(_month);
      final categories = await _catSvc.fetchCategories();
      final categoryTotals = await _txSvc.categoryExpenseTotals(
        start: monthStart,
        end: monthEnd,
      );
      
      // Build a map of category_id -> spending amount
      final spendingMap = <String, double>{};
      for (final item in categoryTotals) {
        final catId = item['category_id']?.toString() ?? '';
        final amount = TransactionService.parseNum(item['total_amount']);
        if (catId.isNotEmpty) {
          spendingMap[catId] = amount;
        }
      }
      
      if (!mounted) return;
      setState(() {
        _budget = b;
        _spent = s;
        _categories = categories;
        _categorySpending = spendingMap;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'load';
        });
      }
    }
  }

  Future<void> _editSheet() async {
    final online = context.read<ConnectivityNotifier>().isOnline;
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.offlineNoWrite)),
      );
      return;
    }
    final ctrl = TextEditingController(text: _budget?.amount.toStringAsFixed(2) ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Monthly budget', style: Theme.of(ctx).textTheme.titleLarge),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final v = double.tryParse(ctrl.text.replaceAll(',', ''));
                if (v == null || v < 0) return;
                try {
                  await _svc.upsertOverall(month: _month, amount: v);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text(AppStrings.genericError)),
                    );
                  }
                }
              },
              child: const Text('Set budget'),
            ),
          ],
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sym = context.watch<SettingsDataNotifier>().currencySymbol;
    final amount = _budget?.amount ?? 0.0;
    final spent = _spent.clamp(0.0, amount <= 0 ? 1.0 : amount);
    final remaining = (amount - spent).clamp(0.0, amount);
    final pct = amount <= 0 ? 0.0 : (spent / amount).clamp(0.0, 1.0);
    final email = Supabase.instance.client.auth.currentUser?.email ?? '?';
    final initial = email.isNotEmpty ? email.substring(0, 1).toUpperCase() : '?';

    final hasBudget = _budget != null;

    return Scaffold(
      body: _loading
          ? const BudgetScreenSkeleton()
          : _error != null
              ? ListView(
                  children: [
                    EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: 'Could not load budget',
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
                      MediaQuery.of(context).size.width * 0.06,
                      MediaQuery.of(context).size.height * 0.10,
                      MediaQuery.of(context).size.width * 0.06,
                      MediaQuery.of(context).size.height * 0.15,
                    ),
                    children: [
                      _topBar(context, initial),
                      const SizedBox(height: 20),
                      _heroBudgetCard(context, sym, remaining, spent, amount),
                      const SizedBox(height: 18),
                      // Only show alert if budget is actually set and usage is high
                      if (hasBudget && pct > 0.8) _alertCard(context, pct),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Categories',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: MediaQuery.sizeOf(context).width < 360 ? 28 : 40,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          TextButton(onPressed: _editSheet, child: const Text('Set budget')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._categoryCards(context, sym),
                      if (_categories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: EmptyStateWidget(
                            icon: Icons.category_outlined,
                            title: 'No category budgets',
                            subtitle: 'Add categories to track specific spending.',
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _topBar(BuildContext context, String initial) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
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
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ),
        IconButton(
          onPressed: _editSheet,
          icon: Icon(Icons.search, color: cs.primary),
        ),
      ],
    );
  }

  Widget _heroBudgetCard(
    BuildContext context,
    String sym,
    double remaining,
    double spent,
    double total,
  ) {
    final cs = Theme.of(context).colorScheme;
    final pct = total <= 0 ? 0.0 : (spent / total).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primaryContainer],
        ),
        boxShadow: editorialAmbientShadow(context),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "THIS MONTH'S BUDGET",
            style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.4),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              return SizedBox(
                width: c.maxWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _money(sym, remaining, noDecimals: true),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('remaining', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 24)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent: ${_money(sym, spent, noDecimals: true)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total: ${_money(sym, total, noDecimals: true)}',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: pct,
              backgroundColor: const Color(0x33FFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(pct * 100).round()}% of your monthly limit reached',
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(BuildContext context, double pct) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? cs.errorContainer : cs.errorContainer.withValues(alpha: 0.15);
    final titleC = dark ? cs.onErrorContainer : cs.error;
    final subC = cs.onSurfaceVariant.withValues(alpha: 0.85);
    final iconBg = dark ? cs.error.withValues(alpha: 0.25) : cs.error;
    final iconFg = dark ? cs.error : Colors.white;
    
    final isOver = pct >= 1.0;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isOver ? Icons.warning_amber_rounded : Icons.lightbulb, color: iconFg),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOver ? 'Budget Exceeded!' : 'Approaching limit',
                  style: TextStyle(
                    color: titleC,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOver 
                    ? 'You have spent more than your monthly allocation.'
                    : 'You have utilized over 80% of your primary budget.',
                  style: TextStyle(color: subC, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _categoryCards(BuildContext context, String sym) {
    final cs = Theme.of(context).colorScheme;
    return _categories.map((c) {
      // Get the actual spending for this category
      final spent = _categorySpending[c.id] ?? 0.0;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: editorialAmbientShadow(context),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Icon(appIconFromName(c.icon), color: cs.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'CATEGORY',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _money(sym, spent, noDecimals: true),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: spent > 0 ? cs.secondary : cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'spent',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _money(String sym, double amount, {bool noDecimals = false}) {
    final fixed = noDecimals ? amount.round().toString() : amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final comma = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    if (noDecimals) return '$sym$comma';
    return '$sym$comma.${parts[1]}';
  }
}
