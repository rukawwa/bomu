import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../theme.dart';
import '../main_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final UserProfile userProfile;

  const SubscriptionScreen({super.key, required this.userProfile});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isPlusSelected = true;

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
              const SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                toolbarHeight: 56,
                automaticallyImplyLeading: false,
                elevation: 0,
              ),

              // Header (scrolls with content)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "İlk haftanız bizden! 🎁",
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
                        "Planını seç",
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

              SliverToBoxAdapter(child: SizedBox(height: 24)),

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
              color: AppColors.background,
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
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainScreen(
                              initialDailyGoal:
                                  widget.userProfile.dailyCalorieLimit,
                            ),
                          ),
                          (route) => false,
                        );
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
                            ? "Ücretsiz Denemeyi Başlat"
                            : "Ücretsiz Başla",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPlusSelected
                        ? "İstediğin zaman iptal edebilirsin"
                        : "Dilediğin zaman Plus'a yükseltebilirsin",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4),
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
    return Container(
      width: 60,
      height: 48,
      decoration: BoxDecoration(
        color: isSelected ? _highlightColor : Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
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
    List<_TimelineItem>? timeline,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (isPrimary
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          const Color(0xFF505065),
                          const Color(0xFF353545),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ))
              : null,
          color: isPrimary
              ? null
              : (isSelected ? Colors.transparent : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isPrimary ? AppColors.primary : const Color(0xFF505065))
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (title == "Plus")
                  const SparkleIcon(size: 20, color: AppColors.primary)
                else
                  Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (isPrimary) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Önerilen",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Radio
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isPrimary
                                ? AppColors.primary
                                : const Color(0xFF2A2A3E))
                          : Colors.white38,
                      width: 2,
                    ),
                    color: isSelected
                        ? (isPrimary
                              ? AppColors.primary
                              : const Color(0xFF2A2A3E))
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  priceNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),

            // Timeline (only for Plus)
            if (timeline != null && isSelected) ...[
              const SizedBox(height: 20),
              ...timeline.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == timeline.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 24,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "${item.day}: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: item.description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _Feature {
  final String name;
  final bool free;
  final bool plus;

  _Feature(this.name, {required this.free, required this.plus});
}

class _TimelineItem {
  final String day;
  final String description;
  final IconData icon;

  _TimelineItem(this.day, this.description, this.icon);
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: maxExtent, child: child);
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class SparkleIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SparkleIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _SparklePainter(color));
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;

  _SparklePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.5;

    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    // Path 1
    final path1 = Path();
    path1.moveTo(8, 15);
    path1.cubicTo(12.8747, 15, 15, 12.949, 15, 8);
    path1.cubicTo(15, 12.949, 17.1104, 15, 22, 15);
    path1.cubicTo(17.1104, 15, 15, 17.1104, 15, 22);
    path1.cubicTo(15, 17.1104, 12.8747, 15, 8, 15);
    path1.close();
    canvas.drawPath(path1, paint);

    // Path 2
    final path2 = Path();
    path2.moveTo(2, 6.5);
    path2.cubicTo(5.13376, 6.5, 6.5, 5.18153, 6.5, 2);
    path2.cubicTo(6.5, 5.18153, 7.85669, 6.5, 11, 6.5);
    path2.cubicTo(7.85669, 6.5, 6.5, 7.85669, 6.5, 11);
    path2.cubicTo(6.5, 7.85669, 5.13376, 6.5, 2, 6.5);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
