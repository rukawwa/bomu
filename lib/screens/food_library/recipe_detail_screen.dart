import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/food_entry.dart'; // For FoodEntry and FoodType
import '../../theme.dart';
import 'package:uuid/uuid.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final Function(FoodEntry) onAddEntry;
  final bool isLiked;
  final VoidCallback? onToggleLike;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.onAddEntry,
    this.isLiked = false,
    this.onToggleLike,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  double _portionMultiplier = 1.0;

  void _showPortionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Porsiyon Seçin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPortionOption(
                        0.5,
                        "Yarım\nPorsiyon",
                        setModalState,
                      ),
                      _buildPortionOption(1.0, "Tam\nPorsiyon", setModalState),
                      _buildPortionOption(1.5, "1.5\nPorsiyon", setModalState),
                      _buildPortionOption(2.0, "Çift\nPorsiyon", setModalState),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close modal
                        _logFood(); // Log with selected portion
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Günlüğe Ekle",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPortionOption(
    double value,
    String label,
    StateSetter setModalState,
  ) {
    final isSelected = _portionMultiplier == value;
    return GestureDetector(
      onTap: () {
        setModalState(() => _portionMultiplier = value);
        setState(() {}); // Update main screen too if visible
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              "x$value",
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logFood() {
    final entry = FoodEntry(
      id: const Uuid().v4(),
      name: "${widget.recipe.name} (x$_portionMultiplier)",
      calories: (widget.recipe.calories * _portionMultiplier).round(),
      protein: (widget.recipe.protein * _portionMultiplier).round(),
      carbs: (widget.recipe.carbs * _portionMultiplier).round(),
      fat: (widget.recipe.fat * _portionMultiplier).round(),
      type: widget.recipe.type,
      time: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    widget.onAddEntry(entry);
    Navigator.pop(context); // Go back to library
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${entry.name} günlüğe eklendi!"),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.background,
            actions: [
              if (widget.onToggleLike != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      widget.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: widget.isLiked ? Colors.redAccent : Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      if (widget.onToggleLike != null) {
                        widget.onToggleLike!();
                      }
                    },
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    // Placeholder - normally use widget.recipe.imageUrl
                    "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80",
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.8),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                widget.recipe.name,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Macros Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMacroInfo(
                        "Kalori",
                        "${widget.recipe.calories} kcal",
                        Colors.white,
                      ),
                      _buildMacroInfo(
                        "Protein",
                        "${widget.recipe.protein}g",
                        Colors.purpleAccent,
                      ),
                      _buildMacroInfo(
                        "Karb",
                        "${widget.recipe.carbs}g",
                        Colors.orangeAccent,
                      ),
                      _buildMacroInfo(
                        "Yağ",
                        "${widget.recipe.fat}g",
                        Colors.amberAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Ingredients
                  const Text(
                    "Malzemeler",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.recipe.ingredients.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            i,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Instructions
                  const Text(
                    "Hazırlanışı",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.recipe.instructions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${entry.key + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'recipe_detail_fab',
        onPressed: _showPortionDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Günlüğe Ekle",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
