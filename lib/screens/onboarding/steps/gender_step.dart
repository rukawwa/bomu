import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

class GenderStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const GenderStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends State<GenderStep> {
  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      title: "Cinsiyetin nedir?",
      subtitle: "Metabolizma hesaplaması cinsiyete göre farklılık gösterir.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: Center(
        child: Row(
          children: [
            Expanded(
              child: _buildGenderCard(
                gender: Gender.male,
                icon: Icons.male_rounded,
                label: "Erkek",
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderCard(
                gender: Gender.female,
                icon: Icons.female_rounded,
                label: "Kadın",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard({
    required Gender gender,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.profile.gender == gender;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => widget.profile.gender = gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        height: 220,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 3 : 1, // Thicker border for selection
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              scale: isSelected ? 1.15 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 20,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                letterSpacing: -0.5,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
