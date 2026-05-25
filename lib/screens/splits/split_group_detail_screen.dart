import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/split_group_model.dart';
import '../../models/split_member_model.dart';
import '../../providers/connectivity_provider.dart';
import '../../services/split_service.dart';
import '../../utils/safe_parse.dart';
import '../../widgets/empty_state_widget.dart';
import 'split_settle_up_screen.dart';
import 'split_expense_editor_screen.dart';

class SplitGroupDetailScreen extends StatefulWidget {
  const SplitGroupDetailScreen({super.key, required this.group});

  final SplitGroupModel group;

  @override
  State<SplitGroupDetailScreen> createState() => _SplitGroupDetailScreenState();
}

class _SplitGroupDetailScreenState extends State<SplitGroupDetailScreen> {
  final _svc = SplitService();
  bool _loading = true;
  String? _error;

  List<SplitMemberModel> _members = [];
  List<Map<String, dynamic>> _balances = [];
  List<dynamic> _expenses = [];
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _svc.listMembers(widget.group.id),
        _svc.getGroupBalances(widget.group.id),
        _svc.listExpenses(widget.group.id),
        _svc.listPayments(widget.group.id),
      ]);
      if (!mounted) return;
      setState(() {
        _members = results[0] as List<SplitMemberModel>;
        _balances = results[1] as List<Map<String, dynamic>>;
        _expenses = results[2] as List<dynamic>;
        _payments = results[3] as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'load';
        _loading = false;
      });
    }
  }

  Future<void> _addMember() async {
    final online = context.read<ConnectivityNotifier>().isOnline;
    if (!online) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Add member'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Name'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    try {
      await _svc.addMember(groupId: widget.group.id, displayName: name);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't add member.")),
      );
    }
  }

  Future<void> _newSplitExpense() async {
    final online = context.read<ConnectivityNotifier>().isOnline;
    if (!online) return;
    if (_members.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 members first.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SplitExpenseEditorScreen(group: widget.group, members: _members),
      ),
    );
    await _load();
  }

  Future<void> _settleUp() async {
    final online = context.read<ConnectivityNotifier>().isOnline;
    if (!online) return;
    if (_members.length < 2) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SplitSettleUpScreen(group: widget.group, members: _members),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final online = context.watch<ConnectivityNotifier>().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            tooltip: 'Add member',
            onPressed: online ? _addMember : null,
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: 'Could not load group',
                  subtitle: 'Please try again.',
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _balancesCard(cs),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Activity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: online ? _settleUp : null,
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Settle up'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: online ? _newSplitExpense : null,
                            icon: const Icon(Icons.add),
                            label: const Text('Split'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_expenses.isEmpty && _payments.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.receipt_long,
                          title: 'No split activity yet',
                          subtitle: 'Add a split expense or record a settle-up payment.',
                        )
                      else ...[
                        ..._expenses.map((e) => _expenseTile(cs, e)),
                        ..._payments.map((p) => _paymentTile(cs, p)),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Members (${_members.length})',
                        style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _members
                            .map(
                              (m) => Chip(
                                label: Text(m.displayName),
                                backgroundColor: cs.surfaceContainer,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _balancesCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balances',
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          if (_balances.isEmpty)
            Text(
              'No balances yet.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ..._balances.map((b) {
              final name = (b['display_name'] as String?) ?? '';
              final net = parseDoubleOrDefault(b['net_balance']);
              final isCreditor = net > 0.005;
              final isDebtor = net < -0.005;
              final label = isCreditor
                  ? 'gets'
                  : isDebtor
                      ? 'owes'
                      : 'settled';
              final value = net.abs().toStringAsFixed(2);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: TextStyle(
                        color: isCreditor
                            ? cs.primary
                            : isDebtor
                                ? cs.error
                                : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _expenseTile(ColorScheme cs, dynamic e) {
    final payerId = e.paidByMemberId;
    final payer = _members.where((m) => m.id == payerId).toList();
    final payerName = payer.isNotEmpty ? payer.first.displayName : 'Unknown';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: cs.primary.withValues(alpha: 0.12),
        child: Icon(Icons.receipt_long, color: cs.primary),
      ),
      title: Text(
        e.notes?.toString().trim().isNotEmpty == true ? e.notes.toString().trim() : 'Split expense',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('Paid by $payerName'),
      trailing: Text(
        e.totalAmount.toStringAsFixed(2),
        style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
      ),
    );
  }

  Widget _paymentTile(ColorScheme cs, dynamic p) {
    final from = _members.where((m) => m.id == p.fromMemberId).toList();
    final to = _members.where((m) => m.id == p.toMemberId).toList();
    final fromName = from.isNotEmpty ? from.first.displayName : 'Unknown';
    final toName = to.isNotEmpty ? to.first.displayName : 'Unknown';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: cs.tertiary.withValues(alpha: 0.12),
        child: Icon(Icons.swap_horiz, color: cs.tertiary),
      ),
      title: Text('Settlement'),
      subtitle: Text('$fromName → $toName'),
      trailing: Text(
        p.amount.toStringAsFixed(2),
        style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
      ),
    );
  }
}

