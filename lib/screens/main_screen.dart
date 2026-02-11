import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'food_library_screen.dart';
import 'profile_screen.dart';
import 'my_foods_screen.dart';
import 'camera/camera_screen.dart';
import '../models/food_entry.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import '../services/gemini_service.dart';
import '../services/user_profile_service.dart';
import '../services/custom_food_service.dart';
import '../models/custom_food.dart';
import '../widgets/custom_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/food_log_service.dart';
import '../services/notification_service.dart';

class MainScreen extends StatefulWidget {
  final UserProfile userProfile;

  const MainScreen({super.key, required this.userProfile});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late UserProfile _userProfile;

  // SHARED STATE
  List<FoodEntry> entries = [];
  List<FoodEntry> savedFoods = [];
  List<CustomFood> customFoods = [];
  Set<String> likedFoodIds = {};

  // Used for calculating daily totals in Add Meal flow if needed,
  // though MainScreen might not track dailyGoal/total directly as HomeScreen does.
  // HomeScreen handles its own animations. MainScreen just manages the Data.

  void _saveFood(FoodEntry entry) {
    setState(() {
      // Prevent duplicates
      if (!savedFoods.any((e) => e.name == entry.name)) {
        savedFoods.add(entry);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _userProfile = widget.userProfile;
    _loadCustomFoods();
    _loadLikedFoodIds();
    _loadTodayLog(); // Load persisted data
  }

  Future<void> _loadTodayLog() async {
    final today = DateTime.now();
    final loaded = await FoodLogService.loadDailyLog(today);
    setState(() {
      entries = loaded;
    });
  }

  void _addEntry(FoodEntry entry) {
    setState(() {
      entries.add(entry);
      entries.sort((a, b) => a.time.compareTo(b.time));
    });
    FoodLogService.saveDailyLog(DateTime.now(), entries);
    NotificationService().scheduleMealReminder();
  }

  void _removeEntry(FoodEntry entry) {
    setState(() {
      entries.removeWhere((e) => e.id == entry.id);
    });
    FoodLogService.saveDailyLog(DateTime.now(), entries);
  }

  void _updateEntry(FoodEntry updatedEntry) {
    setState(() {
      final index = entries.indexWhere((e) => e.id == updatedEntry.id);
      if (index != -1) {
        entries[index] = updatedEntry;
      }
    });
    FoodLogService.saveDailyLog(DateTime.now(), entries);
  }

  void _onProfileUpdated(UserProfile updatedProfile) {
    setState(() {
      _userProfile = updatedProfile;
    });
    UserProfileService.saveProfile(updatedProfile);
    // Sync weight to daily stats if changed
    if (updatedProfile.weightKg > 0) {
      FoodLogService.updateWeight(DateTime.now(), updatedProfile.weightKg);
    }
  }

  Future<void> _loadCustomFoods() async {
    final foods = await CustomFoodService.loadFoods();
    setState(() => customFoods = foods);
  }

  void _addCustomFood(CustomFood food) {
    setState(() => customFoods.add(food));
    CustomFoodService.saveFoods(customFoods);
  }

  void _removeCustomFood(String id) {
    setState(() => customFoods.removeWhere((f) => f.id == id));
    CustomFoodService.saveFoods(customFoods);
  }

  void _updateCustomFood(CustomFood updatedFood) {
    setState(() {
      final index = customFoods.indexWhere((f) => f.id == updatedFood.id);
      if (index != -1) {
        customFoods[index] = updatedFood;
      }
    });
    CustomFoodService.saveFoods(customFoods);
  }

  static const String _likedKey = 'liked_food_ids';

  Future<void> _loadLikedFoodIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_likedKey) ?? [];
    setState(() => likedFoodIds = ids.toSet());
  }

  Future<void> _saveLikedFoodIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_likedKey, likedFoodIds.toList());
  }

  void _toggleLikeFood(String id) {
    setState(() {
      if (likedFoodIds.contains(id)) {
        likedFoodIds.remove(id);
      } else {
        likedFoodIds.add(id);
      }
    });
    _saveLikedFoodIds();
  }

  // --- ADD MEAL LOGIC (Moved from HomeScreen) ---

  void _showAddMealOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Nasıl eklemek istersin?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.camera_alt,
                    title: "Kamera",
                    subtitle: "AI Analizi",
                    color: AppColors.primary,
                    onTap: () async {
                      Navigator.pop(context);
                      final results = await Navigator.push<List<Map<String, dynamic>>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            // Calculate context
                            final totalCals = entries.fold<int>(
                              0,
                              (sum, e) => sum + e.calories,
                            );
                            final remaining =
                                _userProfile.dailyCalorieLimit - totalCals;
                            final now = DateTime.now();
                            final timeStr =
                                "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                            final contextStr =
                                "Time: $timeStr, Remaining Calories: $remaining kcal, Daily Goal: ${_userProfile.dailyCalorieLimit} kcal";

                            return CameraScreen(context: contextStr);
                          },
                        ),
                      );
                      if (results != null && results.isNotEmpty) {
                        _addFoodsFromAnalysis(results);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.menu_book_rounded,
                    title: "Defter",
                    subtitle: "Kayıtlılar",
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _openFoodBookSelection();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.edit_note,
                    title: "Yazarak Ekle",
                    subtitle: "Yemek Adı Gir",
                    color: Colors.tealAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _showTextFoodInput();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _openFoodBookSelection() {
    if (savedFoods.isEmpty) {
      ToastUtils.showWarning(
        context,
        "Yemek defterin boş. Önce yemek kaydetmelisin.",
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Yemek Defterinden Seç",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: savedFoods.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final food = savedFoods[index];
                  return ListTile(
                    onTap: () {
                      final now = DateTime.now();
                      final decimalTime = now.hour + now.minute / 60.0;
                      // Note: We don't have access to totalCalories here easily to pass "oldTotal"
                      // HomeScreen will handle animation next time it builds with new props.

                      _addEntry(
                        FoodEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: food.name,
                          calories: food.calories,
                          type: food.type,
                          time: decimalTime,
                          imageFile: null,
                          protein: food.protein,
                          carbs: food.carbs,
                          fat: food.fat,
                        ),
                      );

                      Navigator.pop(context);
                      // Switch to Tracker to see the adding effect
                      setState(() => _currentIndex = 0);
                    },
                    tileColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      Icons.restaurant,
                      color: food.type == FoodType.healthy
                          ? AppColors.primary
                          : AppColors.secondary,
                    ),
                    title: Text(
                      food.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Text(
                      "${food.calories} kcal",
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextFoodInput() {
    final textController = TextEditingController();
    bool isLoading = false;
    List<String> foodItems = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ne yedin?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Yemek adını yaz, Enter'a bas ve devam et",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                // Food chips
                if (foodItems.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: foodItems
                        .map(
                          (food) => Chip(
                            label: Text(
                              food,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            deleteIcon: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            onDeleted: () {
                              setModalState(() {
                                foodItems.remove(food);
                              });
                            },
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                if (foodItems.isNotEmpty) const SizedBox(height: 12),

                // Text field
                TextField(
                  controller: textController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    final trimmed = value.trim();
                    if (trimmed.isNotEmpty) {
                      setModalState(() {
                        foodItems.add(trimmed);
                        textController.clear();
                      });
                    }
                  },
                  onChanged: (_) => setModalState(() {}),
                  decoration: InputDecoration(
                    hintText: foodItems.isEmpty
                        ? "örn: tavuk sote, pilav"
                        : "Başka bir yemek ekle...",
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (isLoading ||
                            (foodItems.isEmpty &&
                                textController.text.trim().isEmpty))
                        ? null
                        : () async {
                            setModalState(() => isLoading = true);

                            // Include current text field content if not empty
                            final currentText = textController.text.trim();
                            final allItems = [...foodItems];
                            if (currentText.isNotEmpty) {
                              allItems.add(currentText);
                            }
                            final allFoods = allItems.join(", ");

                            try {
                              // Calculate context
                              final totalCals = entries.fold<int>(
                                0,
                                (sum, e) => sum + e.calories,
                              );
                              final remaining =
                                  _userProfile.dailyCalorieLimit - totalCals;
                              final now = DateTime.now();
                              final timeStr =
                                  "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                              final contextStr =
                                  "Time: $timeStr, Remaining Calories: $remaining kcal, Daily Goal: ${_userProfile.dailyCalorieLimit} kcal";

                              final foods =
                                  await GeminiService.analyzeFoodFromText(
                                    allFoods,
                                    context: contextStr,
                                  );

                              if (!context.mounted) return;
                              Navigator.pop(context);

                              if (foods.isNotEmpty) {
                                _addFoodsFromAnalysis(foods);
                              }
                            } catch (e) {
                              setModalState(() => isLoading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Analiz başarısız: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.3,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              final chipCount = foodItems.length;
                              final hasText = textController.text
                                  .trim()
                                  .isNotEmpty;
                              final total = chipCount + (hasText ? 1 : 0);
                              return Text(
                                total == 0
                                    ? "Yemek yaz"
                                    : "Analiz Et ($total yemek)",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addFoodsFromAnalysis(List<Map<String, dynamic>> foods) {
    final now = DateTime.now();
    final decimalTime = now.hour + now.minute / 60.0;

    for (final food in foods) {
      final imageBytes = food['croppedImageBytes'] as Uint8List?;

      _addEntry(
        FoodEntry(
          id: '${DateTime.now().millisecondsSinceEpoch}_${food['name']}',
          name: food['name']?.toString() ?? 'Bilinmeyen',
          calories: (food['calories'] as num?)?.toInt() ?? 0,
          protein: (food['protein'] as num?)?.toInt() ?? 0,
          carbs: (food['carbs'] as num?)?.toInt() ?? 0,
          fat: (food['fat'] as num?)?.toInt() ?? 0,
          type: food['type'] == 'healthy'
              ? FoodType.healthy
              : FoodType.unhealthy,
          time: decimalTime,
          imageBytes: imageBytes,
          aiAnalysis: food['analysis'] as String?,
        ),
      );
    }

    // Switch to Tracker
    setState(() => _currentIndex = 0);

    ToastUtils.showSuccess(
      context,
      '${foods.length} yemek eklendi! (+${foods.fold(0, (sum, f) => sum + ((f['calories'] as num?)?.toInt() ?? 0))} kcal)',
    );
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        userProfile: _userProfile,
        entries: entries,
        savedFoods: savedFoods,
        onAddEntry: _addEntry,
        onRemoveEntry: _removeEntry,
        onUpdateEntry: _updateEntry,
        onSaveFood: _saveFood,
      ),
      FoodLibraryScreen(
        onAddEntry: _addEntry,
        onSaveRecipe: _saveFood,
        publicFoods: customFoods.where((f) => f.isPublic).toList(),
        likedFoodIds: likedFoodIds,
        onToggleLike: _toggleLikeFood,
        onAddFoodTap: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      // MY FOODS SCREEN
      MyFoodsScreen(
        customFoods: customFoods,
        onAddFood: _addCustomFood,
        onUpdateFood: _updateCustomFood,
        onRemoveFood: _removeCustomFood,
        onLogFood: _addEntry,
      ),
      ProfileScreen(
        userProfile: _userProfile,
        onProfileUpdated: _onProfileUpdated,
        likedFoods: customFoods
            .where((f) => likedFoodIds.contains(f.id))
            .toList(),
        entries: entries,
        onLogFood: _addEntry,
        onToggleLike: _toggleLikeFood,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: screens),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: _showAddMealOptions,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: AppColors.surface,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.bolt_rounded, "Tracker"),
            _buildNavItem(1, Icons.search_rounded, "Library"),
            const SizedBox(width: 48), // Spacer for FAB
            _buildNavItem(2, Icons.restaurant_menu_rounded, "My Foods"),
            _buildNavItem(3, Icons.person_rounded, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.white38,
            size: 24,
          ),
          const SizedBox(height: 4),
          // Optional: Show Label? If space permits. The design usually omits separate labels
          // or shows them small.
          // Text(label, style: TextStyle(fontSize: 10, color: ...))
        ],
      ),
    );
  }
}
