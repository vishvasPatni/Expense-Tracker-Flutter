import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../models/user_settings_model.dart';
import '../services/settings_service.dart';
import 'supabase_user_mixin.dart';

/// Theme mode: persisted locally and synced to `user_settings` when available.
class ThemeNotifier extends ChangeNotifier with SupabaseUserMixin {
  ThemeNotifier(this._settingsService) {
    _loadLocal();
  }

  final SettingsService _settingsService;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeData get lightTheme => buildLightTheme();
  ThemeData get darkTheme => buildDarkTheme();

  Future<void> _loadLocal() async {
    final c = await _settingsService.readLocalCache();
    _themeMode = _parse(c['theme_mode'] ?? 'system');
    notifyListeners();
  }

  ThemeMode _parse(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get modeKey => switch (_themeMode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefsKey = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    final local = await _settingsService.readLocalCache();
    await _settingsService.cacheLocal(
      themeMode: prefsKey,
      currencyCode: local['currency_code']!,
      currencySymbol: local['currency_symbol']!,
    );
    if (!hasSignedInUser) return;
    final remote = await _settingsService.fetchRemote();
    if (remote != null) {
      await _settingsService.updateRemote(
        UserSettingsModel(
          id: remote.id,
          userId: remote.userId,
          currencyCode: remote.currencyCode,
          currencySymbol: remote.currencySymbol,
          language: remote.language,
          themeMode: prefsKey,
          createdAt: remote.createdAt,
          updatedAt: remote.updatedAt,
        ),
      );
    }
  }

  /// Pull remote theme after login (optional enhancement).
  Future<void> hydrateFromRemote() async {
    if (!hasSignedInUser) return;
    final remote = await _settingsService.fetchRemote();
    if (remote == null) return;
    _themeMode = _parse(remote.themeMode);
    notifyListeners();
    await _settingsService.cacheLocal(
      themeMode: remote.themeMode,
      currencyCode: remote.currencyCode,
      currencySymbol: remote.currencySymbol,
    );
  }
}
