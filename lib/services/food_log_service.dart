import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_entry.dart';

class DailyStats {
  final DateTime date;
  final int totalCalories;
  final double weight;

  DailyStats({
    required this.date,
    required this.totalCalories,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'totalCalories': totalCalories,
    'weight': weight,
  };

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
    date: DateTime.parse(json['date']),
    totalCalories: json['totalCalories'],
    weight: json['weight'],
  );
}

class FoodLogService {
  static const String _logPrefix = 'log_';
  static const String _statsKey = 'daily_stats_history';

  static String _getDateKey(DateTime date) {
    return "${_logPrefix}${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // --- Daily Log Operations ---

  static Future<void> saveDailyLog(
    DateTime date,
    List<FoodEntry> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getDateKey(date);

    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(key, jsonEncode(jsonList));

    // Also update stats for charts
    await _updateDailyStats(date, entries);
  }

  static Future<List<FoodEntry>> loadDailyLog(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getDateKey(date);
    final jsonString = prefs.getString(key);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => FoodEntry.fromJson(e)).toList();
    } catch (e) {
      print("Error loading log for $date: $e");
      return [];
    }
  }

  // --- Statistics Operations ---

  static Future<void> _updateDailyStats(
    DateTime date,
    List<FoodEntry> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHistory = await loadHistory();

    final totalCals = entries.fold<int>(0, (sum, e) => sum + e.calories);

    // Check if we have weight processing logic elsewhere or pass it here?
    // For now let's assume weight is updated separately or just fetch current weight if available?
    // Actually, weight tracking might be separate. We'll just update calories here.
    // If weight is missing, we might keep old value or 0.

    // Find if date exists
    final index = currentHistory.indexWhere((s) => _isSameDay(s.date, date));
    double weight =
        0; // Default or fetch from profile if possible but profile storage is separate.

    if (index != -1) {
      weight = currentHistory[index].weight;
      // Update entry
      currentHistory[index] = DailyStats(
        date: date,
        totalCalories: totalCals,
        weight: weight,
      );
    } else {
      // New entry
      currentHistory.add(
        DailyStats(
          date: date,
          totalCalories: totalCals,
          weight: 0, // Placeholder
        ),
      );
    }

    // Sort by date
    currentHistory.sort((a, b) => a.date.compareTo(b.date));

    // Save back
    final jsonList = currentHistory.map((e) => e.toJson()).toList();
    await prefs.setString(_statsKey, jsonEncode(jsonList));
  }

  static Future<void> updateWeight(DateTime date, double newWeight) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHistory = await loadHistory();

    final index = currentHistory.indexWhere((s) => _isSameDay(s.date, date));

    if (index != -1) {
      currentHistory[index] = DailyStats(
        date: date,
        totalCalories: currentHistory[index].totalCalories,
        weight: newWeight,
      );
    } else {
      // If no food log exists yet for today, create stats entry
      currentHistory.add(
        DailyStats(date: date, totalCalories: 0, weight: newWeight),
      );
    }

    currentHistory.sort((a, b) => a.date.compareTo(b.date));

    final jsonList = currentHistory.map((e) => e.toJson()).toList();
    await prefs.setString(_statsKey, jsonEncode(jsonList));
  }

  static Future<List<DailyStats>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_statsKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => DailyStats.fromJson(e)).toList();
    } catch (e) {
      print("Error loading history: $e");
      return [];
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
