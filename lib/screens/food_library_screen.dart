import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/food_entry.dart';
import '../models/recipe.dart';
import 'food_library/recipe_detail_screen.dart';

class FoodLibraryScreen extends StatefulWidget {
  final Function(FoodEntry) onAddEntry;
  final Function(FoodEntry)? onSaveRecipe;
  final List<String> savedRecipeIds;
  final VoidCallback? onAddFoodTap;

  const FoodLibraryScreen({
    super.key,
    required this.onAddEntry,
    this.onSaveRecipe,
    this.savedRecipeIds = const [],
    this.onAddFoodTap,
  });

  @override
  State<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends State<FoodLibraryScreen> {
  final String _searchQuery = "";
  final List<String> _activeFilters = [];

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
        title: const Text(
          "Yemek Kütüphanesi",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Search Button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {
              // TODO: Implement search modal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Arama yakında eklenecek!"),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
          ),
          // Filter Button
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
              onPressed: widget.onAddFoodTap,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipe: recipe,
              onAddEntry: widget.onAddEntry,
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
            // Image with Heart Button
            Stack(
              children: [
                Hero(
                  tag: recipe.id,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(recipe.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Heart Button
                if (widget.onSaveRecipe != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${recipe.name} favorilere eklendi! ❤️",
                            ),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.savedRecipeIds.contains(recipe.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.savedRecipeIds.contains(recipe.id)
                              ? Colors.redAccent
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${recipe.calories} kcal",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${recipe.prepTimeMinutes} dk",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Macros Row
                  Row(
                    children: [
                      _buildMiniMacro("P", recipe.protein),
                      const SizedBox(width: 8),
                      _buildMiniMacro("C", recipe.carbs),
                      const SizedBox(width: 8),
                      _buildMiniMacro("F", recipe.fat),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMacro(String label, int value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          "$value",
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
