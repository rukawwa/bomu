import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/user_profile.dart';
import '../../../theme.dart';
import '../../../widgets/shadcn_components.dart';

class DietStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const DietStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<DietStep> createState() => _DietStepState();
}

class _DietStepState extends State<DietStep> {
  final List<_DietOption> _diets = [
    _DietOption(type: DietType.classic, label: "Klasik", emoji: "🍽️"),
    _DietOption(type: DietType.vegetarian, label: "Vejetaryen", emoji: "🥗"),
    _DietOption(type: DietType.vegan, label: "Vegan", emoji: "🌱"),
    _DietOption(type: DietType.keto, label: "Keto", emoji: "🥩"),
    _DietOption(type: DietType.paleo, label: "Paleo", emoji: "🦴"),
    _DietOption(type: DietType.pescatarian, label: "Pescatarian", emoji: "🐟"),
  ];

  final List<String> _allergies = [
    "Gluten",
    "Süt Ürünleri",
    "Fıstık",
    "Yumurta",
    "Deniz Ürünleri",
    "Soya",
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      title: "Beslenme tercihlerin?",
      subtitle: "Sana uygun yemek önerileri sunalım.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diet Type Section
            const Text(
              "Diyet Tipi",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _diets.map((diet) {
                final isSelected = widget.profile.dietType == diet.type;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => widget.profile.dietType = diet.type);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(diet.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          diet.label,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Allergies Section
            const Text(
              "Alerjiler (varsa seç)",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _allergies.map((allergy) {
                final isSelected = widget.profile.allergies.contains(allergy);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        widget.profile.allergies.remove(allergy);
                      } else {
                        widget.profile.allergies.add(allergy);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.redAccent
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                        Text(
                          allergy,
                          style: TextStyle(
                            color: isSelected ? Colors.redAccent : Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Meals per day
            const Text(
              "Günlük Öğün Sayısı",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [2, 3, 4, 5].map((count) {
                final isSelected = widget.profile.mealsPerDay == count;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => widget.profile.mealsPerDay = count);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: count < 5 ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "$count",
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DietOption {
  final DietType type;
  final String label;
  final String emoji;

  _DietOption({required this.type, required this.label, required this.emoji});
}
