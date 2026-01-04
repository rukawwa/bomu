import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

class CalorieStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CalorieStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<CalorieStep> createState() => _CalorieStepState();
}

class _CalorieStepState extends State<CalorieStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _calculateCalories();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Mifflin-St Jeor Equation for BMR
  double get _bmr {
    final weight = widget.profile.weightKg;
    final height = widget.profile.heightCm;
    final age = widget.profile.age;

    if (widget.profile.gender == Gender.male) {
      // Men: BMR = 10 * weight(kg) + 6.25 * height(cm) - 5 * age + 5
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      // Women: BMR = 10 * weight(kg) + 6.25 * height(cm) - 5 * age - 161
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  /// Activity multiplier for TDEE
  double get _activityMultiplier {
    switch (widget.profile.activityLevel) {
      case ActivityLevel.sedentary:
        return 1.2; // Little or no exercise
      case ActivityLevel.lightlyActive:
        return 1.375; // Light exercise 1-3 days/week
      case ActivityLevel.moderatelyActive:
        return 1.55; // Moderate exercise 3-5 days/week
      case ActivityLevel.veryActive:
        return 1.725; // Hard exercise 6-7 days/week
    }
  }

  /// Total Daily Energy Expenditure
  double get _tdee => _bmr * _activityMultiplier;

  /// Goal-adjusted calories
  int get _dailyCalories {
    double calories = _tdee;

    switch (widget.profile.goal) {
      case GoalType.lose:
        // 500 calorie deficit for ~0.5kg/week loss
        calories -= 500;
        break;
      case GoalType.gain:
        // 300 calorie surplus for lean muscle gain
        calories += 300;
        break;
      case GoalType.maintain:
        // No adjustment
        break;
    }

    // Never go below 1200 for safety
    return calories.clamp(1200, 5000).round();
  }

  void _calculateCalories() {
    // Save to profile
    widget.profile.dailyCalorieLimit = _dailyCalories;

    // Also calculate macros (simple 30/40/30 split)
    widget.profile.dailyProteinGoal = (_dailyCalories * 0.30 / 4).round();
    widget.profile.dailyCarbGoal = (_dailyCalories * 0.40 / 4).round();
    widget.profile.dailyFatGoal = (_dailyCalories * 0.30 / 9).round();
  }

  String get _goalLabel {
    switch (widget.profile.goal) {
      case GoalType.lose:
        return "Zayıflamak için";
      case GoalType.gain:
        return "Kas yapmak için";
      case GoalType.maintain:
        return "Kilomu korumak için";
    }
  }

  String get _activityLabel {
    switch (widget.profile.activityLevel) {
      case ActivityLevel.sedentary:
        return "Masa başı";
      case ActivityLevel.lightlyActive:
        return "Az hareketli";
      case ActivityLevel.moderatelyActive:
        return "Aktif";
      case ActivityLevel.veryActive:
        return "Çok aktif";
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      title: "Günlük kalori\nihtiyacın",
      subtitle: "Verilerine göre hesapladık.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      buttonLabel: "Başla!",
      content: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Column(
            children: [
              const SizedBox(height: 16),

              // Main Calorie Card
              Transform.scale(
                scale: 0.8 + (0.2 * _animation.value),
                child: Opacity(
                  opacity: _animation.value,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _goalLabel.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: _dailyCalories),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Text(
                              "$value",
                              style: const TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                                letterSpacing: -2,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "kcal / gün",
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Breakdown
              _buildBreakdownItem(
                icon: Icons.monitor_weight_outlined,
                label: "Bazal metabolizma",
                value: "${_bmr.round()} kcal",
                delay: 0.2,
              ),
              _buildBreakdownItem(
                icon: Icons.directions_run,
                label: "Aktivite seviyesi",
                value:
                    "$_activityLabel (×${_activityMultiplier.toStringAsFixed(2)})",
                delay: 0.4,
              ),
              _buildBreakdownItem(
                icon: Icons.flag_outlined,
                label: "Hedef ayarlaması",
                value: widget.profile.goal == GoalType.lose
                    ? "-500 kcal"
                    : widget.profile.goal == GoalType.gain
                    ? "+300 kcal"
                    : "±0 kcal",
                delay: 0.6,
              ),

              const SizedBox(height: 24),

              // Macros preview
              Opacity(
                opacity: _animation.value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMacroChip(
                      "Protein",
                      "${widget.profile.dailyProteinGoal}g",
                      Colors.purpleAccent,
                    ),
                    _buildMacroChip(
                      "Karb",
                      "${widget.profile.dailyCarbGoal}g",
                      Colors.orangeAccent,
                    ),
                    _buildMacroChip(
                      "Yağ",
                      "${widget.profile.dailyFatGoal}g",
                      Colors.amberAccent,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBreakdownItem({
    required IconData icon,
    required String label,
    required String value,
    required double delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: (800 + (delay * 500)).toInt()),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
