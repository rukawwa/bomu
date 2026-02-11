import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/custom_food.dart';
import '../models/food_entry.dart';
import '../theme.dart';
import '../widgets/custom_toast.dart';
import 'my_foods/add_custom_food_screen.dart';
import 'my_foods/my_food_detail_screen.dart';

class MyFoodsScreen extends StatelessWidget {
  final List<CustomFood> customFoods;
  final Function(CustomFood) onAddFood;
  final Function(CustomFood) onUpdateFood;
  final Function(String) onRemoveFood;
  final Function(FoodEntry) onLogFood;

  const MyFoodsScreen({
    super.key,
    required this.customFoods,
    required this.onAddFood,
    required this.onUpdateFood,
    required this.onRemoveFood,
    required this.onLogFood,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "My Foods",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (customFoods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${customFoods.length} yemek",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: customFoods.isEmpty
          ? _buildEmptyState(context)
          : _buildGrid(context),
      floatingActionButton: FloatingActionButton(
        heroTag: 'my_foods_fab',
        onPressed: () => _openAddFood(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _openAddFood(BuildContext context) async {
    final result = await Navigator.push<CustomFood>(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomFoodScreen()),
    );
    if (result != null) {
      onAddFood(result);
    }
  }

  void _openEditFood(BuildContext context, CustomFood food) async {
    final result = await Navigator.push<CustomFood>(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomFoodScreen(existingFood: food),
      ),
    );
    if (result != null) {
      onUpdateFood(result);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Henüz yemeğin yok",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Kendi yemeklerini ekle ve\nhızlıca günlüğe kaydet",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _openAddFood(context),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text("Yemek Ekle"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: customFoods.length,
      itemBuilder: (context, index) {
        final food = customFoods[index];
        return _FoodCard(
          food: food,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyFoodDetailScreen(
                  food: food,
                  onLogFood: onLogFood,
                  onEditFood: (f) => _openEditFood(context, f),
                ),
              ),
            );
          },
          onEdit: () => _openEditFood(context, food),
          onDelete: () {
            onRemoveFood(food.id);
            HapticFeedback.mediumImpact();
            ToastUtils.showInfo(context, "${food.name} silindi");
          },
          onQuickLog: () {
            onLogFood(food.toFoodEntry());
            HapticFeedback.mediumImpact();
            ToastUtils.showSuccess(context, "${food.name} eklendi! 🍽️");
          },
        );
      },
    );
  }
}

class _FoodCard extends StatelessWidget {
  final CustomFood food;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onQuickLog;

  const _FoodCard({
    required this.food,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onQuickLog,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  food.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    "Düzenle",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    "Günlüğe Ekle",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onQuickLog();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    "Sil",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  color: AppColors.background,
                  image: food.imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(food.imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: food.imagePath == null
                    ? Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.primary.withValues(alpha: 0.3),
                          size: 40,
                        ),
                      )
                    : null,
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${food.calories} kcal",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        // Quick add button
                        GestureDetector(
                          onTap: onQuickLog,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
