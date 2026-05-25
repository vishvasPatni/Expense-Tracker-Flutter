import '../utils/safe_parse.dart';

class UserSettingsModel {
  const UserSettingsModel({
    required this.id,
    required this.userId,
    required this.currencyCode,
    required this.currencySymbol,
    required this.language,
    required this.themeMode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String currencyCode;
  final String currencySymbol;
  final String language;
  final String themeMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      currencyCode: json['currency_code'] as String? ?? 'USD',
      currencySymbol: json['currency_symbol'] as String? ?? r'$',
      language: json['language'] as String? ?? 'en',
      themeMode: json['theme_mode'] as String? ?? 'system',
      createdAt: parseDateTimeOrDefault(json['created_at']),
      updatedAt: parseDateTimeOrDefault(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'language': language,
        'theme_mode': themeMode,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toUpdateJson() => {
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'language': language,
        'theme_mode': themeMode,
      };
}
