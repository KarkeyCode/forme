import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Thin wrapper over the Gemini REST API for (a) estimating calories of ANY
/// food the user types and (b) generating a diet plan.
///
/// The API key is supplied at build time so it never ships hard-coded:
///   flutter run --dart-define=GEMINI_API_KEY=your_key
/// See AI_SETUP.md. When no key is set, [configured] is false and the app
/// falls back to the built-in offline estimator / sample plan.
class GeminiService {
  GeminiService._();
  static final instance = GeminiService._();

  static const _key = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-2.0-flash';
  bool get configured => _key.isNotEmpty;

  Uri get _endpoint => Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_key');

  Future<String?> _generate(String prompt) async {
    if (!configured) return null;
    try {
      final res = await http
          .post(_endpoint,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ]
              }))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        debugPrint('gemini ${res.statusCode}: ${res.body}');
        return null;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final text = (((json['candidates'] as List?)?.first
              as Map<String, dynamic>?)?['content']
          as Map<String, dynamic>?)?['parts'] as List?;
      return (text?.first as Map<String, dynamic>?)?['text'] as String?;
    } catch (e) {
      debugPrint('gemini error: $e');
      return null;
    }
  }

  /// Estimate total calories for a free-text food/activity description.
  /// Negative means calories burned (an activity). Returns null on failure.
  Future<int?> estimateCalories(String text) async {
    final out = await _generate(
        'Estimate the total calories for this food or activity. '
        'If it is exercise/activity, return a NEGATIVE number (calories burned). '
        'Reply with ONLY an integer, no words or units.\n\n"$text"');
    if (out == null) return null;
    final m = RegExp(r'-?\d+').firstMatch(out.replaceAll(',', ''));
    return m == null ? null : int.tryParse(m.group(0)!);
  }

  /// Generate a short, followable diet plan tailored to the user.
  Future<String?> planDiet({
    required List<String> goals,
    required List<String> dietaryPrefs,
    required List<String> allergens,
    int? calorieTarget,
  }) {
    final g = goals.isEmpty ? 'general health' : goals.join(', ');
    final d = dietaryPrefs.isEmpty ? 'no specific diet' : dietaryPrefs.join(', ');
    final a = allergens.isEmpty ? 'none' : allergens.join(', ');
    return _generate(
        'Create a simple one-day meal plan a person can follow.\n'
        'Goals: $g\nDietary needs: $d\nAllergies to avoid: $a\n'
        '${calorieTarget != null ? 'Daily calorie target: about $calorieTarget kcal\n' : ''}'
        'Give Breakfast, Lunch, Dinner and one Snack. For each, list the foods and approximate calories. '
        'Keep it concise and friendly. Use plain text with clear headings, no markdown symbols.');
  }
}
