import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/currency_utils.dart';
import '../utils/date_utils.dart';
import '../utils/safe_parse.dart';

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.category,
    required this.currencySymbol,
  });

  final TransactionModel transaction;
  final CategoryModel? category;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final incomeColor = isDark ? AppColors.incomeDark : AppColors.incomeLight;
    final expenseColor =
        isDark ? AppColors.expenseDark : AppColors.expenseLight;
    final c = category;
    final tint = c != null
        ? parseColorOrFallback(c.color, fallback: theme.colorScheme.primary)
        : theme.colorScheme.primary;

    final title = transaction.notes?.isNotEmpty == true
        ? transaction.notes!
        : (c?.name ?? 'Transaction');
    final subtitle =
        '${c?.name ?? ''} · ${formatDayHeader(transaction.dateTime)}';
    final formattedAmount = formatMoney(transaction.amount, currencySymbol);
    final amountText = transaction.isIncome
        ? '+$formattedAmount'
        : transaction.isTransfer
            ? '↔ $formattedAmount'
            : '-$formattedAmount';
    final amountColor = transaction.isIncome
        ? incomeColor
        : transaction.isTransfer
            ? (isDark ? AppColors.transferDark : AppColors.transferLight)
            : expenseColor;

    IconData accountIcon;
    switch (transaction.accountType) {
      case 'bank':
        accountIcon = Icons.account_balance;
        break;
      case 'wallet':
        accountIcon = Icons.account_balance_wallet_outlined;
        break;
      case 'upi':
        accountIcon = Icons.smartphone_outlined;
        break;
      default:
        accountIcon = Icons.payments_outlined;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: tint.withValues(alpha: 0.15),
        child: Icon(
          c != null ? appIconFromName(c.icon) : Icons.swap_horiz,
          color: tint,
          size: 22,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amountText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Icon(accountIcon, size: 16, color: theme.colorScheme.outline),
        ],
      ),
    );
  }
}
