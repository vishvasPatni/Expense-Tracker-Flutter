import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/budget_model.dart';
import '../utils/date_utils.dart';
import '../utils/safe_parse.dart';
import 'supabase_service.dart';

/// CRUD for `budgets` — MVP uses overall monthly rows (`category_id` null).
class BudgetService {
  BudgetService();

  final _table = SupabaseService.client.from('budgets');
  final _client = SupabaseService.client;

  /// Fetches overall budget for month start [month], or null.
  Future<BudgetModel?> fetchOverallForMonth(DateTime month) async {
    final key = startOfMonth(month);
    final rows = await _table
        .select()
        .eq('month', formatMonthDate(key))
        .isFilter('category_id', null);
    if (rows.isEmpty) return null;
    return BudgetModel.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  /// Total expenses in month via RPC (server-side sum).
  Future<double> monthlyExpenseTotal(DateTime month) async {
    final key = formatMonthDate(startOfMonth(month));
    final res = await _client.rpc(
      'get_monthly_expense_total',
      params: {'p_month_start': key},
    );
    return parseDoubleOrDefault(res);
  }

  Future<BudgetModel> upsertOverall({
    required DateTime month,
    required double amount,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthException('Not signed in');
    final key = formatMonthDate(startOfMonth(month));
    final existing = await fetchOverallForMonth(month);
    if (existing != null) {
      await _table.update({'amount': amount}).eq('id', existing.id);
      return BudgetModel(
        id: existing.id,
        userId: existing.userId,
        month: existing.month,
        amount: amount,
        categoryId: null,
        createdAt: existing.createdAt,
      );
    }
    final inserted = await _table
        .insert({
          'user_id': uid,
          'month': key,
          'amount': amount,
          'category_id': null,
        })
        .select()
        .single();
    return BudgetModel.fromJson(Map<String, dynamic>.from(inserted));
  }
}
