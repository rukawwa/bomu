enum Gender { male, female }

enum ActivityLevel { sedentary, lightlyActive, moderatelyActive, veryActive }

enum GoalType { lose, maintain, gain }

enum GoalSpeed { slow, moderate, aggressive }

enum CoachingStyle { strict, supportive }

enum DietType { classic, vegetarian, vegan, keto, paleo, pescatarian }

class UserProfile {
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

  UserProfile({
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
  }) : allergies = allergies ?? [],
       dislikedFoods = dislikedFoods ?? [];
}
