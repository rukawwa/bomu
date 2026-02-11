enum Gender { male, female }

enum ActivityLevel { sedentary, lightlyActive, moderatelyActive, veryActive }

enum GoalType { lose, maintain, gain }

enum GoalSpeed { slow, moderate, aggressive }

enum CoachingStyle { strict, supportive }

enum DietType { classic, vegetarian, vegan, keto, paleo, pescatarian, halal }

class UserProfile {
  // Personal
  String name;

  // Biological
  Gender gender;
  int age;
  double heightCm;
  double weightKg;

  // Lifestyle
  ActivityLevel activityLevel;
  int exerciseFrequency; // 0, 1-2, 3-4, 5+

  // Goals
  GoalType goal;
  GoalSpeed goalSpeed;
  double targetWeight;

  // Preferences
  DietType dietType;
  List<String> allergies;
  List<String> dislikedFoods;
  int mealsPerDay;

  // Psychology
  CoachingStyle coachingStyle;
  String mainChallenge;

  // Calculated Results
  int dailyCalorieLimit;
  int dailyProteinGoal;
  int dailyCarbGoal;
  int dailyFatGoal;
  DateTime? estimatedGoalDate;

  // Subscription
  bool isPremium;

  UserProfile({
    this.name = '',
    this.gender = Gender.male,
    this.age = 25,
    this.heightCm = 175,
    this.weightKg = 75,
    this.activityLevel = ActivityLevel.sedentary,
    this.exerciseFrequency = 0,
    this.goal = GoalType.lose,
    this.goalSpeed = GoalSpeed.moderate,
    this.targetWeight = 70,
    this.dietType = DietType.classic,
    List<String>? allergies,
    List<String>? dislikedFoods,
    this.mealsPerDay = 3,
    this.coachingStyle = CoachingStyle.supportive,
    this.mainChallenge = "Snacking",
    this.dailyCalorieLimit = 2000,
    this.dailyProteinGoal = 150,
    this.dailyCarbGoal = 200,
    this.dailyFatGoal = 65,
    this.estimatedGoalDate,
    this.isPremium = false,
  }) : allergies = allergies ?? [],
       dislikedFoods = dislikedFoods ?? [];

  /// Creates a deep copy of this profile
  UserProfile copyWith({
    String? name,
    Gender? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    int? exerciseFrequency,
    GoalType? goal,
    GoalSpeed? goalSpeed,
    double? targetWeight,
    DietType? dietType,
    List<String>? allergies,
    List<String>? dislikedFoods,
    int? mealsPerDay,
    CoachingStyle? coachingStyle,
    String? mainChallenge,
    int? dailyCalorieLimit,
    int? dailyProteinGoal,
    int? dailyCarbGoal,
    int? dailyFatGoal,
    DateTime? estimatedGoalDate,
    bool? isPremium,
  }) {
    return UserProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      goal: goal ?? this.goal,
      goalSpeed: goalSpeed ?? this.goalSpeed,
      targetWeight: targetWeight ?? this.targetWeight,
      dietType: dietType ?? this.dietType,
      allergies: allergies ?? List<String>.from(this.allergies),
      dislikedFoods: dislikedFoods ?? List<String>.from(this.dislikedFoods),
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      coachingStyle: coachingStyle ?? this.coachingStyle,
      mainChallenge: mainChallenge ?? this.mainChallenge,
      dailyCalorieLimit: dailyCalorieLimit ?? this.dailyCalorieLimit,
      dailyProteinGoal: dailyProteinGoal ?? this.dailyProteinGoal,
      dailyCarbGoal: dailyCarbGoal ?? this.dailyCarbGoal,
      dailyFatGoal: dailyFatGoal ?? this.dailyFatGoal,
      estimatedGoalDate: estimatedGoalDate ?? this.estimatedGoalDate,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  /// Serializes to JSON-compatible map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender.name,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel.name,
      'exerciseFrequency': exerciseFrequency,
      'goal': goal.name,
      'goalSpeed': goalSpeed.name,
      'targetWeight': targetWeight,
      'dietType': dietType.name,
      'allergies': allergies,
      'dislikedFoods': dislikedFoods,
      'mealsPerDay': mealsPerDay,
      'coachingStyle': coachingStyle.name,
      'mainChallenge': mainChallenge,
      'dailyCalorieLimit': dailyCalorieLimit,
      'dailyProteinGoal': dailyProteinGoal,
      'dailyCarbGoal': dailyCarbGoal,
      'dailyFatGoal': dailyFatGoal,
      'estimatedGoalDate': estimatedGoalDate?.toIso8601String(),
      'isPremium': isPremium,
    };
  }

  /// Deserializes from JSON-compatible map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      gender: Gender.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => Gender.male,
      ),
      age: json['age'] as int? ?? 25,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 175,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 75,
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.name == json['activityLevel'],
        orElse: () => ActivityLevel.sedentary,
      ),
      exerciseFrequency: json['exerciseFrequency'] as int? ?? 0,
      goal: GoalType.values.firstWhere(
        (e) => e.name == json['goal'],
        orElse: () => GoalType.lose,
      ),
      goalSpeed: GoalSpeed.values.firstWhere(
        (e) => e.name == json['goalSpeed'],
        orElse: () => GoalSpeed.moderate,
      ),
      targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? 70,
      dietType: DietType.values.firstWhere(
        (e) => e.name == json['dietType'],
        orElse: () => DietType.classic,
      ),
      allergies:
          (json['allergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dislikedFoods:
          (json['dislikedFoods'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      mealsPerDay: json['mealsPerDay'] as int? ?? 3,
      coachingStyle: CoachingStyle.values.firstWhere(
        (e) => e.name == json['coachingStyle'],
        orElse: () => CoachingStyle.supportive,
      ),
      mainChallenge: json['mainChallenge'] as String? ?? 'Snacking',
      dailyCalorieLimit: json['dailyCalorieLimit'] as int? ?? 2000,
      dailyProteinGoal: json['dailyProteinGoal'] as int? ?? 150,
      dailyCarbGoal: json['dailyCarbGoal'] as int? ?? 200,
      dailyFatGoal: json['dailyFatGoal'] as int? ?? 65,
      estimatedGoalDate: json['estimatedGoalDate'] != null
          ? DateTime.tryParse(json['estimatedGoalDate'] as String)
          : null,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }
}
