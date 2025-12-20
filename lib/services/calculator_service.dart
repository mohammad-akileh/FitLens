// lib/services/calculator_service.dart
class CalculatorService {

  // 1. Calculate BMR (Mifflin-St Jeor Equation)
  // This is how many calories you burn just by existing (in a coma).
  double calculateBMR({
    required String gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    double bmr;
    if (gender == 'Male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
    return bmr;
  }

  // 2. Calculate Daily Goals based on Activity & GOAL
  Map<String, int> calculateDailyGoals({
    required double bmr,
    required String activityLevel,
    required String goal, // <-- WE NEED THE GOAL HERE
  }) {
    double activityMultiplier;

    // Determine Activity Multiplier
    switch (activityLevel) {
      case 'Sedentary':
        activityMultiplier = 1.2;
        break;
      case 'Light':
        activityMultiplier = 1.375;
        break;
      case 'Moderate':
        activityMultiplier = 1.55; // This is the default we used
        break;
      case 'Active':
        activityMultiplier = 1.725;
        break;
      default:
        activityMultiplier = 1.2;
    }

    // Calculate TDEE (Total Daily Energy Expenditure) - Maintenance Calories
    double tdee = bmr * activityMultiplier;

    // --- THE FIX: ADJUST FOR GOAL ---
    double targetCalories = tdee;

    if (goal == "Lose weight") {
      targetCalories = tdee - 500; // Subtract 500 to lose ~0.5kg/week
    } else if (goal == "Gain weight") {
      targetCalories = tdee + 500; // Add 500 to gain muscle
    }
    // If "Maintain weight", we do nothing (keep tdee)

    // Ensure we don't go dangerously low (Safety Check)
    if (targetCalories < 1200) targetCalories = 1200;

    // --- MACRO SPLIT (Standard Balanced Diet) ---
    // Protein: 25% | Fat: 30% | Carbs: 45%
    // 1g Protein = 4 kcal
    // 1g Fat = 9 kcal
    // 1g Carb = 4 kcal

    int proteinGrams = ((targetCalories * 0.25) / 4).round();
    int fatGrams = ((targetCalories * 0.30) / 9).round();
    int carbsGrams = ((targetCalories * 0.45) / 4).round();

    return {
      'calories': targetCalories.round(),
      'protein': proteinGrams,
      'fat': fatGrams,
      'carbs': carbsGrams,
    };
  }
}