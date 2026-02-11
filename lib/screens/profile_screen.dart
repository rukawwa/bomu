import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../models/food_entry.dart';
import '../models/custom_food.dart';
import '../theme.dart';
import 'my_foods/my_food_detail_screen.dart';
import 'profile/statistics_tab.dart';
import 'settings/settings_screen.dart';
import 'onboarding/subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdated;
  final List<CustomFood> likedFoods;
  final List<FoodEntry> entries;
  final Function(FoodEntry)? onLogFood;
  final Function(String)? onToggleLike;

  const ProfileScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
    this.likedFoods = const [],
    this.entries = const [],
    this.onLogFood,
    this.onToggleLike,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Onboarding-style Height Editor (Ruler) ---
  void _showHeightEditor() {
    double tempHeight = widget.userProfile.heightCm;
    const double minHeight = 140;
    const double maxHeight = 220;
    const double itemWidth = 12;

    final initialOffset = (tempHeight - minHeight) * itemWidth;
    final scrollController = ScrollController(
      initialScrollOffset: initialOffset,
    );
    int? lastHapticValue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool listenerAttached = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            void onScroll() {
              final offset = scrollController.offset;
              final height = minHeight + (offset / itemWidth);
              final clampedHeight = height.clamp(minHeight, maxHeight);
              final int roundedHeight = clampedHeight.round();
              if (lastHapticValue != roundedHeight) {
                HapticFeedback.selectionClick();
                lastHapticValue = roundedHeight;
              }
              setModalState(() => tempHeight = clampedHeight);
            }

            // Attach listener once
            if (!listenerAttached) {
              scrollController.addListener(onScroll);
              listenerAttached = true;
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    "Boyunu Güncelle",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Height Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${tempHeight.round()}",
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          " cm",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Ruler
                  SizedBox(
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SingleChildScrollView(
                          controller: scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width / 2 - 20,
                            ),
                            child: Row(
                              children: List.generate(
                                ((maxHeight - minHeight) + 1).toInt(),
                                (index) {
                                  final value = minHeight + index;
                                  final isMajor = value % 10 == 0;
                                  final isMedium = value % 5 == 0;

                                  return SizedBox(
                                    width: itemWidth,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: isMajor
                                              ? 3
                                              : (isMedium ? 2 : 1),
                                          height: isMajor
                                              ? 45
                                              : (isMedium ? 30 : 18),
                                          decoration: BoxDecoration(
                                            color: isMajor
                                                ? AppColors.primary
                                                : Colors.white.withValues(
                                                    alpha: isMedium ? 0.5 : 0.2,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        if (isMajor) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            "${value.toInt()}",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white.withValues(
                                                alpha: 0.6,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // Center Indicator
                        IgnorePointer(
                          child: Container(
                            width: 4,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Fade gradients
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 50,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppColors.surface,
                                    AppColors.surface.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 50,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    AppColors.surface,
                                    AppColors.surface.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final updated = widget.userProfile.copyWith(
                          heightCm: tempHeight,
                        );
                        widget.onProfileUpdated(updated);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Kaydet",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    ).then((_) => scrollController.dispose());
  }

  // --- Onboarding-style Weight Editor (Wheel Picker) ---
  void _showWeightEditor() {
    const double minWeight = 40;
    const double maxWeight = 150;
    double tempWeight = widget.userProfile.weightKg;

    final scrollController = FixedExtentScrollController(
      initialItem: (tempWeight - minWeight).round(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final progress = (tempWeight - minWeight) / (maxWeight - minWeight);
          final maxWidth = MediaQuery.of(context).size.width - 48; // padding
          const buttonWidthBase = 120.0;
          final availableGrowWidth = maxWidth - buttonWidthBase;
          final currentWidth =
              buttonWidthBase + (availableGrowWidth * progress);

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Kilonu Güncelle",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Wheel Picker
                SizedBox(
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dynamic Background Indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: currentWidth.clamp(buttonWidthBase, maxWidth),
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      // Wheel
                      ListWheelScrollView.useDelegate(
                        controller: scrollController,
                        itemExtent: 60,
                        perspective: 0.003,
                        diameterRatio: 1.5,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            tempWeight = minWeight + index;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: (maxWeight - minWeight).toInt() + 1,
                          builder: (context, index) {
                            final weight = minWeight + index;
                            final isSelected = tempWeight.round() == weight;

                            return Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: isSelected ? 40 : 24,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.3),
                                  letterSpacing: -1,
                                ),
                                child: Text("${weight.toInt()} kg"),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final updated = widget.userProfile.copyWith(
                        weightKg: tempWeight,
                      );
                      widget.onProfileUpdated(updated);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Kaydet",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) => scrollController.dispose());
  }

  // --- Calorie Goal Editor ---
  void _showCalorieEditor() {
    String newValue = '${widget.userProfile.dailyCalorieLimit}';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Kalori Hedefini Güncelle",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 24),
            controller: TextEditingController(
              text: '${widget.userProfile.dailyCalorieLimit}',
            ),
            decoration: InputDecoration(
              suffixText: "kcal",
              suffixStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: (value) => newValue = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "İptal",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                final parsed = int.tryParse(newValue);
                if (parsed != null && parsed > 0) {
                  final updated = widget.userProfile.copyWith(
                    dailyCalorieLimit: parsed,
                  );
                  widget.onProfileUpdated(updated);
                }
                Navigator.pop(context);
              },
              child: const Text(
                "Kaydet",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomScrollView(
            slivers: [
              // Header with Actions
              SliverAppBar(
                backgroundColor: AppColors.background,
                pinned: true,
                title: const Text(
                  "Profil",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                            userProfile: widget.userProfile,
                            onProfileUpdate: (updatedProfile) {
                              setState(() {
                                widget.userProfile.isPremium =
                                    updatedProfile.isPremium;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Profile Space - REDESIGNED
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.cardBackground,
                          AppColors.cardBackground.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200&h=200',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userProfile.name.isNotEmpty
                                        ? widget.userProfile.name
                                        : "Kullanıcı",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SubscriptionScreen(
                                                userProfile: widget.userProfile,
                                                isFromOnboarding: false,
                                                onPlanSelected: (isPremium) {
                                                  setState(() {
                                                    widget
                                                            .userProfile
                                                            .isPremium =
                                                        isPremium;
                                                  });
                                                },
                                              ),
                                          fullscreenDialog: true,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.userProfile.isPremium
                                            ? const Color(
                                                0xFFFFD700,
                                              ).withValues(alpha: 0.2)
                                            : AppColors.primary.withValues(
                                                alpha: 0.2,
                                              ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: widget.userProfile.isPremium
                                              ? const Color(
                                                  0xFFFFD700,
                                                ).withValues(alpha: 0.5)
                                              : AppColors.primary.withValues(
                                                  alpha: 0.3,
                                                ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (widget.userProfile.isPremium)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                right: 6,
                                              ),
                                              child: Icon(
                                                Icons.verified,
                                                size: 16,
                                                color: Color(0xFFFFD700),
                                              ),
                                            ),
                                          Text(
                                            widget.userProfile.isPremium
                                                ? "Premium Plan"
                                                : "Free Plan",
                                            style: TextStyle(
                                              color:
                                                  widget.userProfile.isPremium
                                                  ? const Color(0xFFFFD700)
                                                  : AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SettingsScreen(
                                      userProfile: widget.userProfile,
                                      onProfileUpdate: (updatedProfile) {
                                        setState(() {
                                          widget.userProfile.isPremium =
                                              updatedProfile.isPremium;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Health Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHealthStat(
                              "Kilo",
                              "${widget.userProfile.weightKg.round()} kg",
                              Icons.monitor_weight_outlined,
                              Colors.blueAccent,
                              () => _showWeightEditor(),
                            ),
                            _buildHealthStat(
                              "Boy",
                              "${widget.userProfile.heightCm.round()} cm",
                              Icons.height,
                              Colors.orangeAccent,
                              () => _showHeightEditor(),
                            ),
                            _buildHealthStat(
                              "Hedef",
                              "${widget.userProfile.targetWeight.round()} kg",
                              Icons.flag_outlined,
                              AppColors.primary,
                              () =>
                                  _showCalorieEditor(), // Reusing calorie editor for now or need goal editor
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tabs
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primary,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: "Beğenilenler"),
                      Tab(text: "İstatistikler"),
                    ],
                  ),
                ),
                pinned: true,
              ),

              // Tab Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLikedFoodsTab(),
                    StatisticsTab(
                      todayEntries: widget.entries,
                      userProfile: widget.userProfile,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Liked Foods Tab ---
  Widget _buildLikedFoodsTab() {
    if (widget.likedFoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 56,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              "Henüz beğendiğin yemek yok",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Kütüphanedeki yemekleri beğen",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: widget.likedFoods.length,
      itemBuilder: (context, index) {
        final food = widget.likedFoods[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyFoodDetailScreen(
                  food: food,
                  onLogFood: widget.onLogFood ?? (_) {},
                  isLiked: true,
                  onToggleLike: widget.onToggleLike != null
                      ? () => widget.onToggleLike!(food.id)
                      : null,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
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
                              size: 36,
                            ),
                          )
                        : null,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
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
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${food.calories} kcal",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
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
      },
    );
  }

  Widget _buildHealthStat(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.background, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
