import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../theme.dart';

// --- BASE STEP WIDGET ---
class BaseStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget content;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const BaseStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Icon(Icons.arrow_back, color: Colors.white54),
              ),
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.white54),
          ),
          const SizedBox(height: 32),
          Expanded(child: SingleChildScrollView(child: content)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Devam Et",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- STEP 1: BIO ---
class BioStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;

  const BioStep({super.key, required this.profile, required this.onNext});

  @override
  State<BioStep> createState() => _BioStepState();
}

class _BioStepState extends State<BioStep> {
  @override
  Widget build(BuildContext context) {
    return BaseStep(
      title: "Seni Tanıyalım",
      subtitle: "Doğru hesaplama için biyolojik verilerine ihtiyacımız var.",
      onNext: widget.onNext,
      content: Column(
        children: [
          // Gender
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(Gender.male, "Erkek", Icons.male),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderCard(Gender.female, "Kadın", Icons.female),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Age
          _buildSlider(
            "Yaş",
            widget.profile.age.toDouble(),
            18,
            100,
            (val) => setState(() => widget.profile.age = val.toInt()),
          ),
          const SizedBox(height: 24),
          // Height
          _buildSlider(
            "Boy (cm)",
            widget.profile.heightCm,
            140,
            220,
            (val) => setState(() => widget.profile.heightCm = val),
          ),
          const SizedBox(height: 24),
          // Weight
          _buildSlider(
            "Kilo (kg)",
            widget.profile.weightKg,
            40,
            150,
            (val) => setState(() => widget.profile.weightKg = val),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(Gender gender, String label, IconData icon) {
    final isSelected = widget.profile.gender == gender;
    return GestureDetector(
      onTap: () => setState(() => widget.profile.gender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white10,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.primary : Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              value.toInt().toString(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppColors.primary,
          inactiveColor: Colors.white10,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// --- STEP 2: ACTIVITY ---
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
  @override
  Widget build(BuildContext context) {
    return BaseStep(
      title: "Günlük Tempon",
      subtitle: "Gün içinde ne kadar aktifsin?",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Aktivite Seviyesi",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActivityOption(
            ActivityLevel.sedentary,
            "Masa Başı",
            "Neredeyse hiç kalkmam",
            "🧑‍💻",
          ),
          _buildActivityOption(
            ActivityLevel.lightlyActive,
            "Hafif Hareketli",
            "Öğretmen, Satış vb.",
            "🚶",
          ),
          _buildActivityOption(
            ActivityLevel.moderatelyActive,
            "Aktif",
            "Garson, Kurye vb.",
            "🏃",
          ),
          _buildActivityOption(
            ActivityLevel.veryActive,
            "Çok Ağır",
            "İnşaat, Sporcu vb.",
            "🏋️",
          ),

          const SizedBox(height: 32),
          const Text(
            "Haftalık Spor",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [0, 2, 4, 6].map((e) => _buildSportOption(e)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityOption(
    ActivityLevel level,
    String title,
    String subtitle,
    String emoji,
  ) {
    final isSelected = widget.profile.activityLevel == level;
    return GestureDetector(
      onTap: () => setState(() => widget.profile.activityLevel = level),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white10,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportOption(int count) {
    final isSelected = widget.profile.exerciseFrequency == count;
    return GestureDetector(
      onTap: () => setState(() => widget.profile.exerciseFrequency = count),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          count == 6 ? "5+" : "$count",
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// --- STEP 3: GOALS ---
class GoalStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const GoalStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<GoalStep> {
  @override
  Widget build(BuildContext context) {
    return BaseStep(
      title: "Hedefin Ne?",
      subtitle: "Sana özel bir plan oluşturacağız.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: Column(
        children: [
          _buildGoalOption(GoalType.lose, "Kilo Vermek", "📉"),
          _buildGoalOption(GoalType.maintain, "Kilomu Korumak", "🛡️"),
          _buildGoalOption(GoalType.gain, "Kas Yapmak", "💪"),

          const SizedBox(height: 32),
          if (widget.profile.goal != GoalType.maintain) ...[
            const Text(
              "Hedef Hızı",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSpeedOption(GoalSpeed.slow, "Yavaş & Sürdürülebilir", "🐢"),
            _buildSpeedOption(GoalSpeed.moderate, "Orta Hız", "🐇"),
            _buildSpeedOption(GoalSpeed.aggressive, "Agresif", "🐆"),

            if (widget.profile.goalSpeed == GoalSpeed.aggressive)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Bu modda enerjin düşebilir, emin misin?",
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalOption(GoalType type, String title, String emoji) {
    final isSelected = widget.profile.goal == type;
    return GestureDetector(
      onTap: () => setState(() => widget.profile.goal = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white10,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedOption(GoalSpeed speed, String title, String emoji) {
    final isSelected = widget.profile.goalSpeed == speed;
    return GestureDetector(
      onTap: () => setState(() => widget.profile.goalSpeed = speed),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(color: isSelected ? Colors.black : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// --- STEP 4: NUTRITION ---
class NutritionStep extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const NutritionStep({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<NutritionStep> createState() => _NutritionStepState();
}

class _NutritionStepState extends State<NutritionStep> {
  final List<String> _commonAllergies = [
    "Gluten",
    "Süt",
    "Fıstık",
    "Yumurta",
    "Deniz Ürünleri",
  ];

  @override
  Widget build(BuildContext context) {
    return BaseStep(
      title: "Beslenme Tercihlerin",
      subtitle: "AI sana ne önermeli?",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Diyet Tipi",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DietType.values.map((e) => _buildDietChip(e)).toList(),
          ),

          const SizedBox(height: 32),
          const Text(
            "Alerjiler / Sevilmeyenler",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonAllergies
                .map((e) => _buildAllergyChip(e))
                .toList(),
          ),

          const SizedBox(height: 32),
          const Text(
            "Öğün Sayısı",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [2, 3, 4, 5].map((e) => _buildMealOption(e)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDietChip(DietType type) {
    final isSelected = widget.profile.dietType == type;
    return FilterChip(
      label: Text(type.name.toUpperCase()),
      selected: isSelected,
      onSelected: (val) => setState(() => widget.profile.dietType = type),
      backgroundColor: Colors.white10,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildAllergyChip(String allergy) {
    final isSelected = widget.profile.allergies.contains(allergy);
    return FilterChip(
      label: Text(allergy),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          if (val) {
            widget.profile.allergies.add(allergy);
          } else {
            widget.profile.allergies.remove(allergy);
          }
        });
      },
      backgroundColor: Colors.white10,
      selectedColor: Colors.redAccent,
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildMealOption(int count) {
    final isSelected = widget.profile.mealsPerDay == count;
    return GestureDetector(
      onTap: () => setState(() => widget.profile.mealsPerDay = count),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: isSelected ? AppColors.primary : Colors.white10,
        child: Text(
          "$count",
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// --- STEP 5: PSYCHOLOGY ---
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
    "Düzensiz Saatler",
    "Su İçmemek",
    "Gece Atıştırması",
  ];

  @override
  Widget build(BuildContext context) {
    return BaseStep(
      title: "Zihniyet & Motivasyon",
      subtitle: "Sana en uygun koçluk tarzını belirleyelim.",
      onNext: widget.onNext,
      onBack: widget.onBack,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "En Büyük Zorluğun",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._challenges.map((e) => _buildChallengeOption(e)),

          const SizedBox(height: 32),
          const Text(
            "Koçluk Tarzı",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCoachOption(
                  CoachingStyle.strict,
                  "Disiplinli",
                  "🤖",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCoachOption(
                  CoachingStyle.supportive,
                  "Destekleyici",
                  "🤝",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeOption(String challenge) {
    final isSelected = widget.profile.mainChallenge == challenge;
    return GestureDetector(
      onTap: () => setState(() => widget.profile.mainChallenge = challenge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white10,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : Colors.white54,
            ),
            const SizedBox(width: 12),
            Text(challenge, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachOption(CoachingStyle style, String title, String emoji) {
    final isSelected = widget.profile.coachingStyle == style;
    return GestureDetector(
      onTap: () => setState(() => widget.profile.coachingStyle = style),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
