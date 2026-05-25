import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_settings_model.dart';
import 'supabase_service.dart';

const _kThemeMode = 'theme_mode';
const _kCurrencyCode = 'currency_code';
const _kCurrencySymbol = 'currency_symbol';

/// Mirrors critical settings to [SharedPreferences] for fast startup.
class SettingsService {
  SettingsService();

  // Lazy getter: only accesses Supabase.instance after it's been initialized.
  SupabaseQueryBuilder get _table =>
      SupabaseService.client.from('user_settings');

  Future<UserSettingsModel?> fetchRemote() async {
    try {
      final rows = await _table.select().limit(1);
      if (rows.isEmpty) return null;
      return UserSettingsModel.fromJson(
        Map<String, dynamic>.from(rows.first as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserSettingsModel> updateRemote(UserSettingsModel s) async {
    final updated = await _table
        .update(s.toUpdateJson())
        .eq('id', s.id)
        .select()
        .single();
    final m = UserSettingsModel.fromJson(Map<String, dynamic>.from(updated));
    await cacheLocal(
      themeMode: m.themeMode,
      currencyCode: m.currencyCode,
      currencySymbol: m.currencySymbol,
    );
    return m;
  }

  Future<void> cacheLocal({
    required String themeMode,
    required String currencyCode,
    required String currencySymbol,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kThemeMode, themeMode);
    await p.setString(_kCurrencyCode, currencyCode);
    await p.setString(_kCurrencySymbol, currencySymbol);
  }

  Future<Map<String, String>> readLocalCache() async {
    final p = await SharedPreferences.getInstance();
    return {
      'theme_mode': p.getString(_kThemeMode) ?? 'system',
      'currency_code': p.getString(_kCurrencyCode) ?? 'USD',
      'currency_symbol': p.getString(_kCurrencySymbol) ?? r'$',
    };
  }
}
