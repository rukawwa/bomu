import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

class AgeStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AgeStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  late PageController _pageController;
  final int _minAge = 14;
  final int _maxAge = 99;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.profile.age - _minAge;
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.3,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      title: "Kaç yaşındasın?",
      subtitle: "Metabolizma hızını hesaplamak için yaşını bilmemiz gerekiyor.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: Center(
        child: SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Horizontal Wheel Scroll View (Rotated ListWheelScrollView)
              RotatedBox(
                quarterTurns: -1,
                child: ListWheelScrollView.useDelegate(
                  controller: FixedExtentScrollController(
                    initialItem: widget.profile.age - _minAge,
                  ),
                  itemExtent: 70, // Width of each item when rotated
                  perspective: 0.002,
                  diameterRatio: 1.5,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      widget.profile.age = _minAge + index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _maxAge - _minAge + 1,
                    builder: (context, index) {
                      final age = _minAge + index;
                      final isSelected = widget.profile.age == age;

                      return RotatedBox(
                        quarterTurns: 1,
                        child: OverflowBox(
                          minWidth: 0,
                          maxWidth: double.infinity,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isSelected ? 72 : 32,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.2),
                                letterSpacing: -2,
                                height: 1.0,
                              ),
                              child: Text("$age"),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Glowing Stick Indicator (Horizontal)
              Positioned(
                bottom: 40, // Positioned under the numbers
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
