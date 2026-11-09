import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/gemini_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Generates a one-day meal plan from the user's goals, diet prefs and
/// allergens. Uses Gemini when a key is configured (see AI_SETUP.md), otherwise
/// shows a sensible sample plan.
class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});
  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  String? _plan;
  bool _loading = true;
  bool _fromAi = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    final p = context.read<AppState>().profile;
    final target = p.bmr == null ? null : (p.bmr! * 1.4).round();
    String? plan;
    if (GeminiService.instance.configured) {
      plan = await GeminiService.instance.planDiet(
        goals: p.goals,
        dietaryPrefs: p.dietaryPrefs,
        allergens: p.allergens,
        calorieTarget: target,
      );
    }
    if (!mounted) return;
    setState(() {
      _fromAi = plan != null;
      _plan = plan ?? _samplePlan(p, target);
      _loading = false;
    });
  }

  String _samplePlan(UserProfile p, int? target) {
    final veg = p.dietaryPrefs.any((d) => d == 'Vegan' || d == 'Vegetarian' || d == 'No Meat');
    final protein = veg ? 'tofu' : 'grilled chicken';
    final cal = target == null ? '~2,000' : '~$target';
    return 'Daily target: $cal kcal\n\n'
        'Breakfast (~400 kcal)\n'
        'Oats with banana and a spoon of peanut butter.\n\n'
        'Lunch (~550 kcal)\n'
        'Big salad with $protein, mixed greens, olive oil and a wholegrain roll.\n\n'
        'Snack (~200 kcal)\n'
        'Greek yoghurt (or soy yoghurt) with berries.\n\n'
        'Dinner (~650 kcal)\n'
        'Brown rice, roasted veg and $protein, with a side of beans.\n\n'
        'Tip: drink water with each meal and adjust portions to how you feel.';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppState>().profile;
    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: Icon(Icons.close, color: context.fg),
                  onPressed: () => context.canPop() ? context.pop() : context.go('/diet'),
                ),
                Text('Your Diet Plan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.fg)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: context.fg),
                  onPressed: _loading ? null : _generate,
                ),
              ]),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(color: context.fg),
                        const SizedBox(height: 16),
                        Text('Planning your meals...',
                            style: TextStyle(color: context.fg.withValues(alpha: 0.7))),
                      ]),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                      children: [
                        if (p.dietaryPrefs.isNotEmpty || p.allergens.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Wrap(spacing: 8, runSpacing: 8, children: [
                              for (final d in p.dietaryPrefs) _tag(context, d),
                              for (final a in p.allergens) _tag(context, 'No $a'),
                            ]),
                          ),
                        GlassCard(
                          child: Text(_plan ?? '',
                              style: TextStyle(fontSize: 14.5, height: 1.5, color: context.fg)),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Text(
                              _fromAi
                                  ? 'Generated for you by Gemini.'
                                  : 'Sample plan. Add a Gemini key (AI_SETUP.md) for plans made just for you.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.45))),
                        ),
                      ],
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: context.fg.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(fontSize: 12, color: context.fg)),
      );
}
