import '../utils/safe_parse.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.subcategoryId,
    this.notes,
    required this.dateTime,
    required this.tags,
    required this.accountType,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.isRecurring,
    this.recurrenceInterval,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String type;
  final double amount;
  final String categoryId;
  final String? subcategoryId;
  final String? notes;
  final DateTime dateTime;
  final List<String> tags;
  final String accountType;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool isRecurring;
  final String? recurrenceInterval;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isTransfer => type == 'transfer';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      amount: _toDouble(json['amount']),
      categoryId: json['category_id'] as String,
      subcategoryId: json['subcategory_id'] as String?,
      notes: json['notes'] as String?,
      dateTime: parseDateTimeOrDefault(json['date_time']),
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? const []),
      accountType: json['account_type'] as String? ?? 'cash',
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceInterval: json['recurrence_interval'] as String?,
      createdAt: parseDateTimeOrDefault(json['created_at']),
      updatedAt: parseDateTimeOrDefault(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'amount': amount,
        'category_id': categoryId,
        'subcategory_id': subcategoryId,
        'notes': notes,
        'date_time': dateTime.toUtc().toIso8601String(),
        'tags': tags,
        'account_type': accountType,
        'image_url': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'is_recurring': isRecurring,
        'recurrence_interval': recurrenceInterval,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'type': type,
        'amount': amount,
        'category_id': categoryId,
        'subcategory_id': subcategoryId,
        'notes': notes,
        'date_time': dateTime.toUtc().toIso8601String(),
        'tags': tags,
        'account_type': accountType,
      };

  static double _toDouble(dynamic v) {
    return parseDoubleOrDefault(v);
  }
}
