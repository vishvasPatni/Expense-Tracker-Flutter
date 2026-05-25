import 'package:flutter/material.dart';

import '../constants/app_icons.dart';

class CategoryChoiceChip extends StatelessWidget {
  const CategoryChoiceChip({
    super.key,
    required this.label,
    required this.iconName,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String iconName;
  final Color color;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final base = color.withValues(alpha: selected ? 0.35 : 0.12);
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: FilterChip(
        showCheckmark: false,
        selected: selected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              appIconFromName(iconName),
              size: 18,
              color: selected ? color : color.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        selectedColor: base,
        backgroundColor: base,
        side: BorderSide(
          color: selected ? color : Colors.transparent,
          width: 1.5,
        ),
        onSelected: onSelected,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
