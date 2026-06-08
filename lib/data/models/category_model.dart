class CategoryModel {
  final String id;
  final String name;
  final String? color;
  final int order;
  final String? userId; // null = kategori global

  const CategoryModel({
    required this.id,
    required this.name,
    this.color,
    required this.order,
    this.userId,
  });

  bool get isCustom => userId != null;

  factory CategoryModel.fromMap(String id, Map<dynamic, dynamic> map) =>
      CategoryModel(
        id: id,
        name: map['name']?.toString() ?? '',
        color: map['color']?.toString(),
        order: map['order'] is int ? map['order'] as int : 0,
        userId: map['userId']?.toString(),
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'color': color,
    'order': order,
    'userId': userId,
  };
}
