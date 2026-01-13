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
    _DietOption(type: DietType.halal, label: "Helal", emoji: "🕌"),
  ];

  final List<String> _allergies = [
    "Gluten",
    "Kabuklu Deniz Ürünleri",
    "Yumurta",
    "Balık",
    "Fıstık",
    "Soya",
    "Süt (Laktoz)",
    "Kuruyemişler",
    "Kereviz",
    "Hardal",
    "Susam",
    "Sülfitler",
    "Acı Bakla (Lupin)",
    "Yumuşakçalar",
  ];

  bool _isAddingAllergen = false;
  final TextEditingController _allergenController = TextEditingController();
  final FocusNode _allergenFocusNode = FocusNode();

  @override
  void dispose() {
    _allergenController.dispose();
    _allergenFocusNode.dispose();
    super.dispose();
  }

  void _addNewAllergen() {
    final text = _allergenController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        if (!_allergies.contains(text)) {
          // Add to the local display list if not present, though ideally we might want to keep the base list clean
          // But for UX, showing it in the "list" might be confusing if it wasn't there before.
          // However, user just wants to "add" it.
          // Let's add it to the profile directly and also maybe to our local list to show it selected?
          // Actually, the UI iterates over `_allergies`. If I don't add it there, I can't select it easily with the current logic.
          // Let's add it to _allergies so it renders.
          _allergies.add(text);
        }
        if (!widget.profile.allergies.contains(text)) {
          widget.profile.allergies.add(text);
        }
        _isAddingAllergen = false;
        _allergenController.clear();
      });
    } else {
      setState(() {
        _isAddingAllergen = false;
      });
    }
  }

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
              spacing: 12,
              runSpacing: 12,
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
              children: [
                ..._allergies.map((allergy) {
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
                              color: isSelected
                                  ? Colors.redAccent
                                  : Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Add Allergen Chip
                if (_isAddingAllergen)
                  Container(
                    width: 150,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: TextField(
                      controller: _allergenController,
                      focusNode: _allergenFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: "Yaz...",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _addNewAllergen(),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAddingAllergen = true;
                      });
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _allergenFocusNode.requestFocus();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            "Alerjen Ekle",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
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
