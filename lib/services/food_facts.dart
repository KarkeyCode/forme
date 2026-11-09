/// Nutrition breakdown for a logged food item. For a handful of common foods
/// we use realistic per-serving values; for anything else we estimate the
/// macros from the calorie count. (A Gemini-backed lookup can replace
/// [factsFor] later — see AI_SETUP.md.)
class FoodFacts {
  const FoodFacts({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    this.estimated = false,
    this.micros = const {},
    this.servingNote,
  });

  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final bool estimated; // true when derived from calories, not a known value
  final Map<String, String> micros; // e.g. {'Potassium': '422 mg'}
  final String? servingNote;
}

// A small known-foods table (per typical serving).
const _known = <String, FoodFacts>{
  'banana': FoodFacts(
    kcal: 105, proteinG: 1.3, carbsG: 27, fatG: 0.4, fiberG: 3.1,
    servingNote: '1 medium (118 g)',
    micros: {'Sugars': '14 g', 'Potassium': '422 mg', 'Vitamin C': '10 mg', 'Vitamin B6': '0.4 mg'},
  ),
  'oatmeal': FoodFacts(
    kcal: 150, proteinG: 5, carbsG: 27, fatG: 2.5, fiberG: 4,
    servingNote: '1 cup cooked (234 g)',
    micros: {'Sugars': '1 g', 'Iron': '2 mg', 'Magnesium': '63 mg'},
  ),
  'chicken': FoodFacts(
    kcal: 335, proteinG: 38, carbsG: 10, fatG: 15, fiberG: 3,
    servingNote: 'Grilled chicken salad',
    micros: {'Sodium': '620 mg', 'Vitamin A': '110 µg', 'Iron': '2 mg'},
  ),
  'egg': FoodFacts(
    kcal: 78, proteinG: 6.3, carbsG: 0.6, fatG: 5.3, fiberG: 0,
    servingNote: '1 large (50 g)',
    micros: {'Cholesterol': '186 mg', 'Vitamin D': '1 µg', 'Choline': '147 mg'},
  ),
  'apple': FoodFacts(
    kcal: 95, proteinG: 0.5, carbsG: 25, fatG: 0.3, fiberG: 4.4,
    servingNote: '1 medium (182 g)',
    micros: {'Sugars': '19 g', 'Vitamin C': '8 mg', 'Potassium': '195 mg'},
  ),
  'rice': FoodFacts(
    kcal: 206, proteinG: 4.3, carbsG: 45, fatG: 0.4, fiberG: 0.6,
    servingNote: '1 cup cooked (158 g)',
    micros: {'Manganese': '0.7 mg', 'Magnesium': '19 mg'},
  ),
  'toast': FoodFacts(
    kcal: 75, proteinG: 2.6, carbsG: 13, fatG: 1, fiberG: 1.1,
    servingNote: '1 slice',
    micros: {'Sodium': '147 mg', 'Iron': '0.9 mg'},
  ),
  'coffee': FoodFacts(
    kcal: 5, proteinG: 0.3, carbsG: 0, fatG: 0, fiberG: 0,
    servingNote: '1 cup, black',
    micros: {'Caffeine': '95 mg'},
  ),
  'milk': FoodFacts(
    kcal: 103, proteinG: 8, carbsG: 12, fatG: 2.4, fiberG: 0,
    servingNote: '1 cup, low fat (244 g)',
    micros: {'Calcium': '305 mg', 'Vitamin D': '2.9 µg', 'Sugars': '12 g'},
  ),
  'salad': FoodFacts(
    kcal: 150, proteinG: 5, carbsG: 12, fatG: 9, fiberG: 4,
    servingNote: 'Mixed salad bowl',
    micros: {'Vitamin A': '200 µg', 'Vitamin K': '80 µg'},
  ),
};

FoodFacts factsFor(String label, int kcal) {
  final l = label.toLowerCase();
  for (final entry in _known.entries) {
    if (l.contains(entry.key)) return entry.value;
  }
  // Estimate macros from calories: ~15% protein, 50% carbs, 35% fat.
  final k = kcal.abs();
  double g(double share, double kcalPerG) => (k * share / kcalPerG);
  final carbs = g(0.50, 4);
  return FoodFacts(
    kcal: k,
    proteinG: double.parse(g(0.15, 4).toStringAsFixed(1)),
    carbsG: double.parse(carbs.toStringAsFixed(1)),
    fatG: double.parse(g(0.35, 9).toStringAsFixed(1)),
    fiberG: double.parse((carbs * 0.1).toStringAsFixed(1)),
    estimated: true,
  );
}
