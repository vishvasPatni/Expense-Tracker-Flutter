import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/split_expense_model.dart';
import '../models/split_group_model.dart';
import '../models/split_line_model.dart';
import '../models/split_member_model.dart';
import '../models/split_payment_model.dart';
import 'supabase_service.dart';

class SplitService {
  SplitService();

  final _client = SupabaseService.client;

  SupabaseQueryBuilder get _groups => _client.from('split_groups');
  SupabaseQueryBuilder get _members => _client.from('split_members');
  SupabaseQueryBuilder get _expenses => _client.from('split_expenses');
  SupabaseQueryBuilder get _lines => _client.from('split_lines');
  SupabaseQueryBuilder get _payments => _client.from('split_payments');

  Future<List<SplitGroupModel>> listGroups() async {
    final rows = await _groups.select().order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => SplitGroupModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<SplitGroupModel> createGroup({
    required String name,
    required String currencyCode,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthException('Not signed in');
    final row = await _groups
        .insert({
          'owner_user_id': uid,
          'name': name,
          'currency_code': currencyCode,
        })
        .select()
        .single();
    return SplitGroupModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<SplitMemberModel>> listMembers(String groupId) async {
    final rows = await _members
        .select()
        .eq('group_id', groupId)
        .eq('is_active', true)
        .order('created_at');
    return (rows as List<dynamic>)
        .map((e) => SplitMemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<SplitMemberModel> addMember({
    required String groupId,
    required String displayName,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthException('Not signed in');
    final row = await _members
        .insert({
          'group_id': groupId,
          'owner_user_id': uid,
          'display_name': displayName,
        })
        .select()
        .single();
    return SplitMemberModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<SplitExpenseModel>> listExpenses(String groupId) async {
    final rows = await _expenses
        .select()
        .eq('group_id', groupId)
        .neq('status', 'voided')
        .order('date_time', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => SplitExpenseModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SplitLineModel>> listLines(String splitExpenseId) async {
    final rows = await _lines
        .select()
        .eq('split_expense_id', splitExpenseId)
        .order('created_at');
    return (rows as List<dynamic>)
        .map((e) => SplitLineModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<SplitPaymentModel>> listPayments(String groupId) async {
    final rows = await _payments
        .select()
        .eq('group_id', groupId)
        .order('date_time', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => SplitPaymentModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Inserts split expense header + lines.
  /// This is not fully atomic without an RPC; Phase 1 keeps it simple.
  Future<SplitExpenseModel> createSplitExpense({
    required String groupId,
    required String paidByMemberId,
    required double totalAmount,
    required DateTime dateTime,
    required String? notes,
    required List<Map<String, dynamic>> lines, // [{member_id, owed_amount}]
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthException('Not signed in');

    final header = await _expenses
        .insert({
          'group_id': groupId,
          'owner_user_id': uid,
          'paid_by_member_id': paidByMemberId,
          'total_amount': totalAmount,
          'notes': notes,
          'date_time': dateTime.toUtc().toIso8601String(),
          'status': 'open',
        })
        .select()
        .single();

    final expense = SplitExpenseModel.fromJson(Map<String, dynamic>.from(header));

    if (lines.isNotEmpty) {
      await _lines.insert(
        lines
            .map((l) => {
                  'split_expense_id': expense.id,
                  'owner_user_id': uid,
                  'member_id': l['member_id'],
                  'owed_amount': l['owed_amount'],
                })
            .toList(),
      );
    }

    return expense;
  }

  Future<SplitPaymentModel> createPayment({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    required DateTime dateTime,
    required String? notes,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const AuthException('Not signed in');

    final row = await _payments
        .insert({
          'group_id': groupId,
          'owner_user_id': uid,
          'from_member_id': fromMemberId,
          'to_member_id': toMemberId,
          'amount': amount,
          'notes': notes,
          'date_time': dateTime.toUtc().toIso8601String(),
        })
        .select()
        .single();
    return SplitPaymentModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<Map<String, dynamic>>> getGroupBalances(String groupId) async {
    final res = await _client.rpc(
      'get_group_balances',
      params: {'p_group_id': groupId},
    );
    return (res as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}

