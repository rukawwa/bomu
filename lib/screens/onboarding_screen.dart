import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import 'onboarding/steps/name_step.dart';
import 'onboarding/steps/age_step.dart';
import 'onboarding/steps/height_step.dart';
import 'onboarding/steps/weight_step.dart';
import 'onboarding/steps/gender_step.dart';
import 'onboarding/steps/activity_step.dart';
import 'onboarding/steps/goal_step.dart';
import 'onboarding/steps/diet_step.dart';
import 'onboarding/steps/calorie_step.dart';
import 'onboarding/value_proposition_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 9;

  // Data State
  final UserProfile _userProfile = UserProfile();

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Go to Value Proposition Screen (replaces Magic Moment)
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ValuePropositionScreen(userProfile: _userProfile),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(_totalPages, (index) {
                  final isCompleted = index < _currentPage;
                  final isCurrent = index == _currentPage;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primary
                              : isCurrent
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  // Step 1: Name
                  NameStep(profile: _userProfile, onNext: _nextPage),

                  // Step 2: Age
                  AgeStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),

                  // Step 3: Height
                  HeightStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),

                  // Step 4: Weight
                  WeightStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),

                  // Step 5: Gender
                  GenderStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),

                  // Step 6: Activity Level
                  ActivityStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),

                  // Step 7: Goal
                  GoalStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),

                  // Step 8: Diet
                  DietStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),

                  // Step 9: Calorie Summary (replaces Psychology)
                  CalorieStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
