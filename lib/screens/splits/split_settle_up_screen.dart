import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/split_group_model.dart';
import '../../models/split_member_model.dart';
import '../../providers/connectivity_provider.dart';
import '../../services/split_service.dart';
import '../../utils/validators.dart';

class SplitSettleUpScreen extends StatefulWidget {
  const SplitSettleUpScreen({
    super.key,
    required this.group,
    required this.members,
  });

  final SplitGroupModel group;
  final List<SplitMemberModel> members;

  @override
  State<SplitSettleUpScreen> createState() => _SplitSettleUpScreenState();
}

class _SplitSettleUpScreenState extends State<SplitSettleUpScreen> {
  final _svc = SplitService();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _fromId;
  String? _toId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.members.length >= 2) {
      _fromId = widget.members.first.id;
      _toId = widget.members[1].id;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final online = context.read<ConnectivityNotifier>().isOnline;
    if (!online) return;
    final from = _fromId;
    final to = _toId;
    if (from == null || to == null || from == to) return;
    final amt = parseAmount(_amountCtrl.text);
    if (amt == null || amt <= 0) return;

    setState(() => _saving = true);
    try {
      await _svc.createPayment(
        groupId: widget.group.id,
        fromMemberId: from,
        toMemberId: to,
        amount: amt,
        dateTime: DateTime.now(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save settlement.")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityNotifier>().isOnline;
    return Scaffold(
      appBar: AppBar(title: const Text('Settle up')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _fromId,
            decoration: const InputDecoration(labelText: 'From'),
            items: widget.members
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.displayName)))
                .toList(),
            onChanged: online && !_saving ? (v) => setState(() => _fromId = v) : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _toId,
            decoration: const InputDecoration(labelText: 'To'),
            items: widget.members
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.displayName)))
                .toList(),
            onChanged: online && !_saving ? (v) => setState(() => _toId = v) : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountCtrl,
            enabled: online && !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', hintText: '0.00'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesCtrl,
            enabled: online && !_saving,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 16),
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
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

