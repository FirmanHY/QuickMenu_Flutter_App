class RecipeModel {
  final String id;
  final String title;
  final String? imageUrl;
  final String duration;
  final List<String> categories;
  final String ingredients; // HTML format
  final String steps; // HTML format
  final String source; // 'QuickMenu' | 'Manual' | 'Instagram' | 'Web'
  final String? originalUrl;
  final String? userId;
  final bool isBookmarked;
  final int createdAt;
  final int? updatedAt;
  final String? imagePublicId;

  const RecipeModel({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.duration,
    required this.categories,
    required this.ingredients,
    required this.steps,
    this.source = 'QuickMenu',
    this.originalUrl,
    this.userId,
    this.isBookmarked = false,
    required this.createdAt,
    this.updatedAt,
    this.imagePublicId,
  });

  String get primaryCategory =>
      categories.isNotEmpty ? categories.first : 'Lainnya';

  String get durationFormatted =>
      duration.contains('Min') ? duration : '$duration Min';

  factory RecipeModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final raw = map['categories'];
    final cats = raw is List
        ? raw.map((e) => e.toString()).toList()
        : raw is Map
        ? raw.values.map((e) => e.toString()).toList()
        : <String>[];

    return RecipeModel(
      id: id,
      title: map['title']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
      duration: map['duration']?.toString() ?? '0',
      categories: List<String>.from(cats),
      ingredients: map['ingredients']?.toString() ?? '',
      steps: map['steps']?.toString() ?? '',
      source: map['source']?.toString() ?? 'QuickMenu',
      originalUrl: map['originalUrl']?.toString(),
      userId: map['userId']?.toString(),
      isBookmarked: map['isBookmarked'] == true,
      createdAt: map['createdAt'] is int
          ? map['createdAt'] as int
          : DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'] is int ? map['updatedAt'] as int : null,
      imagePublicId: map['imagePublicId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'imageUrl': imageUrl,
    'duration': duration,
    'categories': categories,
    'ingredients': ingredients,
    'steps': steps,
    'source': source,
    'originalUrl': originalUrl,
    'userId': userId,
    'isBookmarked': isBookmarked,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'imagePublicId': imagePublicId,
  };

  RecipeModel copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? duration,
    List<String>? categories,
    String? ingredients,
    String? steps,
    String? source,
    String? originalUrl,
    String? userId,
    bool? isBookmarked,
    int? createdAt,
    int? updatedAt,
    String? imagePublicId,
  }) => RecipeModel(
    id: id ?? this.id,
    title: title ?? this.title,
    imageUrl: imageUrl ?? this.imageUrl,
    duration: duration ?? this.duration,
    categories: categories ?? this.categories,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
    source: source ?? this.source,
    originalUrl: originalUrl ?? this.originalUrl,
    userId: userId ?? this.userId,
    isBookmarked: isBookmarked ?? this.isBookmarked,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    imagePublicId: imagePublicId ?? this.imagePublicId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RecipeModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
