import 'food_entry.dart';

class CustomFood {
  final String id;
  String name;
  String? imagePath; // Local file path from gallery
  int calories;
  int protein;
  int carbs;
  int fat;
  bool isPublic;
  int likes;
  List<String> ingredients;
  List<String> instructions; // Step-by-step

  CustomFood({
    required this.id,
    required this.name,
    this.imagePath,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.isPublic = false,
    this.likes = 0,
    List<String>? ingredients,
    List<String>? instructions,
  }) : ingredients = ingredients ?? [],
       instructions = instructions ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'isPublic': isPublic,
    'likes': likes,
    'ingredients': ingredients,
    'instructions': instructions,
  };

  factory CustomFood.fromJson(Map<String, dynamic> json) => CustomFood(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    imagePath: json['imagePath'] as String?,
    calories: json['calories'] as int? ?? 0,
    protein: json['protein'] as int? ?? 0,
    carbs: json['carbs'] as int? ?? 0,
    fat: json['fat'] as int? ?? 0,
    isPublic: json['isPublic'] as bool? ?? false,
    likes: json['likes'] as int? ?? 0,
    ingredients:
        (json['ingredients'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    instructions:
        (json['instructions'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );

  /// Convert to FoodEntry for logging to the calorie tracker
  FoodEntry toFoodEntry() {
    return FoodEntry(
      id: '${id}_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      type: FoodType.healthy,
      time: DateTime.now().hour + DateTime.now().minute / 60.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomFood && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
