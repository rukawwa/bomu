import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

class PsychologyStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const PsychologyStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<PsychologyStep> createState() => _PsychologyStepState();
}

class _PsychologyStepState extends State<PsychologyStep> {
  final List<String> _challenges = [
    "Tatlı Krizleri",
    "Porsiyon Kontrolü",
    "Düzensiz Öğünler",
    "Gece Atıştırması",
    "Duygusal Yeme",
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      title: "Son bir adım!",
      subtitle: "En büyük zorluğunu ve tercih ettiğin koçluk tarzını seç.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge Section
            const Text(
              "En Büyük Zorluğun",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_challenges.length, (index) {
              final challenge = _challenges[index];
              final isSelected = widget.profile.mainChallenge == challenge;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => widget.profile.mainChallenge = challenge);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.black,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        challenge,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.7),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 28),

            // Coaching Style Section
            const Text(
              "Koçluk Tarzı",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCoachingCard(
                    style: CoachingStyle.strict,
                    emoji: "🎯",
                    title: "Disiplinli",
                    subtitle: "Sıkı takip",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCoachingCard(
                    style: CoachingStyle.supportive,
                    emoji: "🤗",
                    title: "Destekleyici",
                    subtitle: "Esnek yaklaşım",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachingCard({
    required CoachingStyle style,
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    final isSelected = widget.profile.coachingStyle == style;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => widget.profile.coachingStyle = style);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
