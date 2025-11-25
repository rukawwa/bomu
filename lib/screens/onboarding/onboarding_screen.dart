import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../theme.dart';
import 'step_widgets.dart';
import 'magic_moment_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  // Data State
  final UserProfile _userProfile = UserProfile();

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // Go to Magic Moment
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MagicMomentScreen(userProfile: _userProfile),
        ),
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
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
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? AppColors.primary
                              : Colors.white10,
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
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  BioStep(profile: _userProfile, onNext: _nextPage),
                  ActivityStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),
                  GoalStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),
                  NutritionStep(
                    profile: _userProfile,
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),
                  PsychologyStep(
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
