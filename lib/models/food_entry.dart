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

  final String? aiAnalysis; // AI feedback about the food

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
    this.aiAnalysis,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'type': type.name, // Enum to String
      'time': time,
      'imagePath': imageFile?.path, // Store path only
      'aiAnalysis': aiAnalysis,
    };
  }

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: json['calories'] as int,
      protein: json['protein'] as int? ?? 0,
      carbs: json['carbs'] as int? ?? 0,
      fat: json['fat'] as int? ?? 0,
      type: FoodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FoodType.healthy,
      ),
      time: (json['time'] as num).toDouble(),
      imageFile: json['imagePath'] != null ? File(json['imagePath']) : null,
      aiAnalysis: json['aiAnalysis'] as String?,
    );
  }
}
