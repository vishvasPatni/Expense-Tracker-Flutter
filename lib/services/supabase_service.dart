import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin accessor for the initialized Supabase client singleton.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
}
