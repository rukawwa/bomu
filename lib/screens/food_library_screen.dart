import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/food_entry.dart';
import '../models/recipe.dart';
import '../models/custom_food.dart';
import 'food_library/recipe_detail_screen.dart';
import 'my_foods/my_food_detail_screen.dart';
import '../widgets/custom_toast.dart';

class FoodLibraryScreen extends StatefulWidget {
  final Function(FoodEntry) onAddEntry;
  final Function(FoodEntry)? onSaveRecipe;
  final List<String> savedRecipeIds;
  final VoidCallback? onAddFoodTap;
  final List<CustomFood> publicFoods;
  final Set<String> likedFoodIds;
  final Function(String)? onToggleLike;

  const FoodLibraryScreen({
    super.key,
    required this.onAddEntry,
    this.onSaveRecipe,
    this.savedRecipeIds = const [],
    this.onAddFoodTap,
    this.publicFoods = const [],
    this.likedFoodIds = const {},
    this.onToggleLike,
  });

  @override
  State<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends State<FoodLibraryScreen> {
  String _searchQuery = "";
  final List<String> _activeFilters = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Dummy Recipes
  final List<Recipe> _allRecipes = [
    const Recipe(
      id: '1',
      name: 'Izgara Tavuk Salata',
      description: 'Protein dolu, hafif ve lezzetli bir öğle yemeği seçeneği.',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      calories: 350,
      protein: 45,
      carbs: 12,
      fat: 10,
      prepTimeMinutes: 20,
      ingredients: [
        '200g Tavuk Göğsü',
        'Mevsim Yeşillikleri',
        '1 Yk Zeytinyağı',
        'Limon',
      ],
      instructions: [
        'Tavukları ızgarada pişirin.',
        'Yeşillikleri yıkayıp doğrayın.',
        'Hepsini karıştırıp servis edin.',
      ],
      tags: ['Sağlıklı', 'Protein', 'Glutensiz'],
      type: FoodType.healthy,
    ),
    const Recipe(
      id: '2',
      name: 'Yulaf Ezmesi',
      description: 'Sabahları enerji veren mükemmel bir karbonhidrat kaynağı.',
      imageUrl:
          'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=800&q=80',
      calories: 200,
      protein: 6,
      carbs: 35,
      fat: 4,
      prepTimeMinutes: 5,
      ingredients: ['50g Yulaf', '100ml Süt', '1 Muz', 'Tarçın'],
      instructions: [
        'Yulaf ve sütü pişirin.',
        'Üzerine muz ve tarçın ekleyin.',
      ],
      tags: ['Kahvaltı', 'Sağlıklı', 'Vegetarian'],
      type: FoodType.healthy,
    ),
    const Recipe(
      id: '3',
      name: 'Somon & Kuşkonmaz',
      description: 'Omega-3 zengini somon balığı ve ızgara sebzeler.',
      imageUrl:
          'https://images.unsplash.com/photo-1467003909585-2f8a7270028d?auto=format&fit=crop&w=800&q=80',
      calories: 450,
      protein: 35,
      carbs: 5,
      fat: 25,
      prepTimeMinutes: 30,
      ingredients: ['200g Somon', '10 Dal Kuşkonmaz', 'Tereyağı'],
      instructions: ['Somonu fırınlayın.', 'Kuşkonmazları soteleyin.'],
      tags: ['Keto', 'Protein', 'Akşam Yemeği'],
      type: FoodType.healthy,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Default filters could be loaded from user profile here if accessible
  }

  List<Recipe> get _filteredRecipes {
    return _allRecipes.where((recipe) {
      final matchesSearch = recipe.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesFilter =
          _activeFilters.isEmpty ||
          _activeFilters.every((filter) => recipe.tags.contains(filter));
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _showFilterBottomSheet() {
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
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filtrele",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        [
                          'Sağlıklı',
                          'Protein',
                          'Vegetarian',
                          'Keto',
                          'Glutensiz',
                          'Kahvaltı',
                          'Akşam Yemeği',
                        ].map((filter) {
                          final isSelected = _activeFilters.contains(filter);
                          return FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _activeFilters.add(filter);
                                } else {
                                  _activeFilters.remove(filter);
                                }
                              });
                              setModalState(() {});
                            },
                            backgroundColor: AppColors.cardBackground,
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.white24,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Yemek ara...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                autofocus: true,
              )
            : const Text(
                "Yemek Kütüphanesi",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = "";
                    _searchController.clear();
                  });
                },
              )
            : null,
        actions: [
          // Search Button
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = "";
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          // Filter Button
          if (!_isSearching)
            GestureDetector(
              onTap: _showFilterBottomSheet,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _activeFilters.isNotEmpty
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune,
                  color: _activeFilters.isNotEmpty
                      ? AppColors.primary
                      : Colors.white70,
                ),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Filters
                  if (_activeFilters.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _activeFilters
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(
                                    filter,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  onDeleted: () => setState(
                                    () => _activeFilters.remove(filter),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide.none,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (_activeFilters.isNotEmpty) const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Community Foods Section
          if (widget.publicFoods.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Topluluk Yemekleri",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.publicFoods.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildCommunityFoodCard(widget.publicFoods[index]);
                }, childCount: widget.publicFoods.length),
              ),
            ),
          ],

          // Section header for built-in recipes
          if (widget.publicFoods.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Tarifler",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Recipe Grid
          if (_filteredRecipes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 50),
                child: Center(
                  child: Text(
                    "Sonuç bulunamadı.",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75, // Adjust for card height
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildRecipeCard(_filteredRecipes[index]);
                }, childCount: _filteredRecipes.length),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.onAddFoodTap != null
          ? FloatingActionButton(
              heroTag: 'food_library_fab',
              onPressed: widget.onAddFoodTap,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return _buildFoodCard(
      id: recipe.id,
      name: recipe.name,
      calories: recipe.calories,
      protein: recipe.protein,
      carbs: recipe.carbs,
      imageProvider: NetworkImage(recipe.imageUrl),
      isLiked: widget.savedRecipeIds.contains(recipe.id),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipe: recipe,
              onAddEntry: widget.onAddEntry,
              isLiked: widget.savedRecipeIds.contains(recipe.id),
              onToggleLike: widget.onSaveRecipe != null
                  ? () {
                      final entry = FoodEntry(
                        id: 'lib_${recipe.id}',
                        name: recipe.name,
                        calories: recipe.calories,
                        protein: recipe.protein,
                        carbs: recipe.carbs,
                        fat: recipe.fat,
                        type: recipe.type,
                        time: 0,
                      );
                      widget.onSaveRecipe!(entry);
                      ToastUtils.showSuccess(
                        context,
                        "${recipe.name} favorilere eklendi!",
                      );
                    }
                  : null,
            ),
          ),
        );
      },
      onLike: widget.onSaveRecipe != null
          ? () {
              final entry = FoodEntry(
                id: 'lib_${recipe.id}',
                name: recipe.name,
                calories: recipe.calories,
                protein: recipe.protein,
                carbs: recipe.carbs,
                fat: recipe.fat,
                type: recipe.type,
                time: 0,
              );
              widget.onSaveRecipe!(entry);
              ToastUtils.showSuccess(
                context,
                "${recipe.name} favorilere eklendi!",
              );
            }
          : null,
    );
  }

  Widget _buildCommunityFoodCard(CustomFood food) {
    return _buildFoodCard(
      id: food.id,
      name: food.name,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      imageProvider: food.imagePath != null
          ? FileImage(File(food.imagePath!))
          : null,
      isLiked: widget.likedFoodIds.contains(food.id),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyFoodDetailScreen(
              food: food,
              onLogFood: widget.onAddEntry,
              isLiked: widget.likedFoodIds.contains(food.id),
              onToggleLike: widget.onToggleLike != null
                  ? () {
                      HapticFeedback.lightImpact();
                      widget.onToggleLike!(food.id);
                    }
                  : null,
            ),
          ),
        );
      },
      onLike: () {
        HapticFeedback.lightImpact();
        widget.onToggleLike?.call(food.id);
      },
    );
  }

  Widget _buildFoodCard({
    required String id,
    required String name,
    required int calories,
    required int protein,
    required int carbs,
    required ImageProvider? imageProvider,
    required bool isLiked,
    required VoidCallback onTap,
    VoidCallback? onLike,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            // Image with Like Button
            Stack(
              children: [
                Hero(
                  tag: id,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      color: AppColors.background,
                      image: imageProvider != null
                          ? DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageProvider == null
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
                if (onLike != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onLike,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Stats Row
                    Row(
                      children: [
                        // Calories (Primary)
                        Text(
                          "$calories kcal",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        // Protein
                        _buildMicroStats("P", protein, Colors.purpleAccent),
                        const SizedBox(width: 8),
                        // Carbs
                        _buildMicroStats("K", carbs, Colors.orangeAccent),
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

  Widget _buildMicroStats(String label, int value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "$value",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
