import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/food_log_service.dart';
import '../../theme.dart';

import '../../models/food_entry.dart';
import '../../models/user_profile.dart';

class StatisticsTab extends StatefulWidget {
  final List<FoodEntry> todayEntries;
  final UserProfile userProfile;

  const StatisticsTab({
    super.key,
    required this.todayEntries,
    required this.userProfile,
  });

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  List<DailyStats> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(StatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todayEntries != widget.todayEntries ||
        oldWidget.userProfile != widget.userProfile) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final history = await FoodLogService.loadHistory();

    // Merge today's in-memory data
    final today = DateTime.now();
    final todayCals = widget.todayEntries.fold<int>(
      0,
      (sum, e) => sum + e.calories,
    );

    // Remove existing today entry from disk history if any (to use fresh memory data)
    history.removeWhere(
      (e) =>
          e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day,
    );

    // Add current status
    history.add(
      DailyStats(
        date: today,
        totalCalories: todayCals,
        weight: widget.userProfile.weightKg,
      ),
    );

    // Sort by date
    history.sort((a, b) => a.date.compareTo(b.date));

    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              "Henüz veri yok",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Yemek ekledikçe istatistiklerin burada görünecek.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Get last 7 days or more
    final recentHistory = _history.length > 7
        ? _history.sublist(_history.length - 7)
        : _history;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionTitle("Kalori Geçmişi (Son 7 Gün)"),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Dark card
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: CustomPaint(
            painter: CalorieChartPainter(
              data: recentHistory,
              barColor: AppColors.primary,
              targetLineColor: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),

        const SizedBox(height: 32),

        _buildSectionTitle("Kilo Değişimi"),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: CustomPaint(
            painter: WeightChartPainter(
              data:
                  _history, // Use full history for weight trend? Or recent? Let's use full for now or last 30
              // Ideally pass scrollable implementation but for now static
              lineColor: const Color(0xFF4ADE80), // Greenish
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// --- PAINTERS ---

class CalorieChartPainter extends CustomPainter {
  final List<DailyStats> data;
  final Color barColor;
  final Color targetLineColor;

  CalorieChartPainter({
    required this.data,
    required this.barColor,
    required this.targetLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final maxCals = data.map((e) => e.totalCalories).reduce(math.max);
    // Add some buffer to top
    final maxY = maxCals * 1.2;
    // Assuming target is around 2000 for visuals (could pass actual target)

    final barWidth = size.width / (data.length * 2 + 1);
    final spacing = barWidth;

    double startX = spacing;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      final heightRatio = entry.totalCalories / maxY;
      final barHeight = size.height * heightRatio;

      final rect = Rect.fromLTWH(
        startX,
        size.height - barHeight,
        barWidth,
        barHeight,
      );

      // Gradient Bar
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [barColor.withValues(alpha: 0.6), barColor],
      );
      paint.shader = gradient.createShader(rect);

      // Draw Bar
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rrect, paint);

      // Draw Date Label below? (Need TextPainter)
      // Simplifying for MVP: Just bars.

      startX += barWidth + spacing;
    }

    // Draw Target Line
    /*
    final targetY = size.height - (target / maxY * size.height);
    final linePaint = Paint()
      ..color = targetLineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..pathEffect = PathEffect.dashPath(
          Path()..addRect(const Rect.fromLTWH(0, 0, 4, 4)), 
          circular: 4, 
          dashArray: CircularIntervalList<double>([4, 4]) // Need package? No standard dash is hard in flutter raw.
      ); 
    // Standard dash line manually:
    double dashX = 0;
    while (dashX < size.width) {
      canvas.drawLine(
        Offset(dashX, targetY), 
        Offset(dashX + 4, targetY), 
        Paint()..color = targetLineColor..strokeWidth = 1
      );
      dashX += 8;
    }
    */
  }

  @override
  bool shouldRepaint(covariant CalorieChartPainter oldDelegate) => true;
}

class WeightChartPainter extends CustomPainter {
  final List<DailyStats> data;
  final Color lineColor;

  WeightChartPainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Filter out 0 weights // Or handle gaps?
    final validData = data.where((e) => e.weight > 0).toList();
    if (validData.length < 2) return; // Need at least 2 points for a line

    final minWeight = validData.map((e) => e.weight).reduce(math.min) - 2;
    final maxWeight = validData.map((e) => e.weight).reduce(math.max) + 2;
    final range = maxWeight - minWeight;

    final path = Path();
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round; // Round joins

    final stepX = size.width / (validData.length - 1);

    for (var i = 0; i < validData.length; i++) {
      final entry = validData[i];
      final normalizedY = (entry.weight - minWeight) / range;
      // Invert Y because canvas 0 is top
      final y = size.height - (normalizedY * size.height);
      final x = i * stepX;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Cubic bezier for smoothness? Or just lineTo
        // For simple implementation: lineTo
        path.lineTo(x, y);
      }

      // Draw dot
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
    }

    canvas.drawPath(path, paint);

    // Area below?
  }

  @override
  bool shouldRepaint(covariant WeightChartPainter oldDelegate) => true;
}
