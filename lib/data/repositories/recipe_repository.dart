import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/errors/app_exception.dart';
import '../models/recipe_model.dart';

class RecipeRepository {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  RecipeRepository({FirebaseDatabase? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseDatabase.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ── Public QuickMenu Recipes ─────────────────────────────────
  Future<List<RecipeModel>> getPublicRecipes() async {
    try {
      final snap = await _db.ref('recipes').orderByChild('createdAt').get();
      if (!snap.exists) return [];
      final map = snap.value as Map<dynamic, dynamic>;
      return map.entries
          .map(
            (e) => RecipeModel.fromMap(
              e.key.toString(),
              e.value as Map<dynamic, dynamic>,
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      throw StorageException('Gagal memuat resep: $e');
    }
  }

  // ── User Custom Recipes ──────────────────────────────────────
  Future<List<RecipeModel>> getUserRecipes() async {
    try {
      final snap = await _db.ref('user_recipes/$_uid').get();
      if (!snap.exists) return [];
      final map = snap.value as Map<dynamic, dynamic>;
      return map.entries
          .map(
            (e) => RecipeModel.fromMap(
              e.key.toString(),
              e.value as Map<dynamic, dynamic>,
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      throw StorageException('Gagal memuat resep: $e');
    }
  }

  // ── Bookmarks ────────────────────────────────────────────────
  Future<Set<String>> getBookmarkedIds() async {
    try {
      final snap = await _db.ref('user_bookmarks/$_uid').get();
      if (!snap.exists) return {};
      final map = snap.value as Map<dynamic, dynamic>;
      return map.keys.map((e) => e.toString()).toSet();
    } catch (e) {
      throw StorageException('Gagal memuat bookmark: $e');
    }
  }

  Future<List<RecipeModel>> getBookmarkedRecipes() async {
    try {
      final bookmarkSnap = await _db.ref('user_bookmarks/$_uid').get();
      if (!bookmarkSnap.exists) return [];
      final bookmarkMap = bookmarkSnap.value as Map<dynamic, dynamic>;
      final recipeIds = bookmarkMap.keys.map((e) => e.toString()).toList();

      final results = <RecipeModel>[];
      for (final id in recipeIds) {
        var snap = await _db.ref('recipes/$id').get();
        if (!snap.exists) snap = await _db.ref('user_recipes/$_uid/$id').get();
        if (snap.exists) {
          results.add(
            RecipeModel.fromMap(
              id,
              snap.value as Map<dynamic, dynamic>,
            ).copyWith(isBookmarked: true),
          );
        }
      }
      return results;
    } catch (e) {
      throw StorageException('Gagal memuat bookmark: $e');
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

  // ── Single Recipe ────────────────────────────────────────────
  Future<RecipeModel?> getRecipeById(String recipeId) async {
    final bookmarkSnap = await _db.ref('user_bookmarks/$_uid/$recipeId').get();
    final isBookmarked = bookmarkSnap.exists;

    var snap = await _db.ref('user_recipes/$_uid/$recipeId').get();
    if (snap.exists) {
      return RecipeModel.fromMap(
        recipeId,
        snap.value as Map<dynamic, dynamic>,
      ).copyWith(isBookmarked: isBookmarked);
    }
    snap = await _db.ref('recipes/$recipeId').get();
    if (snap.exists) {
      return RecipeModel.fromMap(
        recipeId,
        snap.value as Map<dynamic, dynamic>,
      ).copyWith(isBookmarked: isBookmarked, source: 'QuickMenu');
    }
    return null;
  }

  // ── CRUD ─────────────────────────────────────────────────────
  Future<String> saveRecipe(RecipeModel recipe) async {
    final ref = _db.ref('user_recipes/$_uid').push();
    final data = recipe.toMap()
      ..['userId'] = _uid
      ..['createdAt'] = ServerValue.timestamp;
    await ref.set(data);
    return ref.key!;
  }

  Future<void> updateRecipe(String recipeId, RecipeModel recipe) async {
    final data = recipe.toMap()..['updatedAt'] = ServerValue.timestamp;
    await _db.ref('user_recipes/$_uid/$recipeId').update(data);
  }

  Future<void> deleteRecipe(String recipeId) async {
    await _db.ref('user_recipes/$_uid/$recipeId').remove();
    await _db.ref('user_bookmarks/$_uid/$recipeId').remove();
  }


  Future<void> ensureUserCategory(String uid, String tagName) async {
    final id = tagName.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final ref = _db.ref('user_categories/$uid/$id');
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'id': id,
        'name': tagName,
        'displayName': tagName,
        'color': '#70B9BE',
        'isDefault': false,
        'userId': uid,
        'createdAt': ServerValue.timestamp,
      });
    }
  }
}

