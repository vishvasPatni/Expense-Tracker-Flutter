import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/split_group_model.dart';
import '../../models/split_member_model.dart';
import '../../providers/connectivity_provider.dart';
import '../../services/split_service.dart';
import '../../utils/validators.dart';

class SplitExpenseEditorScreen extends StatefulWidget {
  const SplitExpenseEditorScreen({
    super.key,
    required this.group,
    required this.members,
  });

  final SplitGroupModel group;
  final List<SplitMemberModel> members;

  @override
  State<SplitExpenseEditorScreen> createState() => _SplitExpenseEditorScreenState();
}

class _SplitExpenseEditorScreenState extends State<SplitExpenseEditorScreen> {
  final _svc = SplitService();
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _paidByMemberId;
  late Map<String, TextEditingController> _owedCtrls;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _paidByMemberId = widget.members.first.id;
    _owedCtrls = {
      for (final m in widget.members) m.id: TextEditingController(text: '0.00'),
    };
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _owedCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _sumOwed() {
    var sum = 0.0;
    for (final c in _owedCtrls.values) {
      sum += parseAmount(c.text) ?? 0.0;
    }
    return sum;
  }

  void _autoAdjustLast() {
    final total = parseAmount(_amountCtrl.text) ?? 0.0;
    if (total <= 0) return;
    if (widget.members.isEmpty) return;

    final lastId = widget.members.last.id;
    var sumWithoutLast = 0.0;
    for (final m in widget.members) {
      if (m.id == lastId) continue;
      sumWithoutLast += parseAmount(_owedCtrls[m.id]!.text) ?? 0.0;
    }
    final remaining = (total - sumWithoutLast);
    _owedCtrls[lastId]!.text = remaining.clamp(0.0, total).toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _save() async {
    final online = context.read<ConnectivityNotifier>().isOnline;
    if (!online) return;
    if (!_formKey.currentState!.validate()) return;
    final payer = _paidByMemberId;
    if (payer == null) return;

    final total = parseAmount(_amountCtrl.text);
    if (total == null || total <= 0) return;

    // Auto-adjust last member to fix minor rounding issues.
    _autoAdjustLast();

    final sum = _sumOwed();
    final diff = (total - sum).abs();
    if (diff > 0.011) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Split amounts must sum to ${total.toStringAsFixed(2)}.')),
      );
      return;
    }

    final lines = <Map<String, dynamic>>[];
    for (final m in widget.members) {
      final owed = parseAmount(_owedCtrls[m.id]!.text) ?? 0.0;
      lines.add({'member_id': m.id, 'owed_amount': owed});
    }

    setState(() => _saving = true);
    try {
      await _svc.createSplitExpense(
        groupId: widget.group.id,
        paidByMemberId: payer,
        totalAmount: total,
        dateTime: DateTime.now(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        lines: lines,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save split expense.")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final online = context.watch<ConnectivityNotifier>().isOnline;

    final total = parseAmount(_amountCtrl.text) ?? 0.0;
    final sum = _sumOwed();
    final remaining = total - sum;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountCtrl,
              enabled: online && !_saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total amount',
                hintText: '0.00',
              ),
              validator: (v) {
                final amt = parseAmount(v ?? '');
                if (amt == null || amt <= 0) return 'Enter an amount';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paidByMemberId,
              decoration: const InputDecoration(labelText: 'Paid by'),
              items: widget.members
                  .map(
                    (m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(m.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _paidByMemberId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              enabled: online && !_saving,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'e.g. Dinner, Taxi, Hotel…',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Remaining',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    remaining.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: remaining.abs() < 0.011 ? cs.primary : cs.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: online && !_saving ? _autoAdjustLast : null,
                    child: const Text('Auto-adjust'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Split amounts',
              style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            ...widget.members.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _owedCtrls[m.id],
                  enabled: online && !_saving,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: m.displayName,
                    hintText: '0.00',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: (!online || _saving) ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save split'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

