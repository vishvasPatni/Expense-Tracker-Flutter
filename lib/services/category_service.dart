import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';
import 'supabase_service.dart';

/// CRUD for the `categories` table (RLS-scoped).
class CategoryService {
  CategoryService();

  final _table = SupabaseService.client.from('categories');

  /// Loads all categories for the signed-in user.
  Future<List<CategoryModel>> fetchCategories() async {
    final rows = await _table.select().order('name');
    return (rows as List<dynamic>)
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Creates a user-defined category.
  Future<CategoryModel> create({
    required String name,
    required String icon,
    required String color,
  }) async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) throw const AuthException('Not signed in');
    final inserted = await _table
        .insert({
          'user_id': uid,
          'name': name,
          'icon': icon,
          'color': color,
          'is_default': false,
        })
        .select()
        .single();
    return CategoryModel.fromJson(Map<String, dynamic>.from(inserted));
  }

  Future<void> update({
    required String id,
    required String name,
    required String icon,
    required String color,
  }) async {
    await _table.update({
      'name': name,
      'icon': icon,
      'color': color,
    }).eq('id', id);
  }

  /// Fails at DB level if `is_default` is true (RLS).
  Future<void> delete(String id) async {
    await _table.delete().eq('id', id);
  }
}
