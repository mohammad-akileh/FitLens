// lib/utils/calculator.dart

class Calculator {
  
  // 1. Calculate BMR (Mifflin-St Jeor Equation)
  // The "Gold Standard" for resting calories.
  static double calculateBMR({
    required int heightCm,
    required int weightKg,
    required int age,
    required String gender, // 'male' or 'female'
  }) {
    double base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    
    if (gender.toLowerCase() == 'male') {
      return base + 5;
    } else {
      return base - 161;
    }
  }

  // 2. Calculate TDEE (Total Daily Energy Expenditure)
  // This adds your movement. 
  // activityMultiplier:
  // 1.2 = Sedentary (Desk job)
  // 1.375 = Light Exercise (1-3 days/week)
  // 1.55 = Moderate Exercise (3-5 days/week)
  // 1.725 = Heavy Exercise (6-7 days/week)
  static double calculateTargetCalories(double bmr, {double activityMultiplier = 1.375}) {
    return bmr * activityMultiplier;
  }

  // 3. Calculate Macros (Based on Goal)
  // Standard (Maintenance): 50% Carb, 30% Prot, 20% Fat
  // Muscle (High Protein): 40% Carb, 40% Prot, 20% Fat
  // Weight Loss (Lower Carb): 40% Carb, 35% Prot, 25% Fat
  static Map<String, double> calculateMacros(double dailyCalories, {String goal = 'maintain'}) {
    double carbPct, protPct, fatPct;

    if (goal == 'muscle') {
      carbPct = 0.40; protPct = 0.40; fatPct = 0.20;
    } else if (goal == 'loss') {
      carbPct = 0.40; protPct = 0.35; fatPct = 0.25;
    } else {
      // Default / Maintain
      carbPct = 0.50; protPct = 0.30; fatPct = 0.20;
    }

    return {
      'protein': (dailyCalories * protPct) / 4, // 1g Prot = 4 kcal
      'carb': (dailyCalories * carbPct) / 4,    // 1g Carb = 4 kcal
      'fat': (dailyCalories * fatPct) / 9,      // 1g Fat = 9 kcal
    };
  }

  // 4. Calculate Water Need (The Scientific Formula) 💧
  // Base: 33ml per kg of body weight.
  // Plus: 0.5 Liters for every hour of exercise.
  static double calculateWater({required int weightKg, double exerciseHours = 0}) {
    // Step 1: Base need (Weight * 0.033 Liters)
    double baseWater = weightKg * 0.033; 
    
    // Step 2: Add water for sweat (0.5L per hour of workout)
    double extraWater = exerciseHours * 0.5;

    return baseWater + extraWater;
  }
}
