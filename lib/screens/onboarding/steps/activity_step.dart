import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

class ActivityStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ActivityStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ActivityStep> createState() => _ActivityStepState();
}

class _ActivityStepState extends State<ActivityStep> {
  final List<_ActivityOption> _options = [
    _ActivityOption(
      level: ActivityLevel.sedentary,
      emoji: "🧑‍💻",
      title: "Masa Başı",
      description: "Çoğunlukla oturuyorum",
    ),
    _ActivityOption(
      level: ActivityLevel.lightlyActive,
      emoji: "🚶",
      title: "Az Hareketli",
      description: "Günde 1-2 saat ayakta",
    ),
    _ActivityOption(
      level: ActivityLevel.moderatelyActive,
      emoji: "🏃",
      title: "Aktif",
      description: "Günde 3-4 saat hareket",
    ),
    _ActivityOption(
      level: ActivityLevel.veryActive,
      emoji: "🏋️",
      title: "Çok Aktif",
      description: "Fiziksel iş veya yoğun spor",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      title: "Günlük aktivite\nseviyen?",
      subtitle: "Kalori ihtiyacın aktivite düzeyine göre değişir.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final option = _options[index];
          final isSelected = widget.profile.activityLevel == option.level;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => widget.profile.activityLevel = option.level);
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
              child: Row(
                children: [
                  // Emoji
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        option.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Check
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1 : 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 18,
                      ),
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

class _ActivityOption {
  final ActivityLevel level;
  final String emoji;
  final String title;
  final String description;

  _ActivityOption({
    required this.level,
    required this.emoji,
    required this.title,
    required this.description,
  });
}
