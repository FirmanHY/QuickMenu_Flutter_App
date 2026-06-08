import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/errors/app_exception.dart';
import '../models/meal_plan_model.dart';

class PlannerRepository {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  PlannerRepository({FirebaseDatabase? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseDatabase.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  Future<List<DailyMealPlanModel>> getWeeklyPlans(
    String startDate,
    String endDate,
  ) async {
    try {
      final snap = await _db.ref('user_meal_plans/$_uid').get();
      if (!snap.exists) return [];
      final map = snap.value as Map<dynamic, dynamic>;
      return map.entries
          .where((e) {
            final d = e.key.toString();
            return d.compareTo(startDate) >= 0 && d.compareTo(endDate) <= 0;
          })
          .map(
            (e) =>
                _parseDay(e.key.toString(), e.value as Map<dynamic, dynamic>),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      throw StorageException('Gagal memuat meal plan: $e');
    }
  }

  Future<void> saveMeal(String date, MealType type, MealItemModel meal) async {
    await _db.ref('user_meal_plans/$_uid/$date/${type.name}').set(meal.toMap());
  }

  Future<void> removeMeal(String date, MealType type) async {
    await _db.ref('user_meal_plans/$_uid/$date/${type.name}').remove();
  }

  DailyMealPlanModel _parseDay(String date, Map<dynamic, dynamic> map) {
    MealItemModel? parseMeal(String key) {
      final raw = map[key];
      if (raw == null) return null;
      return MealItemModel.fromMap(key, raw as Map<dynamic, dynamic>);
    }

    return DailyMealPlanModel(
      date: date,
      breakfast: parseMeal('breakfast'),
      lunch: parseMeal('lunch'),
      dinner: parseMeal('dinner'),
    );
  }
}
