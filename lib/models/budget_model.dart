import '../utils/safe_parse.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.amount,
    this.categoryId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime month;
  final double amount;
  final String? categoryId;
  final DateTime createdAt;

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      month: parseDateTimeOrDefault(json['month']),
      amount: _toDouble(json['amount']),
      categoryId: json['category_id'] as String?,
      createdAt: parseDateTimeOrDefault(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'month': month.toIso8601String().split('T').first,
        'amount': amount,
        'category_id': categoryId,
        'created_at': createdAt.toIso8601String(),
      };

  static double _toDouble(dynamic v) {
    return parseDoubleOrDefault(v);
  }
}
