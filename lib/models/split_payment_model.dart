import '../utils/safe_parse.dart';

class SplitPaymentModel {
  const SplitPaymentModel({
    required this.id,
    required this.groupId,
    required this.ownerUserId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    this.notes,
    required this.dateTime,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String ownerUserId;
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final String? notes;
  final DateTime dateTime;
  final DateTime createdAt;

  factory SplitPaymentModel.fromJson(Map<String, dynamic> json) {
    return SplitPaymentModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      fromMemberId: json['from_member_id'] as String,
      toMemberId: json['to_member_id'] as String,
      amount: parseDoubleOrDefault(json['amount']),
      notes: json['notes'] as String?,
      dateTime: parseDateTimeOrDefault(json['date_time']),
      createdAt: parseDateTimeOrDefault(json['created_at']),
    );
  }
}

