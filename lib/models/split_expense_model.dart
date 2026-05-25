import '../utils/safe_parse.dart';

class SplitExpenseModel {
  const SplitExpenseModel({
    required this.id,
    required this.groupId,
    required this.ownerUserId,
    this.transactionId,
    required this.paidByMemberId,
    required this.totalAmount,
    this.notes,
    required this.dateTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String groupId;
  final String ownerUserId;
  final String? transactionId;
  final String paidByMemberId;
  final double totalAmount;
  final String? notes;
  final DateTime dateTime;
  final String status; // open|settled|voided
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SplitExpenseModel.fromJson(Map<String, dynamic> json) {
    return SplitExpenseModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      transactionId: json['transaction_id'] as String?,
      paidByMemberId: json['paid_by_member_id'] as String,
      totalAmount: parseDoubleOrDefault(json['total_amount']),
      notes: json['notes'] as String?,
      dateTime: parseDateTimeOrDefault(json['date_time']),
      status: (json['status'] as String?) ?? 'open',
      createdAt: parseDateTimeOrDefault(json['created_at']),
      updatedAt: parseDateTimeOrDefault(json['updated_at']),
    );
  }
}

