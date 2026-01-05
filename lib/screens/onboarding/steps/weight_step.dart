import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

class WeightStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const WeightStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends State<WeightStep> {
  final double _minWeight = 40;
  final double _maxWeight = 150;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(
      initialItem: (widget.profile.weightKg - _minWeight).round(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      title: "Şu anki kilon?",
      subtitle:
          "Günlük kalori ihtiyacını hesaplamak için kilonu bilmemiz gerekiyor.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final buttonWidthBase = 120.0;
          final availableGrowWidth =
              maxWidth - buttonWidthBase; // Padding handled by layout?

          // Calculate progress 0.0 -> 1.0
          final progress =
              (widget.profile.weightKg - _minWeight) /
              (_maxWeight - _minWeight);

          // Dynamic width calculation
          final currentWidth =
              buttonWidthBase + (availableGrowWidth * progress);

          return Center(
            child: SizedBox(
              height: 300,
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

                  // Wheel Picker
                  ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 60,
                    perspective: 0.003,
                    diameterRatio: 1.5,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        widget.profile.weightKg = _minWeight + index;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: (_maxWeight - _minWeight).toInt() + 1,
                      builder: (context, index) {
                        final weight = _minWeight + index;
                        final isSelected =
                            widget.profile.weightKg.round() == weight;

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
          );
        },
      ),
    );
  }
}
