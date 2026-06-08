enum MealType {
  breakfast,
  lunch,
  dinner;

  String get label => switch (this) {
    MealType.breakfast => 'Sarapan',
    MealType.lunch => 'Makan Siang',
    MealType.dinner => 'Makan Malam',
  };
}

class MealItemModel {
  final String id;
  final String recipeId;
  final String title;
  final String? imageUrl;

  const MealItemModel({
    required this.id,
    required this.recipeId,
    required this.title,
    this.imageUrl,
  });

  factory MealItemModel.fromMap(String id, Map<dynamic, dynamic> map) =>
      MealItemModel(
        id: id,
        recipeId: map['recipeId']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        imageUrl: map['imageUrl']?.toString(),
      );

  Map<String, dynamic> toMap() => {
    'recipeId': recipeId,
    'title': title,
    'imageUrl': imageUrl,
  };
}

class DailyMealPlanModel {
  final String date; // yyyy-MM-dd
  final MealItemModel? breakfast;
  final MealItemModel? lunch;
  final MealItemModel? dinner;

  const DailyMealPlanModel({
    required this.date,
    this.breakfast,
    this.lunch,
    this.dinner,
  });

  MealItemModel? getMeal(MealType type) => switch (type) {
    MealType.breakfast => breakfast,
    MealType.lunch => lunch,
    MealType.dinner => dinner,
  };

  DailyMealPlanModel copyWith({
    String? date,
    MealItemModel? breakfast,
    MealItemModel? lunch,
    MealItemModel? dinner,
  }) => DailyMealPlanModel(
    date: date ?? this.date,
    breakfast: breakfast ?? this.breakfast,
    lunch: lunch ?? this.lunch,
    dinner: dinner ?? this.dinner,
  );
}
