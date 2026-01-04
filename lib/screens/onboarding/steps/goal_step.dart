import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

enum BmiCategory { underweight, normal, overweight, obese }

class GoalStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const GoalStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<GoalStep> {
  late FixedExtentScrollController _scrollController;
  late List<_GoalOption> _availableGoals;

  @override
  void initState() {
    super.initState();
    _availableGoals = _getGoalsForBmi();
    final initialIndex = _availableGoals.indexWhere(
      (g) => g.type == widget.profile.goal && g.isEnabled,
    );
    _scrollController = FixedExtentScrollController(
      initialItem: initialIndex >= 0 ? initialIndex : 0,
    );

    // Set default goal if current one is disabled
    if (initialIndex < 0 && _availableGoals.isNotEmpty) {
      final firstEnabled = _availableGoals.indexWhere((g) => g.isEnabled);
      if (firstEnabled >= 0) {
        widget.profile.goal = _availableGoals[firstEnabled].type;
      }
    }
  }

  double get _bmi {
    final heightM = widget.profile.heightCm / 100;
    return widget.profile.weightKg / (heightM * heightM);
  }

  BmiCategory get _bmiCategory {
    if (_bmi < 18.5) return BmiCategory.underweight;
    if (_bmi < 25) return BmiCategory.normal;
    if (_bmi < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  List<_GoalOption> _getGoalsForBmi() {
    final category = _bmiCategory;

    switch (category) {
      case BmiCategory.underweight:
        return [
          _GoalOption(
            type: GoalType.gain,
            emoji: "💪",
            title: "Kas Yap",
            description: "Sağlıklı kilo al",
            isEnabled: true,
          ),
          _GoalOption(
            type: GoalType.maintain,
            emoji: "⚖️",
            title: "Kilomu Koru",
            description: "Mevcut kilonda kal",
            isEnabled: true,
          ),
          _GoalOption(
            type: GoalType.lose,
            emoji: "📉",
            title: "Zayıfla",
            description: "BMI'ın zaten düşük",
            isEnabled: false,
            disabledReason:
                "BMI değerin 18.5'in altında, zayıflamak sağlığına zarar verebilir.",
          ),
        ];
      case BmiCategory.normal:
        return [
          _GoalOption(
            type: GoalType.maintain,
            emoji: "✨",
            title: "Fit Kal",
            description: "İdeal kilondasın!",
            isEnabled: true,
          ),
          _GoalOption(
            type: GoalType.gain,
            emoji: "💪",
            title: "Kas Yap",
            description: "Kas kütlesi kazan",
            isEnabled: true,
          ),
          _GoalOption(
            type: GoalType.lose,
            emoji: "📉",
            title: "Biraz Zayıfla",
            description: "Ekstra yağları eriT",
            isEnabled: true,
          ),
        ];
      case BmiCategory.overweight:
        return [
          _GoalOption(
            type: GoalType.lose,
            emoji: "📉",
            title: "Zayıfla",
            description: "Sağlıklı kiloya dön",
            isEnabled: true,
          ),
          _GoalOption(
            type: GoalType.gain,
            emoji: "💪",
            title: "Kas Yaparak Zayıfla",
            description: "Yağ yak, kas kazan",
            isEnabled: true,
          ),
          _GoalOption(
            type: GoalType.maintain,
            emoji: "⚖️",
            title: "Kilomu Koru",
            description: "Mevcut kilonda kal",
            isEnabled: true,
          ),
        ];
      case BmiCategory.obese:
        return [
          _GoalOption(
            type: GoalType.lose,
            emoji: "📉",
            title: "Zayıfla",
            description: "Sağlığın için önemli",
            isEnabled: true,
          ),
          _GoalOption(
            type: GoalType.gain,
            emoji: "💪",
            title: "Kas Yaparak Zayıfla",
            description: "Metabolizmayı hızlandır",
            isEnabled: true,
          ),
          _GoalOption(
            type: GoalType.maintain,
            emoji: "⚖️",
            title: "Kilomu Koru",
            description: "Önce zayıflamanı öneririz",
            isEnabled: false,
            disabledReason:
                "BMI değerin 30'un üzerinde, önce kilo vermen sağlığın için önemli.",
          ),
        ];
    }
  }

  String get _bmiDescription {
    switch (_bmiCategory) {
      case BmiCategory.underweight:
        return "BMI: ${_bmi.toStringAsFixed(1)} • Zayıf";
      case BmiCategory.normal:
        return "BMI: ${_bmi.toStringAsFixed(1)} • Normal";
      case BmiCategory.overweight:
        return "BMI: ${_bmi.toStringAsFixed(1)} • Fazla Kilolu";
      case BmiCategory.obese:
        return "BMI: ${_bmi.toStringAsFixed(1)} • Obez";
    }
  }

  Color get _bmiColor {
    switch (_bmiCategory) {
      case BmiCategory.underweight:
        return Colors.orangeAccent;
      case BmiCategory.normal:
        return AppColors.primary;
      case BmiCategory.overweight:
        return Colors.orangeAccent;
      case BmiCategory.obese:
        return Colors.redAccent;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      title: "Hedefin nedir?",
      subtitle: "Sana özel seçenekler hazırladık.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: Column(
        children: [
          // BMI Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _bmiColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _bmiColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monitor_weight_outlined, color: _bmiColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  _bmiDescription,
                  style: TextStyle(
                    color: _bmiColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Wheel Picker
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selection highlight
                Container(
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),

                // Wheel
                ListWheelScrollView.useDelegate(
                  controller: _scrollController,
                  itemExtent: 100,
                  perspective: 0.003,
                  diameterRatio: 1.5,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    final goal = _availableGoals[index];
                    if (goal.isEnabled) {
                      HapticFeedback.selectionClick();
                      setState(() => widget.profile.goal = goal.type);
                    } else {
                      // Show disabled message
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            goal.disabledReason ??
                                "Bu seçenek şu an uygun değil.",
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      // Snap back to previous selection
                      final prevIndex = _availableGoals.indexWhere(
                        (g) => g.type == widget.profile.goal,
                      );
                      if (prevIndex >= 0) {
                        _scrollController.animateToItem(
                          prevIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    }
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _availableGoals.length,
                    builder: (context, index) {
                      final goal = _availableGoals[index];
                      final isSelected = widget.profile.goal == goal.type;
                      final isEnabled = goal.isEnabled;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isEnabled ? 1.0 : 0.4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            children: [
                              Text(
                                goal.emoji,
                                style: TextStyle(
                                  fontSize: isSelected ? 40 : 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          goal.title,
                                          style: TextStyle(
                                            fontSize: isSelected ? 20 : 16,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                          ),
                                        ),
                                        if (!isEnabled) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.lock_outline,
                                            size: 16,
                                            color: Colors.white38,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      goal.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Gradient overlays
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background,
                            AppColors.background.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.background,
                            AppColors.background.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOption {
  final GoalType type;
  final String emoji;
  final String title;
  final String description;
  final bool isEnabled;
  final String? disabledReason;

  _GoalOption({
    required this.type,
    required this.emoji,
    required this.title,
    required this.description,
    required this.isEnabled,
    this.disabledReason,
  });
}
