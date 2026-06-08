//
// Repository untuk mengambil data kategori dari Firebase Realtime Database.
// Mengikuti pola yang sama dengan RecipeRepository.

import 'package:firebase_database/firebase_database.dart';
import '../../core/errors/app_exception.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final FirebaseDatabase _db;

  CategoryRepository({FirebaseDatabase? db})
    : _db = db ?? FirebaseDatabase.instance;

  /// Ambil semua kategori default (global) dari node `categories/`.
  /// Diurutkan berdasarkan field `order` (ascending).
  Future<List<CategoryModel>> getDefaultCategories() async {
    try {
      final snap = await _db.ref('categories').orderByChild('order').get();

      if (!snap.exists) return [];

      final map = snap.value as Map<dynamic, dynamic>;
      final categories =
          map.entries
              .map(
                (e) => CategoryModel.fromMap(
                  e.key.toString(),
                  e.value as Map<dynamic, dynamic>,
                ),
              )
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

      return categories;
    } catch (e) {
      throw StorageException('Gagal memuat kategori: $e');
    }
  }
}
