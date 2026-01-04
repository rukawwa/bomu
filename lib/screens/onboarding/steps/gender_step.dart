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
                gradient: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderCard(
                gender: Gender.female,
                icon: Icons.female_rounded,
                label: "Kadın",
                gradient: [const Color(0xFFEC4899), const Color(0xFFBE185D)],
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
    required List<Color> gradient,
  }) {
    final isSelected = widget.profile.gender == gender;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => widget.profile.gender = gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: 200,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 250),
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(
                icon,
                size: 64,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
