import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';

import 'camera/camera_screen.dart';
import 'camera/analysis_screen.dart';

// --- MODELLER ---
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

  final ImagePicker _picker = ImagePicker();

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

  @override
  void initState() {
    super.initState();
    dailyGoal = widget.initialDailyGoal ?? 2200;

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
    super.dispose();
  }

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

  // --- ACTIONS (EYLEMLER) ---

  // + Butonuna Basınca Çıkan Menü
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
                    icon: Icons.photo_library,
                    title: "Galeri",
                    subtitle: "Fotoğraf Seç",
                    color: Colors.purpleAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
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

  // Yemek Defterinden Seçim Ekranı
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
                      // Seçilen yemeği bugüne ekle
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

  Future<void> _pickImageFromGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null && mounted) {
      final results = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisScreen(imagePath: photo.path),
        ),
      );
      if (results != null && results.isNotEmpty && mounted) {
        _addFoodsFromAnalysis(results);
      }
    }
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

  // --- UI BİLEŞENLERİ ---

  @override
  Widget build(BuildContext context) {
    final limitExceeded = remaining < 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background, // Ensure no tint
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showAppBarTitle ? 1.0 : 0.0,
                child: _buildAppBarTitle(),
              ),
              background: Padding(
                padding: const EdgeInsets.only(top: 80, bottom: 40),
                child: _buildMainTracker(limitExceeded),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Macros
                  Row(
                    children: [
                      Expanded(
                        child: _buildMacroIndicator(
                          "Protein",
                          totalProtein,
                          proteinGoal,
                          Colors.purpleAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMacroIndicator(
                          "Carbs",
                          totalCarbs,
                          carbsGoal,
                          Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMacroIndicator(
                          "Fat",
                          totalFat,
                          fatGoal,
                          Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Water
                  _buildWaterTracker(),

                  const SizedBox(height: 24),

                  // Food History
                  const Text(
                    "Bugünün Yemekleri",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFoodHistory(),

                  const SizedBox(height: 100), // Spacing for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMealOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  // --- NEW SUB-WIDGETS ---

  Widget _buildMainTracker(bool limitExceeded) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showDetailedMacros = !_showDetailedMacros;
          });
        },
        child: SizedBox(
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
      ),
    );
  }

  Widget _buildMacroIndicator(
    String label,
    int value,
    int target,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDetailedMacros = !_showDetailedMacros;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showDetailedMacros
                  ? RichText(
                      key: const ValueKey<bool>(true),
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "$value",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const WidgetSpan(
                            child: SizedBox(width: 2),
                          ), // Padding
                          TextSpan(
                            text: "/${target}g",
                            style: const TextStyle(
                              color: AppColors.textMuted, // Gray like title
                              fontWeight: FontWeight.bold,
                              fontSize: 14, // 16px - 2px
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      "${value}g",
                      key: const ValueKey<bool>(false),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (value / target).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
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
      ),
    );
  }

  Widget _buildFoodHistory() {
    if (widget.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Henüz yemek eklenmedi.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    // Show newest first
    final reversedEntries = widget.entries.reversed.toList();

    return ListView.separated(
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
    return Container(
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
                if (entry.isLoading) ...[
                  // Skeleton Loading
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
                ] else ...[
                  // Real Data
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
              ],
            ),
          ),
          if (entry.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => widget.onRemoveEntry(entry),
            ),
        ],
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

  Widget _buildAppBarTitle() {
    double progress = dailyGoal > 0 ? totalCalories / dailyGoal : 0;
    if (progress > 1.0) progress = 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end, // Align to bottom of app bar
      children: [
        Text(
          "$totalCalories / $dailyGoal kcal",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 120,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
