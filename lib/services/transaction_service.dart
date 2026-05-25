import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';
import '../utils/date_utils.dart';
import '../utils/safe_parse.dart';
import 'supabase_service.dart';

enum TransactionSort { latest, highest, lowest }

/// CRUD and queries for `transactions`.
class TransactionService {
  TransactionService();

  final _table = SupabaseService.client.from('transactions');
  final _client = SupabaseService.client;

  static const int pageSize = 50;

  /// Paginated list with optional filters (RLS applies).
  Future<List<TransactionModel>> fetchPage({
    int offset = 0,
    int limit = pageSize,
    String? type,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? notesSearch,
    String? tag,
    TransactionSort sort = TransactionSort.latest,
  }) async {
    dynamic query = _table.select();

    if (type != null && type.isNotEmpty) {
      query = query.eq('type', type);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    if (dateFrom != null) {
      query = query.gte('date_time', dateFrom.toUtc().toIso8601String());
    }
    if (dateTo != null) {
      query = query.lte('date_time', dateTo.toUtc().toIso8601String());
    }
    if (notesSearch != null && notesSearch.trim().isNotEmpty) {
      query = query.ilike('notes', '%${notesSearch.trim()}%');
    }
    if (tag != null && tag.trim().isNotEmpty) {
      query = query.contains('tags', [tag.trim()]);
    }

    dynamic ordered;
    switch (sort) {
      case TransactionSort.latest:
        ordered = query.order('date_time', ascending: false);
        break;
      case TransactionSort.highest:
        ordered = query.order('amount', ascending: false);
        break;
      case TransactionSort.lowest:
        ordered = query.order('amount', ascending: true);
        break;
    }

    final rows = await ordered.range(offset, offset + limit - 1);
    return (rows as List<dynamic>)
        .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Fetches all rows in batches using the same filters/sort as [fetchPage].
  Future<List<TransactionModel>> fetchAll({
    String? type,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? notesSearch,
    String? tag,
    TransactionSort sort = TransactionSort.latest,
  }) async {
    final all = <TransactionModel>[];
    var offset = 0;
    while (true) {
      final page = await fetchPage(
        offset: offset,
        limit: pageSize,
        type: type,
        categoryId: categoryId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        notesSearch: notesSearch,
        tag: tag,
        sort: sort,
      );
      all.addAll(page);
      if (page.length < pageSize) {
        break;
      }
      offset += page.length;
      if (offset >= 5000) {
        // Hard cap to avoid excessive memory/network usage on pathological datasets.
        break;
      }
    }
    return all;
  }

  Future<List<TransactionModel>> recent({int n = 5, required DateTime month}) async {
    final start = startOfMonth(month);
    final end = endOfMonth(month);
    return fetchPage(
      limit: n,
      offset: 0,
      dateFrom: start,
      dateTo: end,
      sort: TransactionSort.latest,
    );
  }

  Future<TransactionModel> insert(TransactionModel draft) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthException('Not signed in');
    final row = await _table
        .insert({
          ...draft.toInsertJson(),
          'user_id': uid,
        })
        .select()
        .single();
    return TransactionModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<TransactionModel> update(TransactionModel m) async {
    final row = await _table
        .update(m.toInsertJson())
        .eq('id', m.id)
        .select()
        .single();
    return TransactionModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String id) async {
    await _table.delete().eq('id', id);
  }

  Future<Map<String, double>> monthlySummary(DateTime month) async {
    final key = formatMonthDate(startOfMonth(month));
    final res = await _client.rpc(
      'get_monthly_summary',
      params: {'p_month_start': key},
    );
    final list = res as List<dynamic>;
    if (list.isEmpty) return {'income': 0, 'expense': 0};
    final row = list.first as Map<String, dynamic>;
    return {
      'income': parseNum(row['income_total']),
      'expense': parseNum(row['expense_total']),
    };
  }

  Future<List<Map<String, dynamic>>> categoryExpenseTotals({
    required DateTime start,
    required DateTime end,
  }) async {
    final res = await _client.rpc(
      'get_category_expense_totals',
      params: {
        'p_start': start.toUtc().toIso8601String(),
        'p_end': end.toUtc().toIso8601String(),
      },
    );
    return (res as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> monthlyTotalsLastN({int n = 6}) async {
    final res = await _client.rpc(
      'get_monthly_totals_last_n',
      params: {'p_n': n},
    );
    return (res as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, double>> periodIncomeExpense({
    required DateTime start,
    required DateTime end,
  }) async {
    final res = await _client.rpc(
      'get_period_income_expense',
      params: {
        'p_start': start.toUtc().toIso8601String(),
        'p_end': end.toUtc().toIso8601String(),
      },
    );
    final list = res as List<dynamic>;
    if (list.isEmpty) return {'income': 0, 'expense': 0};
    final row = list.first as Map<String, dynamic>;
    return {
      'income': parseNum(row['income_total']),
      'expense': parseNum(row['expense_total']),
    };
  }

  static double parseNum(dynamic v) {
    return parseDoubleOrDefault(v);
  }
}
