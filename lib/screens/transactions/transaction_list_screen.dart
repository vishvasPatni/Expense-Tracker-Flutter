import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_strings.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/settings_data_notifier.dart';
import '../../providers/transaction_refresh.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/safe_parse.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton.dart';
import 'add_transaction_screen.dart';
import '../splits/split_groups_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _tx = TransactionService();
  final _cat = CategoryService();
  final _search = TextEditingController();
  final _filterTagCtrl = TextEditingController();

  List<TransactionModel> _items = [];
  List<CategoryModel> _categories = [];
  bool _loading = true;
  String? _typeFilter;
  String? _accountFilter;
  String? _categoryFilter;
  DateTime? _from;
  DateTime? _to;
  String? _tagFilter;
  TransactionSort _sort = TransactionSort.latest;
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  TransactionRefresh? _refreshBus;
  bool _refreshListening = false;
  RealtimeChannel? _txChannel;
  Timer? _syncDebounce;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _bootstrap();
    });
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
    _syncDebounce?.cancel();
    final channel = _txChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    if (_refreshListening) {
      _refreshBus?.removeListener(_onGlobalRefresh);
    }
    _search.dispose();
    _filterTagCtrl.dispose();
    super.dispose();
  }

  void _onGlobalRefresh() {
    if (mounted) _refresh(reset: true);
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadCategories(), _refresh(reset: true)]);
  }

  void _setupRealtime() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _txChannel = Supabase.instance.client.channel('transactions-live-$uid')
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
          _syncDebounce?.cancel();
          _syncDebounce = Timer(const Duration(milliseconds: 300), () {
            if (mounted) _refresh(reset: true);
          });
        },
      )
      ..subscribe();
  }

  Future<void> _loadCategories() async {
    final c = await _cat.fetchCategories();
    if (mounted) setState(() => _categories = c);
  }

  Future<void> _refresh({bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      setState(() {
        _offset = 0;
        _hasMore = true;
        _loading = true;
      });
    }
    try {
      final rows = reset
          ? await _tx.fetchAll(
              type: _typeFilter,
              categoryId: _categoryFilter,
              dateFrom: _from,
              dateTo: _to,
              notesSearch: _search.text.trim().isEmpty ? null : _search.text.trim(),
              tag: _tagFilter,
              sort: _sort,
            )
          : await _tx.fetchPage(
              offset: _offset,
              limit: TransactionService.pageSize,
              type: _typeFilter,
              categoryId: _categoryFilter,
              dateFrom: _from,
              dateTo: _to,
              notesSearch: _search.text.trim().isEmpty ? null : _search.text.trim(),
              tag: _tagFilter,
              sort: _sort,
            );
      if (!mounted) return;
      final filteredByAccount = _accountFilter == null
          ? rows
          : rows.where((t) => t.accountType.toLowerCase() == _accountFilter).toList();
      setState(() {
        if (reset) {
          _items = filteredByAccount;
        } else {
          _items = [..._items, ...filteredByAccount];
        }
        _hasMore = !reset && rows.length >= TransactionService.pageSize;
        _offset = _items.length;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.genericError)),
      );
    }
  }

  CategoryModel? _catFor(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityNotifier>().isOnline;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '?';
    final initial = email.isNotEmpty ? email.substring(0, 1).toUpperCase() : '?';
    final cs = Theme.of(context).colorScheme;
    final flatItems = _getFlatItems();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(reset: true),
        child: _loading
            ? const TransactionScreenSkeleton()
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width * 0.06,
                  MediaQuery.of(context).size.height * 0.10,
                  MediaQuery.of(context).size.width * 0.06,
                  MediaQuery.of(context).size.height * 0.15,
                ),
                itemCount: flatItems.length + 4 + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) return _topBar(context, initial);
                  if (index == 1) return const SizedBox(height: 24);
                  if (index == 2) return _chipsRow(context);
                  if (index == 3) return const SizedBox(height: 12);
                  
                  final listIndex = index - 4;
                  if (listIndex < flatItems.length) {
                    final item = flatItems[listIndex];
                    if (item is String) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 14),
                        child: Text(
                          item.toUpperCase(),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      );
                    } else if (item is TransactionModel) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _transactionTile(item),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  if (_hasMore && listIndex == flatItems.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: _loadingMore
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: () async {
                                  setState(() => _loadingMore = true);
                                  await _refresh(reset: false);
                                },
                                child: const Text('Load more'),
                              ),
                      ),
                    );
                  }
                  
                  if (_items.isEmpty && index == 4) {
                    return EmptyStateWidget(
                      icon: Icons.search_off,
                      title: 'No transactions match',
                      subtitle: 'Try adjusting filters or add a new one.',
                      actionLabel: online ? 'Add' : null,
                      onAction: online ? _openAdd : null,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
      ),
    );
  }

  Widget _topBar(BuildContext context, String initial) {
    final cs = Theme.of(context).colorScheme;
    final hasSearch = _search.text.trim().isNotEmpty;
    return Column(
      children: [
        Row(
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
                'Transactions',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: cs.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _openSearchDialog(),
              icon: Icon(
                hasSearch ? Icons.search : Icons.search,
                color: hasSearch ? cs.secondary : cs.primary,
              ),
            ),
            IconButton(
              onPressed: _showFilterSheet,
              icon: Icon(Icons.tune, color: cs.primary),
            ),
            IconButton(
              tooltip: 'Split groups',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SplitGroupsScreen()),
              ),
              icon: Icon(Icons.groups_outlined, color: cs.primary),
            ),
          ],
        ),
        if (hasSearch) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: cs.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Searching: "${_search.text.trim()}"',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _search.clear());
                    _refresh(reset: true);
                  },
                  child: Icon(Icons.close, size: 16, color: cs.onSecondaryContainer),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _chipsRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget chip(String text, bool selected, VoidCallback onTap) {
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', _typeFilter == null && _accountFilter == null, () {
            setState(() {
              _typeFilter = null;
              _accountFilter = null;
            });
            _refresh(reset: true);
          }),
          const SizedBox(width: 12),
          chip('Income', _typeFilter == 'income', () {
            setState(() {
              _typeFilter = 'income';
              _accountFilter = null;
            });
            _refresh(reset: true);
          }),
          const SizedBox(width: 12),
          chip('Expenses', _typeFilter == 'expense', () {
            setState(() {
              _typeFilter = 'expense';
              _accountFilter = null;
            });
            _refresh(reset: true);
          }),
          const SizedBox(width: 12),
          chip('Cash', _accountFilter == 'cash', () {
            setState(() {
              _typeFilter = null;
              _accountFilter = 'cash';
            });
            _refresh(reset: true);
          }),
          const SizedBox(width: 12),
          chip('UPI', _accountFilter == 'upi', () {
            setState(() {
              _typeFilter = null;
              _accountFilter = 'upi';
            });
            _refresh(reset: true);
          }),
        ],
      ),
    );
  }

  List<Object> _getFlatItems() {
    final groups = <DateTime, List<TransactionModel>>{};
    for (final t in _items) {
      final d = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
      groups.putIfAbsent(d, () => []).add(t);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    final out = <Object>[];
    for (final day in keys) {
      out.add(formatDayHeader(day));
      for (final t in groups[day]!) {
        out.add(t);
      }
    }
    return out;
  }

  Widget _transactionTile(TransactionModel t) {
    final cs = Theme.of(context).colorScheme;
    final cat = _catFor(t.categoryId);
    final icon = appIconFromName(cat?.icon ?? 'more_horiz');
    final iconColor = parseColorOrFallback(cat?.color, fallback: cs.primary);
    final amountColor = t.isIncome
        ? cs.primary
        : t.isTransfer
            ? cs.tertiary
            : cs.secondary;
    final sign = t.isIncome ? '+' : (t.isTransfer ? '↔' : '-');
    final rawTag = t.tags.isNotEmpty ? '#${t.tags.first}' : '#${(cat?.name ?? "misc").toLowerCase()}';
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(t.dateTime),
      alwaysUse24HourFormat: false,
    );

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final del = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete transaction?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
        return del;
      },
      onDismissed: (_) async {
        try {
          await _tx.delete(t.id);
          if (!mounted) return;
          setState(() => _items.removeWhere((x) => x.id == t.id));
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.deleteTransactionError)),
          );
          _refresh(reset: true);
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: cs.onSecondary),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => AddTransactionScreen(existing: t)))
            .then((_) {
          if (mounted) _refresh(reset: true);
        }),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.notes?.trim().isNotEmpty == true ? t.notes!.trim() : (cat?.name ?? 'Transaction'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    rawTag.toLowerCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              t.isTransfer
                                  ? '↔ ${_formatAmount(t.amount, context.watch<SettingsDataNotifier>().currencySymbol)}'
                                  : '$sign ${_formatAmount(t.amount, context.watch<SettingsDataNotifier>().currencySymbol)}',
                              maxLines: 1,
                              style: TextStyle(
                                color: amountColor,
                                fontSize: 32,
                                height: 1.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.accountType.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: -0.3,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double value, String symbol) {
    final abs = value.abs();
    final fixed = abs.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0];
    final dec = parts[1];
    final withCommas = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$symbol$withCommas.$dec';
  }

  Future<void> _openSearchDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search transactions'),
        content: TextField(
          controller: _search,
          decoration: const InputDecoration(hintText: 'Search notes...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _search.text.trim()),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    if (result != null) _refresh(reset: true);
  }

  void _openAdd() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AddTransactionScreen()))
        .then((_) {
      if (mounted) _refresh(reset: true);
    });
  }

  void _showFilterSheet() {
    TransactionSort localSort = _sort;
    String? localType = _typeFilter;
    String? localCat = _categoryFilter;
    DateTime? localFrom = _from;
    DateTime? localTo = _to;
    _filterTagCtrl.text = _tagFilter ?? '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setS) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (_, scroll) {
                  return ListView(
                    controller: scroll,
                    children: [
                      Text('Filter & sort', style: Theme.of(context).textTheme.titleLarge),
                      const Text('Sort by'),
                      RadioListTile<TransactionSort>(
                        title: const Text('Latest'),
                        value: TransactionSort.latest,
                        groupValue: localSort,
                        onChanged: (v) => setS(() => localSort = v!),
                      ),
                      RadioListTile<TransactionSort>(
                        title: const Text('Highest amount'),
                        value: TransactionSort.highest,
                        groupValue: localSort,
                        onChanged: (v) => setS(() => localSort = v!),
                      ),
                      RadioListTile<TransactionSort>(
                        title: const Text('Lowest amount'),
                        value: TransactionSort.lowest,
                        groupValue: localSort,
                        onChanged: (v) => setS(() => localSort = v!),
                      ),
                      const Divider(),
                      const Text('Type'),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: localType == null,
                            onSelected: (_) => setS(() => localType = null),
                          ),
                          FilterChip(
                            label: const Text('Income'),
                            selected: localType == 'income',
                            onSelected: (_) => setS(() => localType = 'income'),
                          ),
                          FilterChip(
                            label: const Text('Expense'),
                            selected: localType == 'expense',
                            onSelected: (_) => setS(() => localType = 'expense'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Category'),
                      DropdownButtonFormField<String?>(
                        value: localCat,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All categories')),
                          ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (v) => setS(() => localCat = v),
                      ),
                      ListTile(
                        title: const Text('Start date'),
                        subtitle: Text(
                          localFrom == null
                              ? 'Any'
                              : MaterialLocalizations.of(context).formatMediumDate(localFrom!),
                        ),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: localFrom ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) setS(() => localFrom = d);
                        },
                      ),
                      ListTile(
                        title: const Text('End date'),
                        subtitle: Text(
                          localTo == null
                              ? 'Any'
                              : MaterialLocalizations.of(context).formatMediumDate(localTo!),
                        ),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: localTo ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) setS(() => localTo = d);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Tag contains'),
                        controller: _filterTagCtrl,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setS(() {
                                  localSort = TransactionSort.latest;
                                  localType = null;
                                  localCat = null;
                                  localFrom = null;
                                  localTo = null;
                                  _filterTagCtrl.clear();
                                });
                              },
                              child: const Text('Clear all'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _sort = localSort;
                                  _typeFilter = localType;
                                  _categoryFilter = localCat;
                                  _from = localFrom;
                                  _to = localTo == null
                                      ? null
                                      : DateTime(localTo!.year, localTo!.month, localTo!.day, 23, 59, 59);
                                  final t = _filterTagCtrl.text.trim();
                                  _tagFilter = t.isEmpty ? null : t;
                                });
                                Navigator.pop(ctx);
                                _refresh(reset: true);
                              },
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
