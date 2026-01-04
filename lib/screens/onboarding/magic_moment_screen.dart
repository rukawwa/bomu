import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../theme.dart';
import 'value_proposition_screen.dart';

class MagicMomentScreen extends StatefulWidget {
  final UserProfile userProfile;

  const MagicMomentScreen({super.key, required this.userProfile});

  @override
  State<MagicMomentScreen> createState() => _MagicMomentScreenState();
}

class _MagicMomentScreenState extends State<MagicMomentScreen>
    with SingleTickerProviderStateMixin {
  bool _isCalculating = true;
  String _loadingText = "Metabolizma hesaplanıyor...";
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _startCalculation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startCalculation() async {
    // Simulate AI steps
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _loadingText = "Beslenme planı oluşturuluyor...");
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _loadingText = "Makrolar optimize ediliyor...");
    }

    await Future.delayed(const Duration(seconds: 1));

    // Perform "Calculation"
    _calculatePlan();

    if (mounted) {
      setState(() => _isCalculating = false);
      _controller.forward();
    }
  }

  void _calculatePlan() {
    // BMR Calculation (Mifflin-St Jeor)
    double bmr;
    if (widget.userProfile.gender == Gender.male) {
      bmr =
          (10 * widget.userProfile.weightKg) +
          (6.25 * widget.userProfile.heightCm) -
          (5 * widget.userProfile.age) +
          5;
    } else {
      bmr =
          (10 * widget.userProfile.weightKg) +
          (6.25 * widget.userProfile.heightCm) -
          (5 * widget.userProfile.age) -
          161;
    }

    // TDEE Calculation
    double multiplier = 1.2;
    switch (widget.userProfile.activityLevel) {
      case ActivityLevel.sedentary:
        multiplier = 1.2;
        break;
      case ActivityLevel.lightlyActive:
        multiplier = 1.375;
        break;
      case ActivityLevel.moderatelyActive:
        multiplier = 1.55;
        break;
      case ActivityLevel.veryActive:
        multiplier = 1.725;
        break;
    }
    double tdee = bmr * multiplier;

    // Goal Adjustment
    int calorieGoal = tdee.toInt();
    if (widget.userProfile.goal == GoalType.lose) {
      calorieGoal -= 500; // Deficit
      if (widget.userProfile.goalSpeed == GoalSpeed.aggressive) {
        calorieGoal -= 200;
      }
      if (widget.userProfile.goalSpeed == GoalSpeed.slow) {
        calorieGoal += 200;
      }
    } else if (widget.userProfile.goal == GoalType.gain) {
      calorieGoal += 300; // Surplus
    }

    // Macro Split (Simple 30/40/30 rule for now)
    int protein = (calorieGoal * 0.30 / 4).round();
    int carbs = (calorieGoal * 0.40 / 4).round();
    int fat = (calorieGoal * 0.30 / 9).round();

    // Set results
    widget.userProfile.dailyCalorieLimit = calorieGoal;
    widget.userProfile.dailyProteinGoal = protein;
    widget.userProfile.dailyCarbGoal = carbs;
    widget.userProfile.dailyFatGoal = fat;

    // Estimated Date (Mock logic)
    widget.userProfile.estimatedGoalDate = DateTime.now().add(
      const Duration(days: 90),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: _isCalculating ? _buildLoading() : _buildResults()),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 6,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _loadingText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Planın Hazır!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Senin için en uygun rotayı oluşturduk.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Calorie Card
            ScaleTransition(
              scale: _animation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "GÜNLÜK HEDEF",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.userProfile.dailyCalorieLimit}",
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      "kcal",
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Macros
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMacroItem(
                  "Protein",
                  "${widget.userProfile.dailyProteinGoal}g",
                  Colors.purpleAccent,
                ),
                _buildMacroItem(
                  "Karb",
                  "${widget.userProfile.dailyCarbGoal}g",
                  Colors.orangeAccent,
                ),
                _buildMacroItem(
                  "Yağ",
                  "${widget.userProfile.dailyFatGoal}g",
                  Colors.amberAccent,
                ),
              ],
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ValuePropositionScreen(
                        userProfile: widget.userProfile,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Devam Et",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
