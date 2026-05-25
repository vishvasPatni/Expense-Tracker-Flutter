/// Build-time configuration only. Never put service role keys here.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Runtime fallback (e.g. loaded from `.env` / `assets/.env` for local dev).
  /// Kept mutable so IDE "Run" without `--dart-define` still works.
  static String runtimeSupabaseUrl = '';
  static String runtimeSupabaseAnonKey = '';

  static String get effectiveSupabaseUrl =>
      supabaseUrl.isNotEmpty ? supabaseUrl : runtimeSupabaseUrl;

  static String get effectiveSupabaseAnonKey =>
      supabaseAnonKey.isNotEmpty ? supabaseAnonKey : runtimeSupabaseAnonKey;

  static bool get hasSupabaseConfig =>
      effectiveSupabaseUrl.isNotEmpty && effectiveSupabaseAnonKey.isNotEmpty;
}
