import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_strings.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../utils/safe_parse.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _svc = CategoryService();
  List<CategoryModel> _list = [];
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
      final rows = await _svc.fetchCategories();
      if (!mounted) return;
      setState(() {
        _list = rows;
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

  Widget _errorState() {
    return ListView(
      children: [
        EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Could not load categories',
          subtitle: 'Please try again.',
          actionLabel: 'Retry',
          onAction: _load,
        ),
      ],
    );
  }

  Future<void> _showEditor({CategoryModel? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String iconKey = existing?.icon ?? kCategoryIconKeys.first;
    Color color = existing != null
        ? parseColorOrFallback(existing.color)
        : AppColors.categoryPalette.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: StatefulBuilder(
            builder: (context, setS) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'New category' : 'Edit category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                        ),
                        itemCount: kCategoryIconKeys.length,
                        itemBuilder: (_, i) {
                          final k = kCategoryIconKeys[i];
                          final on = iconKey == k;
                          return IconButton(
                            onPressed: () => setS(() => iconKey = k),
                            icon: Icon(
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
                          onTap: () => setS(() => color = c),
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
                          if (existing == null) {
                            await _svc.create(
                              name: n,
                              icon: iconKey,
                              color: AppColors.colorToHex(color),
                            );
                          } else {
                            await _svc.update(
                              id: existing.id,
                              name: n,
                              icon: iconKey,
                              color: AppColors.colorToHex(color),
                            );
                          }
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _load();
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

  Future<void> _delete(CategoryModel c) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete ${c.name}?'),
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
    if (!ok) return;
    try {
      await _svc.delete(c.id);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.genericError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaults = _list.where((c) => c.isDefault).toList();
    final custom = _list.where((c) => !c.isDefault).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditor(),
          ),
        ],
      ),
      body: _loading
          ? const LoadingWidget.categories()
          : _error != null
              ? _errorState()
              : ListView(
              children: [
                const ListTile(title: Text('Default Categories')),
                ...defaults.map(
                  (c) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: parseColorOrFallback(c.color)
                          .withValues(alpha: 0.2),
                      child: Icon(appIconFromName(c.icon)),
                    ),
                    title: Text(c.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.lock_outline),
                      tooltip: 'Cannot delete default',
                      onPressed: null,
                    ),
                  ),
                ),
                const Divider(),
                const ListTile(title: Text('My Categories')),
                ...custom.map(
                  (c) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: parseColorOrFallback(c.color)
                          .withValues(alpha: 0.2),
                      child: Icon(appIconFromName(c.icon)),
                    ),
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditor(existing: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(c),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
