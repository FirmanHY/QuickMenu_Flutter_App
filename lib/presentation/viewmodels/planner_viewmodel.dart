import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/meal_plan_model.dart';
import '../../data/repositories/planner_repository.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>(
  (ref) => PlannerRepository(),
);

class PlannerState {
  final List<DailyMealPlanModel> weeklyPlan;
  final DateTime currentWeekStart;
  final bool isLoading;
  final String? errorMessage;

  const PlannerState({
    this.weeklyPlan = const [],
    required this.currentWeekStart,
    this.isLoading = false,
    this.errorMessage,
  });

  String get weekLabel {
    final fmt = DateFormat('d MMM', 'id_ID');
    final end = currentWeekStart.add(const Duration(days: 6));
    return '${fmt.format(currentWeekStart)} – ${fmt.format(end)}';
  }

  PlannerState copyWith({
    List<DailyMealPlanModel>? weeklyPlan,
    DateTime? currentWeekStart,
    bool? isLoading,
    String? errorMessage,
  }) => PlannerState(
    weeklyPlan: weeklyPlan ?? this.weeklyPlan,
    currentWeekStart: currentWeekStart ?? this.currentWeekStart,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

class PlannerViewModel extends Notifier<PlannerState> {
  static DateTime _getMonday(DateTime d) {
    final weekday = d.weekday; // Mon=1 ... Sun=7
    return DateTime(d.year, d.month, d.day - (weekday - 1));
  }

  @override
  PlannerState build() =>
      PlannerState(currentWeekStart: _getMonday(DateTime.now()));

  PlannerRepository get _repo => ref.read(plannerRepositoryProvider);

  static final _fmt = DateFormat('yyyy-MM-dd');

  Future<void> loadCurrentWeek() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final start = state.currentWeekStart;
      final end = start.add(const Duration(days: 6));

      // Buat skeleton 7 hari
      final skeleton = List.generate(7, (i) {
        final day = start.add(Duration(days: i));
        return DailyMealPlanModel(date: _fmt.format(day));
      });

      final data = await _repo.getWeeklyPlans(
        _fmt.format(start),
        _fmt.format(end),
      );

      final merged = skeleton.map((day) {
        final found = data.where((d) => d.date == day.date).firstOrNull;
        return found ?? day;
      }).toList();

      state = state.copyWith(weeklyPlan: merged, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  void goNextWeek() {
    state = state.copyWith(
      currentWeekStart: state.currentWeekStart.add(const Duration(days: 7)),
    );
    loadCurrentWeek();
  }

  void goPrevWeek() {
    state = state.copyWith(
      currentWeekStart: state.currentWeekStart.subtract(
        const Duration(days: 7),
      ),
    );
    loadCurrentWeek();
  }

  Future<void> addMeal(String date, MealType type, MealItemModel meal) async {
    // Optimistic update
    final newPlan = state.weeklyPlan.map((day) {
      if (day.date != date) return day;
      return switch (type) {
        MealType.breakfast => day.copyWith(breakfast: meal),
        MealType.lunch => day.copyWith(lunch: meal),
        MealType.dinner => day.copyWith(dinner: meal),
      };
    }).toList();
    state = state.copyWith(weeklyPlan: newPlan);

    try {
      await _repo.saveMeal(date, type, meal);
    } on AppException catch (e) {
      // Rollback on error
      state = state.copyWith(errorMessage: e.message);
      await loadCurrentWeek();
    }
  }

  Future<void> removeMeal(String date, MealType type) async {
    // Optimistic update
    final newPlan = state.weeklyPlan.map((day) {
      if (day.date != date) return day;
      return switch (type) {
        MealType.breakfast => DailyMealPlanModel(
          date: day.date,
          lunch: day.lunch,
          dinner: day.dinner,
        ),
        MealType.lunch => DailyMealPlanModel(
          date: day.date,
          breakfast: day.breakfast,
          dinner: day.dinner,
        ),
        MealType.dinner => DailyMealPlanModel(
          date: day.date,
          breakfast: day.breakfast,
          lunch: day.lunch,
        ),
      };
    }).toList();
    state = state.copyWith(weeklyPlan: newPlan);

    try {
      await _repo.removeMeal(date, type);
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      await loadCurrentWeek();
    }
  }
}

final plannerViewModelProvider =
    NotifierProvider<PlannerViewModel, PlannerState>(PlannerViewModel.new);
