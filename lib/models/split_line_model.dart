import '../utils/safe_parse.dart';

class SplitLineModel {
  const SplitLineModel({
    required this.id,
    required this.splitExpenseId,
    required this.ownerUserId,
    required this.memberId,
    required this.owedAmount,
    required this.createdAt,
  });

  final String id;
  final String splitExpenseId;
  final String ownerUserId;
  final String memberId;
  final double owedAmount;
  final DateTime createdAt;

  factory SplitLineModel.fromJson(Map<String, dynamic> json) {
    return SplitLineModel(
      id: json['id'] as String,
      splitExpenseId: json['split_expense_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      memberId: json['member_id'] as String,
      owedAmount: parseDoubleOrDefault(json['owed_amount']),
      createdAt: parseDateTimeOrDefault(json['created_at']),
    );
  }
}

