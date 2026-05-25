import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var supabaseUrl = AppConfig.supabaseUrl.trim();
  var supabaseAnonKey = AppConfig.supabaseAnonKey.trim();

  /// Loads a dotenv file; non-empty keys override [supabaseUrl] / [supabaseAnonKey].
  Future<void> tryLoadEnvFile(String fileName) async {
    try {
      await dotenv.load(fileName: fileName);
      final u = dotenv.env['SUPABASE_URL']?.trim() ?? '';
      final k = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
      if (u.isNotEmpty) supabaseUrl = u;
      if (k.isNotEmpty) supabaseAnonKey = k;
    } catch (_) {
      // Missing file or parse error — keep previous values.
    }
  }

  // Bundled env for release APK / profile (and debug). Edit assets/config/app.env then rebuild.
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    await tryLoadEnvFile('assets/config/app.env');
  }
  // Optional project-root .env for desktop / IDE runs without dart-define.
  if ((supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) && kDebugMode) {
    await tryLoadEnvFile('.env');
  }

  AppConfig.runtimeSupabaseUrl = supabaseUrl;
  AppConfig.runtimeSupabaseAnonKey = supabaseAnonKey;

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  runApp(const ExpenseTrackerApp());
}
