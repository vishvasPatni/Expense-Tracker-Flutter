import '../services/supabase_service.dart';

mixin SupabaseUserMixin {
  bool get hasSignedInUser =>
      SupabaseService.client.auth.currentUser != null;
}
