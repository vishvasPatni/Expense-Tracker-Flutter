import 'package:intl/intl.dart';

String formatMoney(double amount, String symbol) {
  final fmt = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
  return fmt.format(amount);
}
