import 'package:flutter/foundation.dart';

import '../models/user_settings_model.dart';
import '../services/settings_service.dart';
import 'supabase_user_mixin.dart';

/// Currency + cached prefs for display across the app.
class SettingsDataNotifier extends ChangeNotifier with SupabaseUserMixin {
  SettingsDataNotifier(this._settingsService) {
    _init();
  }

  final SettingsService _settingsService;

  String currencyCode = 'USD';
  String currencySymbol = r'$';

  Future<void> _init() async {
    final c = await _settingsService.readLocalCache();
    currencyCode = c['currency_code']!;
    currencySymbol = c['currency_symbol']!;
    // Wrap in microtask to avoid notifying during the build phase
    // if the cache read completes synchronously or too quickly.
    Future.microtask(() => notifyListeners());
  }

  Future<void> hydrateFromRemote() async {
    if (!hasSignedInUser) return;
    final remote = await _settingsService.fetchRemote();
    if (remote == null) return;
    currencyCode = remote.currencyCode;
    currencySymbol = remote.currencySymbol;
    await _settingsService.cacheLocal(
      themeMode: remote.themeMode,
      currencyCode: remote.currencyCode,
      currencySymbol: remote.currencySymbol,
    );
    notifyListeners();
  }

  Future<void> setCurrency({
    required String code,
    required String symbol,
  }) async {
    currencyCode = code;
    currencySymbol = symbol;
    notifyListeners();
    final local = await _settingsService.readLocalCache();
    await _settingsService.cacheLocal(
      themeMode: local['theme_mode']!,
      currencyCode: code,
      currencySymbol: symbol,
    );
    if (!hasSignedInUser) return;
    final remote = await _settingsService.fetchRemote();
    if (remote != null) {
      await _settingsService.updateRemote(
        UserSettingsModel(
          id: remote.id,
          userId: remote.userId,
          currencyCode: code,
          currencySymbol: symbol,
          language: remote.language,
          themeMode: remote.themeMode,
          createdAt: remote.createdAt,
          updatedAt: remote.updatedAt,
        ),
      );
    }
  }
}
