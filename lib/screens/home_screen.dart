import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../services/gemini_service.dart';

import 'camera/camera_screen.dart';

// --- MODELLER ---
import '../models/food_entry.dart';

class HomeScreen extends StatefulWidget {
  final int? initialDailyGoal;
  final List<FoodEntry> entries;
  final List<FoodEntry> savedFoods;
  final Function(FoodEntry) onAddEntry;
  final Function(FoodEntry) onRemoveEntry;
  final Function(FoodEntry) onUpdateEntry;
  final Function(FoodEntry) onSaveFood;

  const HomeScreen({
    super.key,
    this.initialDailyGoal,
    required this.entries,
    required this.savedFoods,
    required this.onAddEntry,
    required this.onRemoveEntry,
    required this.onUpdateEntry,
    required this.onSaveFood,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late int dailyGoal;

  // -- NEW: Goals & State for Detailed view --
  int get proteinGoal => 150;
  int get carbsGoal => 275;
  int get fatGoal => 75;
  bool _showDetailedMacros = false; // Toggles between "100g" and "100/150g"

  bool isScanning = false;
  int waterGlasses = 0; // NEW: Water Tracking
  DateTime currentTime = DateTime.now();
  late Timer _timer;

  // Animasyonlar
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Scroll Controller for AppBar visibility
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  // Getters for Macros
  int get totalCalories =>
      widget.entries.fold(0, (sum, item) => sum + item.calories);
  int get totalProtein =>
      widget.entries.fold(0, (sum, item) => sum + item.protein);
  int get totalCarbs => widget.entries.fold(0, (sum, item) => sum + item.carbs);
  int get totalFat => widget.entries.fold(0, (sum, item) => sum + item.fat);
  int get remaining => dailyGoal - totalCalories;

  // Page Controller for Segmented View
  late PageController _pageController;
  int _currentSegment = 0;

  @override
  void initState() {
    super.initState();
    dailyGoal = widget.initialDailyGoal ?? 2200;

    // Page Controller Setup
    _pageController = PageController(initialPage: 0);

    // Scroll Controller Setup
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showAppBarTitle) {
        setState(() => _showAppBarTitle = true);
      } else if (_scrollController.offset <= 300 && _showAppBarTitle) {
        setState(() => _showAppBarTitle = false);
      }
    });

    // Initial Animation Setup
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _updateProgressAnimation(0);
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() => currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressController.dispose();
    _scrollController.dispose();
    _pageController.dispose(); // Add dispose
    super.dispose();
  }

  // ... (Keep existing methods: _updateProgressAnimation, _showAddMealOptions, etc.)
  void _updateProgressAnimation(int oldTotalCalories) {
    double oldProgress = oldTotalCalories / dailyGoal;
    double newProgress = totalCalories / dailyGoal;
    if (oldProgress > 1.0) oldProgress = 1.0;
    if (newProgress > 1.0) newProgress = 1.0;

    _progressAnimation = Tween<double>(begin: oldProgress, end: newProgress)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );
    _progressController.forward(from: 0);
  }

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
                      final results =
                          await Navigator.push<List<Map<String, dynamic>>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CameraScreen(),
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
    if (widget.savedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Yemek defterin boş. Önce yemek kaydetmelisin."),
        ),
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
                itemCount: widget.savedFoods.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final food = widget.savedFoods[index];
                  return ListTile(
                    onTap: () {
                      final now = DateTime.now();
                      final decimalTime = now.hour + now.minute / 60.0;
                      int oldTotal = totalCalories;

                      widget.onAddEntry(
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

                      _updateProgressAnimation(oldTotal);
                      Navigator.pop(context);
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
                              final foods =
                                  await GeminiService.analyzeFoodFromText(
                                    allFoods,
                                  );

                              if (!mounted) return;
                              Navigator.pop(context);

                              if (foods.isNotEmpty) {
                                _addFoodsFromAnalysis(foods);
                              }
                            } catch (e) {
                              setModalState(() => isLoading = false);
                              if (mounted) {
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
    final oldTotal = totalCalories;

    for (final food in foods) {
      final imageBytes = food['croppedImageBytes'] as Uint8List?;

      widget.onAddEntry(
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
        ),
      );
    }

    _updateProgressAnimation(oldTotal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${foods.length} yemek eklendi! (+${foods.fold(0, (sum, f) => sum + ((f['calories'] as num?)?.toInt() ?? 0))} kcal)',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine limitExceeded inside separate views if needed, or pass it down
    // Actually, Scaffolding remains similar but body changes.

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Custom Segmented Control Header
            _buildSegmentedControl(),
            const SizedBox(height: 16),

            // Swipeable Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentSegment = index);
                },
                children: [
                  _buildOverviewPage(),
                  _buildFoodLogPage(),
                  _buildSummaryPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMealOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Segmented Control Widget
  // Segmented Control Widget with Sliding Animation
  Widget _buildSegmentedControl() {
    return Container(
      height: 48, // Fixed height
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Sliding Orange Indicator
          AnimatedAlign(
            alignment: Alignment(
              _currentSegment == 0 ? -1.0 : (_currentSegment == 1 ? 0.0 : 1.0),
              0.0,
            ),
            duration: const Duration(
              milliseconds: 300,
            ), // Match PageView duration
            curve: Curves.fastOutSlowIn, // Match PageView curve
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              heightFactor: 1.0,
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Text Labels
          Row(
            children: [
              _buildSegmentTab("Genel Bakış", 0),
              _buildSegmentTab("Yemekler", 1),
              _buildSegmentTab("Özet", 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(String title, int index) {
    final bool isSelected = _currentSegment == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Update state immediately for instant feedback
          setState(() {
            _currentSegment = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(
              milliseconds: 300,
            ), // Slightly faster than default
            curve: Curves.fastOutSlowIn, // More responsive curve
          );
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: 'Inter', // Ensure font consistency
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  // --- 3 Main Pages ---

  Widget _buildOverviewPage() {
    final limitExceeded = remaining < 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildMainTracker(limitExceeded),
          const SizedBox(height: 24),
          // Macros Column
          Column(
            children: [
              _buildMacroIndicator(
                "Protein",
                totalProtein,
                proteinGoal,
                Colors.purpleAccent,
                Icons.fitness_center,
              ),
              const SizedBox(height: 16),
              _buildMacroIndicator(
                "Carbs",
                totalCarbs,
                carbsGoal,
                Colors.orangeAccent,
                Icons.bolt,
              ),
              const SizedBox(height: 16),
              _buildMacroIndicator(
                "Fat",
                totalFat,
                fatGoal,
                Colors.amberAccent,
                Icons.opacity,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildWaterTracker(),
        ],
      ),
    );
  }

  Widget _buildFoodLogPage() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: widget.entries.isEmpty
              ? Center(
                  child: Text(
                    "Henüz yemek yok.",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : Padding(
                  // Add padding for list content but not scrollbar if strictly necessary,
                  // but ListView has padding.
                  // We need to ensure the list takes available space.
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildFoodHistory(isScrollable: true),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryPage() {
    if (widget.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Henüz analiz yok",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Yemek eklediğinde koç yorumları\nburada görünecek",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Sort entries by time (newest first)
    final sortedEntries = List<FoodEntry>.from(widget.entries)
      ..sort((a, b) => b.time.compareTo(a.time));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final isLast = index == sortedEntries.length - 1;
        return _buildTimelineItem(entry, isLast);
      },
    );
  }

  Widget _buildTimelineItem(FoodEntry entry, bool isLast) {
    final isHealthy = entry.type == FoodType.healthy;
    final accentColor = isHealthy ? Colors.green : AppColors.primary;

    // Generate coach comment
    String coachComment;
    if (isHealthy) {
      if (entry.protein > 20) {
        coachComment = "Harika protein seçimi! 💪";
      } else if (entry.carbs > entry.fat) {
        coachComment = "Dengeli bir öğün 👍";
      } else {
        coachComment = "Sağlıklı tercih! 🌱";
      }
    } else {
      if (entry.calories > 500) {
        coachComment = "Yüksek kalori ⚠️";
      } else if (entry.fat > entry.protein) {
        coachComment = "Yağ oranı yüksek";
      } else {
        coachComment = "Ara sıra olur 🔄";
      }
    }

    // Format time
    final hour = entry.time.floor();
    final minute = ((entry.time - hour) * 60).round();
    final timeString =
        "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Simple dot + line
        SizedBox(
          width: 24,
          child: Column(
            children: [
              // Simple dot (no glow)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              // Simple line
              if (!isLast)
                Container(
                  width: 2,
                  height: 100,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Right side: Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time + Status row
                Row(
                  children: [
                    Text(
                      timeString,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isHealthy ? "Sağlıklı" : "Dikkatli",
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Food name
                Text(
                  entry.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                // Calories + Macros inline
                Text(
                  "${entry.calories} kcal  •  P:${entry.protein}g  K:${entry.carbs}g  Y:${entry.fat}g",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                // Coach comment (simple)
                Text(
                  coachComment,
                  style: TextStyle(
                    color: accentColor.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$label: ${value}g",
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMainTracker(bool limitExceeded) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showDetailedMacros = !_showDetailedMacros;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Removed Weekly Progress Widget call here!
            SizedBox(
              width: 240,
              height: 240,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) => CustomPaint(
                  painter: PremiumRingPainter(
                    percentage: _progressAnimation.value,
                    color: limitExceeded
                        ? AppColors.secondary
                        : AppColors.primaryDark,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Removed "TIME TO GET SHRED!" text
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.orangeAccent,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                          child: _showDetailedMacros
                              ? RichText(
                                  key: const ValueKey<bool>(true),
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "$totalCalories",
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.0,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      TextSpan(
                                        text: " / $dailyGoal",
                                        style: TextStyle(
                                          fontSize: 24, // Smaller
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ), // Gray
                                          height: 1.0,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const WidgetSpan(
                                        child: SizedBox(width: 4),
                                      ), // Padding
                                    ],
                                  ),
                                )
                              : Text(
                                  "$totalCalories",
                                  key: const ValueKey<bool>(false),
                                  style: const TextStyle(
                                    fontSize: 56, // Original large size
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.0,
                                    letterSpacing: -1,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "KCAL",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroIndicator(
    String label,
    int value,
    int target,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      // Use standard card decoration matching the Water Tracker
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.05,
        ), // Matches inactive circle background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              // Text Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "$value",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: " / ${target}g",
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Wider and more prominent Progress Bar
          Container(
            height: 12, // Increased height for better visibility
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (value / target).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodHistory({bool isScrollable = false}) {
    if (widget.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.no_meals,
                color: Colors.white.withValues(alpha: 0.2),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                "Henüz yemek eklenmedi.",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      );
    }

    // Show newest first
    final reversedEntries = widget.entries.reversed.toList();

    return isScrollable
        ? ListView.separated(
            padding: const EdgeInsets.only(bottom: 100), // padding for FAB
            itemCount: reversedEntries.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildFoodItem(reversedEntries[index]);
            },
          )
        : ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reversedEntries.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildFoodItem(reversedEntries[index]);
            },
          );
  }

  Widget _buildFoodItem(FoodEntry entry) {
    if (entry.isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant, color: AppColors.secondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return _PremiumSwipeActions(
      key: Key(entry.id),
      onDelete: () {
        widget.onRemoveEntry(entry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${entry.name} silindi"),
            backgroundColor: AppColors.surface,
            action: SnackBarAction(
              label: "Geri Al",
              textColor: AppColors.primary,
              onPressed: () => widget.onAddEntry(entry),
            ),
          ),
        );
      },
      onSave: () {
        widget.onSaveFood(entry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${entry.name} favorilere eklendi! ❤️"),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: entry.type == FoodType.healthy
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.secondary.withValues(alpha: 0.3),
                ),
                image: entry.imageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(entry.imageBytes!),
                        fit: BoxFit.cover,
                      )
                    : entry.imageFile != null
                    ? DecorationImage(
                        image: FileImage(entry.imageFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (entry.imageBytes == null && entry.imageFile == null)
                  ? Icon(
                      Icons.restaurant,
                      color: entry.type == FoodType.healthy
                          ? AppColors.primary
                          : AppColors.secondary,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${entry.calories} kcal",
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterTracker() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 0,
      ), // Removed margin to fit better
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF1E293B).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.blueAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Water Intake",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "$waterGlasses / 8 glasses",
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // FIXED: Use Wrap to prevent overflow
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(8, (index) {
              return GestureDetector(
                onTap: () => setState(() => waterGlasses = index + 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  width: 30,
                  height: 40,
                  decoration: BoxDecoration(
                    color: index < waterGlasses
                        ? Colors.blueAccent
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: index < waterGlasses
                          ? Colors.blueAccent
                          : Colors.white24,
                    ),
                  ),
                  child: Icon(
                    Icons.water_drop,
                    size: 16,
                    color: index < waterGlasses ? Colors.white : Colors.white24,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM PAINTER (Grafik Çizimi) ---
// --- CUSTOM PAINTER (Premium Gradient Ring) ---
class PremiumRingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  PremiumRingPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeWidth = 20.0;

    // Background Ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Gradient Progress Ring
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = LinearGradient(
      colors: [color.withValues(alpha: 0.5), color],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw arc starting from top (-pi/2)
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * percentage,
      false,
      progressPaint,
    );

    // Optional: Add a glow effect at the tip
    if (percentage > 0) {
      final angle = -math.pi / 2 + (2 * math.pi * percentage);
      final tipX = center.dx + radius * math.cos(angle);
      final tipY = center.dy + radius * math.sin(angle);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(Offset(tipX, tipY), 8, glowPaint);

      final tipPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(tipX, tipY), 4, tipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PremiumRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}

// ============================================================================
// PREMIUM BIDIRECTIONAL SWIPE WIDGET
// Left = Delete (Red), Right = Save (Green)
// ============================================================================

class _PremiumSwipeActions extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback? onSave;

  const _PremiumSwipeActions({
    super.key,
    required this.child,
    required this.onDelete,
    this.onSave,
  });

  @override
  State<_PremiumSwipeActions> createState() => _PremiumSwipeActionsState();
}

class _PremiumSwipeActionsState extends State<_PremiumSwipeActions>
    with TickerProviderStateMixin {
  double _dragExtent = 0.0;
  late AnimationController _animationController;
  late AnimationController _iconController;
  late Animation<double> _animation;
  late Animation<double> _iconScaleAnimation;
  bool _isActioning = false;
  bool _hasTriggeredHaptic = false;
  _SwipeDirection? _activeDirection;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _iconScaleAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isActioning) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final maxDrag = screenWidth * 0.6;

    setState(() {
      _dragExtent += details.delta.dx;

      // Determine active direction
      if (_dragExtent < 0) {
        _activeDirection = _SwipeDirection.left;
      } else if (_dragExtent > 0 && widget.onSave != null) {
        _activeDirection = _SwipeDirection.right;
      } else if (_dragExtent > 0 && widget.onSave == null) {
        _dragExtent = 0;
        return;
      }

      // Apply rubber band effect
      if (_dragExtent.abs() > maxDrag) {
        final sign = _dragExtent.isNegative ? -1 : 1;
        _dragExtent = sign * (maxDrag + ((_dragExtent.abs() - maxDrag) * 0.15));
      }
    });

    // Check threshold and trigger haptic
    final threshold = screenWidth * 0.35;
    final progress = _dragExtent.abs() / threshold;

    if (progress >= 1.0 && !_hasTriggeredHaptic) {
      HapticFeedback.mediumImpact();
      _iconController.forward();
      _hasTriggeredHaptic = true;
    } else if (progress < 0.9 && _hasTriggeredHaptic) {
      _iconController.reverse();
      _hasTriggeredHaptic = false;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isActioning) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.35;

    if (_dragExtent.abs() >= threshold) {
      _triggerAction();
    } else {
      _springBack();
    }
  }

  void _triggerAction() {
    HapticFeedback.heavyImpact();

    if (_activeDirection == _SwipeDirection.left) {
      // DELETE: Fly off screen then remove
      setState(() => _isActioning = true);
      final screenWidth = MediaQuery.of(context).size.width;

      _animationController.reset();
      _animation = Tween<double>(begin: _dragExtent, end: -screenWidth - 50)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInQuart,
            ),
          );

      _animationController.forward().then((_) {
        widget.onDelete();
      });
    } else if (_activeDirection == _SwipeDirection.right &&
        widget.onSave != null) {
      // SAVE: Spring back with a little bounce, then call save
      widget.onSave!();
      _springBackWithBounce();
    }
  }

  void _springBackWithBounce() {
    _animationController.reset();
    _animation = Tween<double>(begin: _dragExtent, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.addListener(_updateDragFromAnimation);
    _animationController.forward().then((_) {
      _animationController.removeListener(_updateDragFromAnimation);
      setState(() {
        _hasTriggeredHaptic = false;
        _activeDirection = null;
      });
    });
  }

  void _springBack() {
    _animationController.reset();
    _animation = Tween<double>(begin: _dragExtent, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.addListener(_updateDragFromAnimation);
    _animationController.forward().then((_) {
      _animationController.removeListener(_updateDragFromAnimation);
      setState(() {
        _hasTriggeredHaptic = false;
        _activeDirection = null;
      });
    });
  }

  void _updateDragFromAnimation() {
    setState(() => _dragExtent = _animation.value);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.35;
    final progress = (_dragExtent.abs() / threshold).clamp(0.0, 1.0);
    final isTriggered = progress >= 1.0;

    final isDelete = _activeDirection == _SwipeDirection.left;
    final isSave = _activeDirection == _SwipeDirection.right;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // LEFT BACKGROUND (Delete - Red)
          if (_dragExtent < 0 || _activeDirection == _SwipeDirection.left)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      isTriggered && isDelete
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF7F1D1D),
                      isTriggered && isDelete
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF450A0A),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: AnimatedBuilder(
                      animation: _iconController,
                      builder: (context, _) => Transform.scale(
                        scale: isDelete ? _iconScaleAnimation.value : 0.8,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(
                            isTriggered && isDelete ? 14 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: isTriggered && isDelete
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTriggered && isDelete
                                ? Icons.delete
                                : Icons.delete_outline,
                            color: Colors.white,
                            size: isTriggered && isDelete ? 28 : 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // RIGHT BACKGROUND (Save - Green)
          if (_dragExtent > 0 || _activeDirection == _SwipeDirection.right)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      isTriggered && isSave
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF14532D),
                      isTriggered && isSave
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF052E16),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: AnimatedBuilder(
                      animation: _iconController,
                      builder: (context, _) => Transform.scale(
                        scale: isSave ? _iconScaleAnimation.value : 0.8,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(
                            isTriggered && isSave ? 14 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: isTriggered && isSave
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTriggered && isSave
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.white,
                            size: isTriggered && isSave ? 28 : 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Foreground card
          GestureDetector(
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  _isActioning ? _animation.value : _dragExtent,
                  0,
                ),
                child: child,
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SwipeDirection { left, right }

/// Custom painter for drawing dotted lines
class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  _DottedLinePainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashLength = 4,
    this.dashGap = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawCircle(
        Offset(size.width / 2, startY + dashLength / 2),
        strokeWidth / 2,
        paint,
      );
      startY += dashLength + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
