// lib/utils/calculator.dart

class Calculator {

  // 1. Calculate BMR (Mifflin-St Jeor Equation)
  static double calculateBMR({
    required double heightCm, // CHANGED TO DOUBLE
    required double weightKg, // CHANGED TO DOUBLE
    required int age,
    required bool isMale,     // CHANGED TO BOOL
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

  // 3. Calculate Macros
  static Map<String, double> calculateMacros(double dailyCalories, {String goal = 'maintain', String dietType = 'standard'}) {
    double carbPct, protPct, fatPct;

    if (dietType.toLowerCase() == 'keto') {
      carbPct = 0.05; protPct = 0.25; fatPct = 0.70;
    } else if (dietType.toLowerCase() == 'high protein') {
      carbPct = 0.35; protPct = 0.45; fatPct = 0.20;
    } else if (dietType.toLowerCase() == 'vegan') {
      carbPct = 0.55; protPct = 0.20; fatPct = 0.25;
    } else {
      // Standard
      carbPct = 0.50; protPct = 0.30; fatPct = 0.20;
    }

    return {
      'protein': (dailyCalories * protPct) / 4,
      'carb': (dailyCalories * carbPct) / 4,
      'fat': (dailyCalories * fatPct) / 9,
    };
  }

  // 4. Calculate Water Need
  static double calculateWater({required double weightKg, double exerciseHours = 0}) { // Changed weightKg to double
    double baseWater = weightKg * 0.033;
    double extraWater = exerciseHours * 0.5;
    return baseWater + extraWater;
  }
}