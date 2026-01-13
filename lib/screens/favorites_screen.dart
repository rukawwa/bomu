import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/food_entry.dart';

class FavoritesScreen extends StatelessWidget {
  final List<FoodEntry> savedFoods;
  final Function(FoodEntry) onAddEntry;
  final Function(FoodEntry) onRemoveFavorite;

  const FavoritesScreen({
    super.key,
    required this.savedFoods,
    required this.onAddEntry,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Favorilerim",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (savedFoods.isNotEmpty)
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
                    "${savedFoods.length} yemek",
                    style: TextStyle(
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
      body: savedFoods.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: savedFoods.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final food = savedFoods[index];
                return _FavoriteItem(
                  food: food,
                  onAdd: () {
                    final newEntry = FoodEntry(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: food.name,
                      calories: food.calories,
                      time: DateTime.now().hour + DateTime.now().minute / 60.0,
                      protein: food.protein,
                      carbs: food.carbs,
                      fat: food.fat,
                      imageBytes: food.imageBytes,
                      imageFile: food.imageFile,
                      type: food.type,
                    );
                    onAddEntry(newEntry);
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${food.name} eklendi! 🍽️"),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  onRemove: () {
                    onRemoveFavorite(food);
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${food.name} favorilerden kaldırıldı"),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.favorite_border,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Henüz favori yemeğin yok",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Yemek günlüğünde sağa kaydırarak\nfavorilere ekleyebilirsin",
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
}

class _FavoriteItem extends StatefulWidget {
  final FoodEntry food;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _FavoriteItem({
    required this.food,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_FavoriteItem> createState() => _FavoriteItemState();
}

class _FavoriteItemState extends State<_FavoriteItem>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0.0;
  late AnimationController _animationController;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isRemoving) return;
    setState(() {
      _dragExtent += details.delta.dx;
      // Only allow left swipe
      if (_dragExtent > 0) _dragExtent = 0;
      // Limit max drag
      if (_dragExtent < -150) _dragExtent = -150;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isRemoving) return;
    if (_dragExtent < -100) {
      setState(() => _isRemoving = true);
      HapticFeedback.heavyImpact();
      widget.onRemove();
    } else {
      // Spring back
      _animationController.reset();
      final anim = Tween<double>(begin: _dragExtent, end: 0.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
      );
      anim.addListener(() => setState(() => _dragExtent = anim.value));
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragExtent.abs() / 100).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Color.lerp(
                      const Color(0xFF7F1D1D),
                      const Color(0xFFDC2626),
                      progress,
                    )!,
                    Color.lerp(
                      const Color(0xFF450A0A),
                      const Color(0xFFB91C1C),
                      progress,
                    )!,
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Transform.scale(
                    scale: 0.8 + (progress * 0.4),
                    child: Icon(
                      progress >= 1.0 ? Icons.delete : Icons.delete_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Foreground
          GestureDetector(
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onTap: widget.onAdd,
            child: Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    // Food Image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.food.type == FoodType.healthy
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.secondary.withValues(alpha: 0.3),
                        ),
                        image: widget.food.imageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(widget.food.imageBytes!),
                                fit: BoxFit.cover,
                              )
                            : widget.food.imageFile != null
                            ? DecorationImage(
                                image: FileImage(widget.food.imageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          (widget.food.imageBytes == null &&
                              widget.food.imageFile == null)
                          ? Icon(
                              Icons.restaurant,
                              color: widget.food.type == FoodType.healthy
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
                            widget.food.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "${widget.food.calories} kcal",
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "P:${widget.food.protein}g C:${widget.food.carbs}g F:${widget.food.fat}g",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Add button
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
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
}
