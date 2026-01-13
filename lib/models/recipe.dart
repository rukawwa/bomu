import 'food_entry.dart';

class Recipe {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int prepTimeMinutes;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags; // e.g., "Vegetarian", "High Protein"
  final FoodType type;

  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.prepTimeMinutes,
    required this.ingredients,
    required this.instructions,
    required this.tags,
    this.type = FoodType.healthy,
  });
}
