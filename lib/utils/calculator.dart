// lib/utils/calculator.dart

class Calculator {

  // 1. Calculate BMR (Mifflin-St Jeor Equation)
  static double calculateBMR({
    required double heightCm,
    required double weightKg,
    required int age,
    required bool isMale,
  }) {
    double base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);

    if (isMale) {
      return base + 5;
    } else {
      return base - 161;
    }
  }

  // 2. Calculate TDEE
  static double calculateTargetCalories(double bmr, {double activityMultiplier = 1.375}) {
    return bmr * activityMultiplier;
  }

  // 3. Calculate Macros (UPDATED WITH MEDICAL DIETS)
  static Map<String, double> calculateMacros(double dailyCalories, {String goal = 'maintain', String dietType = 'standard'}) {
    double carbPct, protPct, fatPct;

    // Normalize string to handle lowercase checks
    String diet = dietType.toLowerCase();

    if (diet.contains('keto')) {
      // Keto: High Fat, Very Low Carb
      carbPct = 0.05; protPct = 0.25; fatPct = 0.70;
    } else if (diet.contains('high protein')) {
      // Bodybuilder style
      carbPct = 0.35; protPct = 0.45; fatPct = 0.20;
    } else if (diet.contains('vegan')) {
      // Plant-based
      carbPct = 0.55; protPct = 0.20; fatPct = 0.25;
    } else if (diet.contains('diabetes')) {
      // 🩺 DIABETES: Controlled Carbs (35%) to manage blood sugar, Balanced Protein/Fat
      carbPct = 0.35; protPct = 0.30; fatPct = 0.35;
    } else if (diet.contains('hypertension') || diet.contains('dash')) {
      // 🩺 DASH DIET: Heart healthy, lower fat, higher fiber carbs
      carbPct = 0.55; protPct = 0.20; fatPct = 0.25;
    } else {
      // Standard / Balanced
      carbPct = 0.50; protPct = 0.30; fatPct = 0.20;
    }

    return {
      'protein': (dailyCalories * protPct) / 4,
      'carb': (dailyCalories * carbPct) / 4,
      'fat': (dailyCalories * fatPct) / 9,
    };
  }

  // 4. Calculate Water Need
  static double calculateWater({required double weightKg, double exerciseHours = 0}) {
    double baseWater = weightKg * 0.033;
    double extraWater = exerciseHours * 0.5;
    return baseWater + extraWater;
  }
}