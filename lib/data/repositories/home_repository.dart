import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/errors/app_exception.dart';
import '../models/recipe_model.dart';
import '../models/meal_plan_model.dart';

class HomeRepository {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  HomeRepository({FirebaseDatabase? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseDatabase.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  static String get _todayKey {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Ambil menu hari ini dari user_meal_plans
  Future<DailyMealPlanModel?> getTodayMealPlan() async {
    try {
      final snap = await _db.ref('user_meal_plans/$_uid/$_todayKey').get();
      if (!snap.exists) return null;

      final map = snap.value as Map<dynamic, dynamic>;

      MealItemModel? parseMeal(String key) {
        final raw = map[key];
        if (raw == null) return null;
        return MealItemModel.fromMap(key, raw as Map<dynamic, dynamic>);
      }

      return DailyMealPlanModel(
        date: _todayKey,
        breakfast: parseMeal('breakfast'),
        lunch: parseMeal('lunch'),
        dinner: parseMeal('dinner'),
      );
    } catch (e) {
      return null; // Non-fatal, home tetap tampil
    }
  }

  /// Ambil resep sehat dari public recipes (filter category 'healthy')
  Future<List<RecipeModel>> getHealthyRecipes() async {
    try {
      final snap = await _db.ref('recipes').get();
      if (!snap.exists) return [];

      final map = snap.value as Map<dynamic, dynamic>;

      // Ambil bookmark set user
      final bookmarkSnap = await _db.ref('user_bookmarks/$_uid').get();
      final bookmarkedIds = <String>{};
      if (bookmarkSnap.exists) {
        final bMap = bookmarkSnap.value as Map<dynamic, dynamic>;
        bookmarkedIds.addAll(bMap.keys.map((k) => k.toString()));
      }

      return map.entries
          .map(
            (e) => RecipeModel.fromMap(
              e.key.toString(),
              e.value as Map<dynamic, dynamic>,
            ),
          )
          .where((r) => r.categories.any((c) => c.toLowerCase() == 'sehat'))
          .map((r) => r.copyWith(isBookmarked: bookmarkedIds.contains(r.id)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      throw StorageException('Gagal memuat resep: $e');
    }
  }

  Future<void> toggleBookmark(String recipeId, bool isBookmarked) async {
    final ref = _db.ref('user_bookmarks/$_uid/$recipeId');
    if (isBookmarked) {
      await ref.set({'bookmarkedAt': ServerValue.timestamp});
    } else {
      await ref.remove();
    }
  }

  Future<String?> getUserFullName() async {
    try {
      final snap = await _db.ref('users/$_uid/fullName').get();
      return snap.exists ? snap.value?.toString() : null;
    } catch (_) {
      return null;
    }
  }
}
