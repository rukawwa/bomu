import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_food.dart';

/// Persists user-created custom foods to SharedPreferences.
class CustomFoodService {
  static const String _key = 'custom_foods';

  static Future<List<CustomFood>> loadFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((e) => CustomFood.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveFoods(List<CustomFood> foods) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(foods.map((f) => f.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> addFood(CustomFood food) async {
    final foods = await loadFoods();
    foods.add(food);
    await saveFoods(foods);
  }

  static Future<void> removeFood(String id) async {
    final foods = await loadFoods();
    foods.removeWhere((f) => f.id == id);
    await saveFoods(foods);
  }
}
