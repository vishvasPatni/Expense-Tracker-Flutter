import 'package:intl/intl.dart';

DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

DateTime endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0, 23, 59, 59);

/// `YYYY-MM-DD` for Postgres `date` / RPC.
String formatMonthDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-01';

String formatDisplayMonth(DateTime d) =>
    DateFormat.yMMMM().format(d);

String formatDayHeader(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat.yMMMd().format(d);
}

(DateTime start, DateTime end) weekRangeContaining(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  final start = day.subtract(Duration(days: day.weekday - 1));
  final end = start
      .add(const Duration(days: 6))
      .copyWith(hour: 23, minute: 59, second: 59);
  return (start, end);
}

(DateTime start, DateTime end) lastNMonthsRange(int n) {
  final end = DateTime.now();
  final start = DateTime(end.year, end.month - (n - 1), 1);
  return (
    DateTime(start.year, start.month, start.day),
    end,
  );
}
