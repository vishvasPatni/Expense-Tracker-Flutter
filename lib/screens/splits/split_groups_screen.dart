import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/connectivity_provider.dart';
import '../../providers/settings_data_notifier.dart';
import '../../services/split_service.dart';
import '../../widgets/empty_state_widget.dart';
import 'split_group_detail_screen.dart';

class SplitGroupsScreen extends StatefulWidget {
  const SplitGroupsScreen({super.key});

  @override
  State<SplitGroupsScreen> createState() => _SplitGroupsScreenState();
}

class _SplitGroupsScreenState extends State<SplitGroupsScreen> {
  final _svc = SplitService();
  bool _loading = true;
  String? _error;
  List<dynamic> _groups = [];

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
      final groups = await _svc.listGroups();
      if (!mounted) return;
      setState(() {
        _groups = groups;
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

  Future<void> _createGroup() async {
    final online = context.read<ConnectivityNotifier>().isOnline;
    if (!online) return;

    final nameCtrl = TextEditingController();
    final currencyCode = context.read<SettingsDataNotifier>().currencyCode;

    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('New split group'),
            content: TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. Goa trip, Roommates'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
            ],
          ),
        ) ??
        false;

    if (!ok) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    try {
      await _svc.createGroup(name: name, currencyCode: currencyCode);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't create group. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityNotifier>().isOnline;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split groups'),
        actions: [
          IconButton(
            tooltip: 'New group',
            onPressed: online ? _createGroup : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: 'Could not load groups',
                  subtitle: 'Please try again.',
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : _groups.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.groups_outlined,
                      title: 'No split groups yet',
                      subtitle: online
                          ? 'Create a group to start splitting expenses.'
                          : "You're offline. Connect to create a group.",
                      actionLabel: online ? 'Create group' : null,
                      onAction: online ? _createGroup : null,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _groups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final g = _groups[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SplitGroupDetailScreen(group: g),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.groups, color: cs.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        Text(
                                          g.currencyCode,
                                          style: TextStyle(color: cs.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: online
          ? FloatingActionButton.extended(
              onPressed: _createGroup,
              label: const Text('New group'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}

