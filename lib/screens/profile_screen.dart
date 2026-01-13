import 'package:flutter/material.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Local State for Health Metrics (Mock Data)
  int _height = 180;
  double _weight = 75.5;
  int _calorieGoal = 2200;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditDialog(
    String title,
    String currentValue,
    Function(String) onSave,
  ) {
    String newValue = currentValue;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: TextField(
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: currentValue,
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
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
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                onSave(newValue);
                Navigator.pop(context);
              },
              child: const Text(
                "Save",
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
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Profile Space
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE3D4B6),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200&h=200',
                            ),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color: AppColors.background,
                            width: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name & Location
                      const Text(
                        "Burakhan Sarıçiçek",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Altıeylül, 10, TR",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Health Metrics Row (Height, Weight, Goal)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHealthMetric(
                            "Height",
                            "$_height",
                            "cm",
                            () => _showEditDialog("Update Height", "$_height", (
                              val,
                            ) {
                              if (val.isNotEmpty) {
                                setState(() => _height = int.parse(val));
                              }
                            }),
                          ),
                          _buildHealthMetric(
                            "Weight",
                            "$_weight",
                            "kg",
                            () => _showEditDialog("Update Weight", "$_weight", (
                              val,
                            ) {
                              if (val.isNotEmpty) {
                                setState(() => _weight = double.parse(val));
                              }
                            }),
                          ),
                          _buildHealthMetric(
                            "Calorie Goal",
                            "$_calorieGoal",
                            "kcal",
                            () => _showEditDialog(
                              "Update Goal",
                              "$_calorieGoal",
                              (val) {
                                if (val.isNotEmpty) {
                                  setState(() => _calorieGoal = int.parse(val));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
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
                    indicatorColor:
                        AppColors.primary, // Simple primary indicator
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
                      Tab(text: "Feed"),
                      Tab(text: "Photos"),
                      Tab(text: "Reviews"),
                      Tab(text: "Completed"),
                    ],
                  ),
                ),
                pinned: true,
              ),

              // Placeholder Feed Content
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Container(
                    height: 100,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Feed Item #$index",
                      style: const TextStyle(color: Colors.white54),
                    ),
                  );
                }, childCount: 5),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(
    String label,
    String value,
    String unit,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 28, // Bigger mock
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
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
