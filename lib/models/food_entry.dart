import 'dart:io';
import 'dart:typed_data';

enum FoodType { healthy, unhealthy }

class FoodEntry {
  final String id;
  String name;
  int calories;
  // Macros
  int protein;
  int carbs;
  int fat;
  final FoodType type;
  final double time;
  final File? imageFile;
  final Uint8List? imageBytes; // Cropped food thumbnail
  bool isLoading;

  FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.type,
    required this.time,
    this.imageFile,
    this.imageBytes,
    this.isLoading = false,
  });
}
