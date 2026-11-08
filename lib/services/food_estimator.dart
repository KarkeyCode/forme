/// Offline calorie estimator: matches keywords in free text against a small
/// food/exercise table and scales by simple quantity words.
class FoodEstimator {
  static const _foods = <String, int>{
    'banana': 105, 'apple': 95, 'orange': 62, 'oatmeal': 300, 'oats': 300,
    'egg': 78, 'toast': 80, 'bread': 80, 'chicken salad': 480, 'salad': 150,
    'chicken': 335, 'rice': 205, 'pasta': 350, 'pizza': 285, 'burger': 550,
    'fries': 365, 'steak': 600, 'salmon': 410, 'tuna': 190, 'yogurt': 150,
    'yoghurt': 150, 'milk': 120, 'coffee': 5, 'latte': 190, 'tea': 2,
    'smoothie': 250, 'protein shake': 160, 'shake': 300, 'avocado': 240,
    'sandwich': 400, 'wrap': 380, 'soup': 200, 'cookie': 160, 'chocolate': 230,
    'ice cream': 270, 'cake': 350, 'beer': 150, 'wine': 125, 'soda': 140,
    'coke': 140, 'chips': 160, 'nuts': 170, 'almonds': 165, 'cereal': 220,
    'pancake': 175, 'bacon': 45, 'sushi': 300, 'noodles': 380, 'burrito': 650,
  };

  // kcal per minute / per km
  static const _exercisePerKm = <String, int>{'ran': 87, 'run': 87, 'walk': 55, 'walked': 55, 'cycl': 30, 'rode': 30};
  static const _exercisePerMin = <String, int>{'gym': 7, 'lift': 6, 'swim': 10, 'yoga': 4, 'hiit': 12, 'workout': 8};

  static const _qty = <String, double>{
    'half': 0.5, 'a ': 1, 'an ': 1, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
    'large': 1.4, 'big': 1.4, 'small': 0.7, 'bowl': 1, 'double': 2,
  };

  static int? estimate(String text) {
    final t = ' ${text.toLowerCase()} ';
    final num = RegExp(r'(\d+(?:\.\d+)?)');

    for (final e in _exercisePerKm.entries) {
      if (t.contains(e.key)) {
        final km = RegExp(r'(\d+(?:\.\d+)?)\s*k').firstMatch(t);
        final d = km != null ? double.parse(km.group(1)!) : 3;
        return -(d * e.value).round();
      }
    }
    for (final e in _exercisePerMin.entries) {
      if (t.contains(e.key)) {
        final m = RegExp(r'(\d+)\s*(min|m\b)').firstMatch(t);
        final h = RegExp(r'(\d+(?:\.\d+)?)\s*h').firstMatch(t);
        final mins = m != null
            ? double.parse(m.group(1)!)
            : h != null
                ? double.parse(h.group(1)!) * 60
                : 45;
        return -(mins * e.value).round();
      }
    }

    var total = 0.0;
    var found = false;
    final keys = _foods.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    var rest = t;
    for (final k in keys) {
      if (rest.contains(k)) {
        found = true;
        var mult = 1.0;
        final idx = rest.indexOf(k);
        final before = rest.substring((idx - 22).clamp(0, idx), idx);
        final n = num.allMatches(before).lastOrNull;
        if (n != null) {
          mult = double.parse(n.group(1)!);
        } else {
          for (final q in _qty.entries) {
            if (before.contains(q.key)) mult *= q.value;
          }
        }
        total += _foods[k]! * mult;
        rest = rest.replaceFirst(k, ' ');
      }
    }
    return found ? total.round() : null;
  }
}
