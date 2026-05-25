import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/currency_utils.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.budget,
    required this.currencySymbol,
  });

  final double spent;
  final double budget;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final pct = budget > 0 ? spent / budget : 0.0;
    Color barColor;
    if (pct < 0.75) {
      barColor = AppColors.incomeLight;
    } else if (pct < 1) {
      barColor = AppColors.warningLight;
    } else {
      barColor = AppColors.expenseLight;
    }

    final remaining = budget - spent;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Spent', style: theme.textTheme.bodySmall),
            Text(
              '${formatMoney(spent, currencySymbol)} / ${formatMoney(budget, currencySymbol)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                color: barColor,
                backgroundColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (remaining >= 0)
          Text(
            '${formatMoney(remaining, currencySymbol)} remaining',
            style: theme.textTheme.bodyMedium,
          )
        else
          Text(
            'Over budget by ${formatMoney(-remaining, currencySymbol)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.expenseLight,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
