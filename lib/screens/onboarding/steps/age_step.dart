import 'package:flutter/material.dart';
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
              // Picker
              PageView.builder(
                controller: _pageController,
                itemCount: _maxAge - _minAge + 1,
                onPageChanged: (index) {
                  setState(() {
                    widget.profile.age = _minAge + index;
                  });
                },
                itemBuilder: (context, index) {
                  final age = _minAge + index;
                  final isSelected = widget.profile.age == age;

                  return Center(
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
                  );
                },
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
