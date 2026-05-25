import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_strings.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/settings_data_notifier.dart';
import '../../providers/transaction_refresh.dart';
import '../../services/category_service.dart';
import '../../services/supabase_service.dart';
import '../../services/transaction_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/safe_parse.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton.dart';

enum _TxKind { expense, income, transfer }

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.existing});

  final TransactionModel? existing;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  final _txSvc = TransactionService();
  final _catSvc = CategoryService();

  bool _loading = true;
  List<CategoryModel> _categories = [];
  String? _categoryId;
  _TxKind _kind = _TxKind.expense;
  DateTime _when = DateTime.now();
  String _account = 'cash';
  bool _saving = false;
  bool _dirty = false;
  String? _loadError;
  bool _recurring = false;
  RealtimeChannel? _categoriesChannel;
  Timer? _categoriesDebounce;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _load();
    _amountCtrl.addListener(_markDirty);
    _notesCtrl.addListener(_markDirty);
    _tagsCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _categoriesDebounce?.cancel();
    _teardownCategoryChannel();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  void _teardownCategoryChannel() {
    final ch = _categoriesChannel;
    if (ch != null) {
      Supabase.instance.client.removeChannel(ch);
      _categoriesChannel = null;
    }
  }

  void _setupCategoryRealtime() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _teardownCategoryChannel();
    _categoriesChannel = Supabase.instance.client.channel('add-tx-categories-$uid')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'categories',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (_) {
          _categoriesDebounce?.cancel();
          _categoriesDebounce = Timer(const Duration(milliseconds: 250), () {
            if (mounted) _reloadCategories();
          });
        },
      )
      ..subscribe();
  }

  Future<void> _reloadCategories() async {
    try {
      final list = await _catSvc.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        if (_categoryId != null && !list.any((c) => c.id == _categoryId)) {
          _categoryId = list.isNotEmpty ? list.first.id : null;
        }
      });
    } catch (_) {
      // Keep existing list on transient errors.
    }
  }

  String _typeForSave() {
    return switch (_kind) {
      _TxKind.expense => 'expense',
      _TxKind.income => 'income',
      _TxKind.transfer => 'transfer',
    };
  }

  Future<void> _load() async {
    try {
      final list = await _catSvc.fetchCategories();
      if (!mounted) return;
      final e = widget.existing;
      if (e != null) {
        if (e.isTransfer) {
          _kind = _TxKind.transfer;
        } else {
          _kind = e.isIncome ? _TxKind.income : _TxKind.expense;
        }
        _amountCtrl.text = e.amount.toStringAsFixed(2);
        _categoryId = e.categoryId;
        _when = e.dateTime;
        _notesCtrl.text = e.notes ?? '';
        _tagsCtrl.text = e.tags.join(', ');
        _account = e.accountType;
        _recurring = e.isRecurring;
        _dirty = false;
      } else {
        _categoryId = list.isNotEmpty ? list.first.id : null;
      }
      setState(() {
        _categories = list;
        _loading = false;
        _loadError = null;
      });
      _setupCategoryRealtime();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'load';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        _when = DateTime(d.year, d.month, d.day, _when.hour, _when.minute);
        _dirty = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (t != null) {
      setState(() {
        _when = DateTime(
          _when.year,
          _when.month,
          _when.day,
          t.hour,
          t.minute,
        );
        _dirty = true;
      });
    }
  }

  List<String> _parseTags() {
    return _tagsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    final online = context.read<ConnectivityNotifier>().isOnline;
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.offlineNoWrite)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    
    // Category is required for Expense and Transfer, but optional for Income
    if (_kind != _TxKind.income && _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')),
      );
      return;
    }
    
    // For Income transactions, create or get a default "Income" category if none selected
    if (_kind == _TxKind.income && _categoryId == null) {
      try {
        // Try to find existing Income category
        final incomeCategories = _categories.where((c) => c.categoryType == 'income').toList();
        if (incomeCategories.isNotEmpty) {
          _categoryId = incomeCategories.first.id;
        } else {
          // Create a default Income category
          final uid = Supabase.instance.client.auth.currentUser?.id;
          if (uid != null) {
            final inserted = await SupabaseService.client
                .from('categories')
                .insert({
                  'user_id': uid,
                  'name': 'Income',
                  'icon': 'account_balance_wallet',
                  'color': '#10B981',
                  'is_default': true,
                  'category_type': 'income',
                })
                .select()
                .single();
            
            final created = CategoryModel.fromJson(Map<String, dynamic>.from(inserted));
            _categoryId = created.id;
            _categories = [..._categories, created];
          }
        }
      } catch (_) {
        // If category creation fails, continue without category
      }
    }
    
    final amount = parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _saving = false);
      return;
    }

    try {
      final tags = _parseTags();
      if (widget.existing != null) {
        final e = widget.existing!;
        final updated = TransactionModel(
          id: e.id,
          userId: e.userId,
          type: _typeForSave(),
          amount: amount,
          categoryId: _categoryId!,
          subcategoryId: e.subcategoryId,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          dateTime: _when,
          tags: tags,
          accountType: _account,
          imageUrl: e.imageUrl,
          latitude: e.latitude,
          longitude: e.longitude,
          isRecurring: _recurring,
          recurrenceInterval: e.recurrenceInterval,
          createdAt: e.createdAt,
          updatedAt: e.updatedAt,
        );
        await _txSvc.update(updated);
      } else {
        final now = DateTime.now();
        await _txSvc.insert(
          TransactionModel(
            id: '',
            userId: uid,
            type: _typeForSave(),
            amount: amount,
            categoryId: _categoryId!,
            subcategoryId: null,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            dateTime: _when,
            tags: tags,
            accountType: _account,
            imageUrl: null,
            latitude: null,
            longitude: null,
          isRecurring: _recurring,
            recurrenceInterval: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      if (mounted) {
        context.read<TransactionRefresh>().bump();
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveTransactionError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final online = context.read<ConnectivityNotifier>().isOnline;
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.offlineNoWrite)),
      );
      return;
    }
    final ok = await showDialog<bool>(
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
    if (!ok || widget.existing == null) return;
    try {
      await _txSvc.delete(widget.existing!.id);
      if (mounted) {
        context.read<TransactionRefresh>().bump();
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.deleteTransactionError)),
        );
      }
    }
  }

  Future<void> _close() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard changes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = context.watch<SettingsDataNotifier>().currencySymbol;
    final online = context.watch<ConnectivityNotifier>().isOnline;
    final dateLabel =
        '${formatDayHeader(_when)}, ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_when))}';

    return Scaffold(
      backgroundColor: cs.surface,
      body: _loading
          ? const AddTransactionScreenSkeleton()
          : _loadError != null
              ? ListView(
                  children: [
                    EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: 'Could not load transaction form',
                      subtitle: 'Please try again.',
                      actionLabel: 'Retry',
                      onAction: () {
                        setState(() => _loading = true);
                        _load();
                      },
                    ),
                  ],
                )
          : Form(
              key: _formKey,
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(24, 88, 24, 132),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _close,
                            icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                          ),
                          Expanded(
                            child: Text(
                              'Spndly',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _typeSegment(context, online),
                      const SizedBox(height: 36),
                      Text(
                        'TRANSACTION AMOUNT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currency,
                              style: TextStyle(
                                color: switch (_kind) {
                                  _TxKind.income => cs.primary,
                                  _TxKind.transfer => cs.tertiary,
                                  _TxKind.expense => cs.secondary,
                                },
                                fontWeight: FontWeight.w700,
                                fontSize: 36,
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 170,
                              child: TextFormField(
                                controller: _amountCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                  height: 1,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0.00',
                                ),
                                validator: validateRequiredAmount,
                                enabled: online,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Only show Category section for Expense and Transfer, not for Income
                      if (_kind != _TxKind.income) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Category',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: online ? () => _showAddCategory(context) : null,
                              child: Text('Add category', style: TextStyle(color: cs.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _categoryGrid(online),
                        const SizedBox(height: 22),
                      ],
                      _simpleFieldCard(
                        label: 'DATE & TIME',
                        icon: Icons.calendar_today_outlined,
                        value: dateLabel,
                        onTap: online
                            ? () async {
                                await _pickDate();
                                if (!mounted) return;
                                await _pickTime();
                              }
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _accountField(context, online),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          maxLength: 200,
                          enabled: online,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'NOTE',
                            hintText: _kind == _TxKind.transfer
                                ? 'e.g. Savings → checking, wallet top-up…'
                                : 'Add a description of this expense…',
                            labelStyle: const TextStyle(fontSize: 10, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _tagsSection(context, online),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.event_repeat, color: cs.onSurfaceVariant),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recurring Transaction',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Automate this entry',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _recurring,
                              onChanged: online
                                  ? (v) => setState(() {
                                        _recurring = v;
                                        _dirty = true;
                                      })
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      if (_isEdit)
                        TextButton(
                          onPressed: online ? _delete : null,
                          child: const Text('Delete transaction'),
                        ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: cs.surface.withValues(alpha: 0.94),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_saving || !online) ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Save Transaction',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _typeSegment(BuildContext context, bool online) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _segBtn(
              'Expense',
              selected: _kind == _TxKind.expense,
              selectedColor: isDark ? AppColors.expenseDark : AppColors.expenseLight,
              textColor: isDark ? const Color(0xFF63000A) : Colors.white,
              onTap: online
                  ? () => setState(() {
                        _kind = _TxKind.expense;
                        _dirty = true;
                        // Reset category to first expense category
                        final expenseCategories = _categories.where((c) => c.categoryType == 'expense').toList();
                        _categoryId = expenseCategories.isNotEmpty ? expenseCategories.first.id : null;
                      })
                  : null,
            ),
          ),
          Expanded(
            child: _segBtn(
              'Income',
              selected: _kind == _TxKind.income,
              selectedColor: isDark ? AppColors.incomeDark : AppColors.incomeLight,
              textColor: isDark ? const Color(0xFF005049) : Colors.white,
              onTap: online
                  ? () => setState(() {
                        _kind = _TxKind.income;
                        _dirty = true;
                        // Reset category to first income category
                        final incomeCategories = _categories.where((c) => c.categoryType == 'income').toList();
                        _categoryId = incomeCategories.isNotEmpty ? incomeCategories.first.id : null;
                      })
                  : null,
            ),
          ),
          Expanded(
            child: _segBtn(
              'Transfer',
              selected: _kind == _TxKind.transfer,
              selectedColor: isDark ? AppColors.transferDark : AppColors.transferLight,
              textColor: isDark ? const Color(0xFF1A237E) : Colors.white,
              onTap: online
                  ? () => setState(() {
                        _kind = _TxKind.transfer;
                        _dirty = true;
                        // Reset category to first transfer category
                        final transferCategories = _categories.where((c) => c.categoryType == 'transfer').toList();
                        _categoryId = transferCategories.isNotEmpty ? transferCategories.first.id : null;
                      })
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segBtn(
    String label, {
    required bool selected,
    required Color selectedColor,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? textColor : const Color(0xFF3D4947),
          ),
        ),
      ),
    );
  }

  Widget _categoryGrid(bool online) {
    // Filter categories based on transaction type
    final filteredCategories = _categories.where((c) {
      switch (_kind) {
        case _TxKind.expense:
          return c.categoryType == 'expense';
        case _TxKind.income:
          return c.categoryType == 'income';
        case _TxKind.transfer:
          return c.categoryType == 'transfer';
      }
    }).toList();
    
    if (filteredCategories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No categories yet. Tap Add category.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6D7A77)),
        ),
      );
    }
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filteredCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cs = Theme.of(context).colorScheme;
          final c = filteredCategories[i];
          final selected = _categoryId == c.id;
          final icon = appIconFromName(c.icon);
          return GestureDetector(
            onTap: online
                ? () => setState(() {
                      _categoryId = c.id;
                      _dirty = true;
                    })
                : null,
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: selected ? cs.primary : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? cs.onPrimary : parseColorOrFallback(c.color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? const Color(0xFF191C1D) : const Color(0xFF3D4947),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _simpleFieldCard({
    required String label,
    required IconData icon,
    required String value,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, letterSpacing: 1, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF006A62)),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF191C1D)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountField(BuildContext context, bool online) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: online ? _pickAccount : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ACCOUNT',
              style: TextStyle(fontSize: 10, letterSpacing: 1, color: Color(0xFF6D7A77)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF006A62)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _accountLabel(_account),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF191C1D)),
                  ),
                ),
                const Icon(Icons.expand_more, color: Color(0xFF6D7A77)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagsSection(BuildContext context, bool online) {
    final tags = _parseTags();
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TAGS',
          style: TextStyle(fontSize: 10, letterSpacing: 1, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ...tags.map(
              (t) => Chip(
                label: Text(t),
                backgroundColor: isDark ? cs.secondaryContainer : const Color(0xFF84F5E8),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? cs.onSecondaryContainer : const Color(0xFF00201D),
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            ActionChip(
              onPressed: online ? _editTagsDialog : null,
              label: const Text('+ Add Tag'),
              labelStyle: TextStyle(
                fontSize: 12,
                color: isDark ? cs.onSurface : cs.onSurfaceVariant,
              ),
              backgroundColor: isDark ? cs.surfaceContainerHigh : const Color(0xFFE7E8E9),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAccount() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Cash'),
              onTap: () => Navigator.pop(ctx, 'cash'),
            ),
            ListTile(
              title: const Text('Bank'),
              onTap: () => Navigator.pop(ctx, 'bank'),
            ),
            ListTile(
              title: const Text('UPI'),
              onTap: () => Navigator.pop(ctx, 'upi'),
            ),
            ListTile(
              title: const Text('Wallet'),
              onTap: () => Navigator.pop(ctx, 'wallet'),
            ),
          ],
        ),
      ),
    );
    if (value != null) {
      setState(() {
        _account = value;
        _dirty = true;
      });
    }
  }

  String _accountLabel(String value) {
    switch (value) {
      case 'cash':
        return 'Main Wallet';
      case 'bank':
        return 'Bank Account';
      case 'upi':
        return 'UPI';
      case 'wallet':
        return 'Wallet';
      default:
        return value.toUpperCase();
    }
  }

  Future<void> _editTagsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit tags'),
        content: TextField(
          controller: _tagsCtrl,
          decoration: const InputDecoration(hintText: 'office, personal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
    if (mounted) setState(() => _dirty = true);
  }

  Future<void> _showAddCategory(BuildContext innerContext) async {
    final nameCtrl = TextEditingController();
    String iconKey = kCategoryIconKeys.first;
    Color color = AppColors.categoryPalette.first;

    // Determine category type based on current transaction type
    final categoryType = switch (_kind) {
      _TxKind.expense => 'expense',
      _TxKind.income => 'income',
      _TxKind.transfer => 'transfer',
    };

    await showModalBottomSheet<void>(
      context: innerContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'New category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 1,
                        ),
                        itemCount: kCategoryIconKeys.length,
                        itemBuilder: (_, i) {
                          final k = kCategoryIconKeys[i];
                          final on = iconKey == k;
                          return InkWell(
                            onTap: () => setModal(() => iconKey = k),
                            child: Icon(
                              appIconFromName(k),
                              color: on
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: AppColors.categoryPalette.map((c) {
                        final on = color == c;
                        return GestureDetector(
                          onTap: () => setModal(() => color = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: on
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        final n = nameCtrl.text.trim();
                        if (n.isEmpty) return;
                        try {
                          // Create category with the appropriate type
                          final uid = SupabaseService.client.auth.currentUser?.id;
                          if (uid == null) throw const AuthException('Not signed in');
                          
                          final inserted = await SupabaseService.client
                              .from('categories')
                              .insert({
                                'user_id': uid,
                                'name': n,
                                'icon': iconKey,
                                'color': AppColors.colorToHex(color),
                                'is_default': false,
                                'category_type': categoryType,
                              })
                              .select()
                              .single();
                          
                          final created = CategoryModel.fromJson(Map<String, dynamic>.from(inserted));
                          
                          if (innerContext.mounted) {
                            setState(() {
                              _categories = [..._categories, created];
                              _categoryId = created.id;
                              _dirty = true;
                            });
                            Navigator.pop(ctx);
                          }
                        } catch (_) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.genericError),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
