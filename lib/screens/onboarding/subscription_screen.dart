import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import '../../theme.dart';
import '../main_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final UserProfile userProfile;
  final bool isFromOnboarding;
  final Function(bool isPremium)? onPlanSelected;

  const SubscriptionScreen({
    super.key,
    required this.userProfile,
    this.isFromOnboarding = true,
    this.onPlanSelected,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late bool _isPlusSelected;

  @override
  void initState() {
    super.initState();
    // Default to existing selection if available, else true (Plus)
    _isPlusSelected = widget.userProfile.isPremium;
    // But if coming from onboarding, default to Plus usually
    if (widget.isFromOnboarding) {
      _isPlusSelected = true;
    }
  }

  final List<_Feature> _features = [
    _Feature("Günlük kalori takibi", free: true, plus: true),
    _Feature("Manuel yemek girişi", free: true, plus: true),
    _Feature("Su takibi", free: true, plus: true),
    _Feature("Temel raporlar", free: true, plus: true),
    _Feature("Fotoğraftan kalori hesaplama", free: false, plus: true),
    _Feature("Yazıdan kalori hesaplama", free: false, plus: true),
    _Feature("AI destekli yemek önerileri", free: false, plus: true),
    _Feature("AI yemek tarifleri", free: false, plus: true),
    _Feature("Kişiselleştirilmiş hatırlatmalar", free: false, plus: true),
    _Feature("Detaylı analiz ve grafikler", free: false, plus: true),
    _Feature("Haftalık hedef ayarlama", free: false, plus: true),
    _Feature("Öncelikli destek", free: false, plus: true),
    _Feature("Reklamsız deneyim", free: false, plus: true),
  ];

  // Column highlight color based on selection
  Color get _highlightColor => _isPlusSelected
      ? AppColors.primary.withValues(alpha: 0.15)
      : const Color(0xFF505065).withValues(alpha: 0.5);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // Invisible SliverAppBar to anchor the sticky header
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                toolbarHeight: 56,
                automaticallyImplyLeading: false,
                elevation: 0,
                // Add Close button if not from onboarding
                leading: !widget.isFromOnboarding
                    ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
              ),

              // Header (scrolls with content)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Paketini Seç",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isFromOnboarding
                            ? "İlk haftanız bizden! 🎁"
                            : "İhtiyacına uygun planı belirle",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Plan Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Plus Plan Card
                      _buildPlanCard(
                        title: "Plus",
                        icon: "✨",
                        description:
                            "AI destekli kalori takibi, kişisel öneriler ve daha fazlası",
                        price: "7 gün ücretsiz, sonra ₺79.99/yıl",
                        priceNote: "(₺6.67/ay)",
                        isSelected: _isPlusSelected,
                        isPrimary: true,
                        timeline: [
                          _TimelineItem(
                            "Bugün",
                            "Ücretsiz denemeyi başlat",
                            Icons.lock_open_rounded,
                          ),
                          _TimelineItem(
                            "5. Gün",
                            "Deneme hatırlatması",
                            Icons.notifications_outlined,
                          ),
                          _TimelineItem(
                            "7. Gün",
                            "₺79.99/yıl ödeme",
                            Icons.star_outline_rounded,
                          ),
                        ],
                        onTap: () => setState(() => _isPlusSelected = true),
                      ),

                      const SizedBox(height: 12),

                      // Free Plan Card
                      _buildPlanCard(
                        title: "Free",
                        icon: "🆓",
                        description: "Temel kalori takibi ve su izleme",
                        price: "Ücretsiz",
                        priceNote: "Sonsuza kadar",
                        isSelected: !_isPlusSelected,
                        isPrimary: false,
                        onTap: () => setState(() => _isPlusSelected = false),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Sticky Header for comparison table
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  child: Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.end, // Align children to bottom
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              "Özellikler",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        _buildColumnHeader("Free", !_isPlusSelected),
                        _buildColumnHeader("Plus", _isPlusSelected),
                      ],
                    ),
                  ),
                ),
              ),

              // Feature rows with seamless column backgrounds
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Stack(
                    children: [
                      // Free column background
                      Positioned(
                        right: 60,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: !_isPlusSelected
                                ? _highlightColor
                                : Colors.transparent,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      // Plus column background
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            color: _isPlusSelected
                                ? _highlightColor
                                : Colors.transparent,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      // Content rows
                      Column(
                        children: _features.asMap().entries.map((entry) {
                          final index = entry.key;
                          final feature = entry.value;
                          final isLast = index == _features.length - 1;

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isLast
                                      ? Colors.transparent
                                      : Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Feature name
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        if (!feature.free) ...[
                                          const SparkleIcon(
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Text(
                                            feature.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Free column cell
                                SizedBox(
                                  width: 60,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Center(
                                      child: feature.free
                                          ? const Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Colors.white,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                                // Plus column cell
                                SizedBox(
                                  width: 60,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Center(
                                      child: feature.plus
                                          ? const Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Colors.white,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom spacing for CTA
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),

          // Fixed top nav bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topPadding + 56,
              color: AppColors.background.withValues(
                alpha: 0.0,
              ), // Transparent top
            ),
          ),

          // Bottom CTA with gradient shadow
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background.withValues(alpha: 0.9),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.4, 0.7],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _isPlusSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFEE531B), Color(0xFFFC6C3A)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: _isPlusSelected ? null : const Color(0xFF3A3A4E),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Update profile Subscription Status
                        final updatedProfile = widget.userProfile.copyWith(
                          isPremium: _isPlusSelected,
                        );

                        await UserProfileService.saveProfile(updatedProfile);

                        // Callback if provided
                        if (widget.onPlanSelected != null) {
                          widget.onPlanSelected!(_isPlusSelected);
                        }

                        if (!context.mounted) return;

                        if (widget.isFromOnboarding) {
                          // Standard Onboarding Flow
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MainScreen(userProfile: updatedProfile),
                            ),
                            (route) => false,
                          );
                        } else {
                          // Just pop if called from Profile
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isPlusSelected
                            ? "Planı Seç ve Devam Et"
                            : "Seçimi Kaydet",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String title, bool isSelected) {
    return SizedBox(
      width: 60,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: isSelected ? 16 : 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
          ),
          child: Text(title),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String icon,
    required String description,
    required String price,
    required String priceNote,
    required bool isSelected,
    required bool isPrimary,
    required VoidCallback onTap,
    List<_TimelineItem>? timeline,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 24,
                  )
                else
                  Icon(
                    Icons.circle_outlined,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (timeline != null && isSelected) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: timeline.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              price,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              priceNote,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem {
  final String title;
  final String subtitle;
  final IconData icon;

  _TimelineItem(this.title, this.subtitle, this.icon);
}

class _Feature {
  final String name;
  final bool free;
  final bool plus;

  _Feature(this.name, {required this.free, required this.plus});
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class SparkleIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SparkleIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, size: size, color: color);
  }
}
