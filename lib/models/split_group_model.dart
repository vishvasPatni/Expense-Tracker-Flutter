import '../utils/safe_parse.dart';

class SplitGroupModel {
  const SplitGroupModel({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.currencyCode,
    required this.createdAt,
  });

  final String id;
  final String ownerUserId;
  final String name;
  final String currencyCode;
  final DateTime createdAt;

  factory SplitGroupModel.fromJson(Map<String, dynamic> json) {
    return SplitGroupModel(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      name: (json['name'] as String?) ?? '',
      currencyCode: (json['currency_code'] as String?) ?? 'USD',
      createdAt: parseDateTimeOrDefault(json['created_at']),
    );
  }
}

