import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/currency_utils.dart';

/// Glass-style balance summary (Design: glassmorphism on balance card only).
class BalanceCardDark extends StatelessWidget {
  const BalanceCardDark({
    super.key,
    required this.balanceLabel,
    required this.balanceAmount,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.currencySymbol,
    this.budgetProgress,
    this.budgetAmount,
    this.spentAmount,
  });

  final String balanceLabel;
  final double balanceAmount;
  final double incomeTotal;
  final double expenseTotal;
  final String currencySymbol;
  final double? budgetProgress;
  final double? budgetAmount;
  final double? spentAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final incomeC = isDark ? AppColors.incomeDark : AppColors.incomeLight;
    final expenseC = isDark ? AppColors.expenseDark : AppColors.expenseLight;
    final borderColor = Colors.white.withValues(alpha: isDark ? 0.12 : 0.45);
    final frosted = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: frosted,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                balanceLabel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(balanceAmount, currencySymbol),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _moneyCol(
                      context,
                      label: 'Income',
                      amount: incomeTotal,
                      color: incomeC,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _moneyCol(
                      context,
                      label: 'Expense',
                      amount: expenseTotal,
                      color: expenseC,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
              if (budgetProgress != null &&
                  budgetAmount != null &&
                  spentAmount != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: budgetProgress!.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatMoney(spentAmount!, currencySymbol)} / ${formatMoney(budgetAmount!, currencySymbol)} budget',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _moneyCol(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatMoney(amount, currencySymbol),
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
