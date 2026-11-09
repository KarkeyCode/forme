import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/haptics.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

const kDietOptions = [
  'Vegetarian',
  'Vegan',
  'Pescatarian',
  'No Meat',
  'No Seafood',
  'Halal',
  'Kosher',
  'Dairy Free',
  'Gluten Free',
  'Keto',
  'Low Carb',
  'Nut Free',
];

class DietPrefsScreen extends StatefulWidget {
  const DietPrefsScreen({super.key});
  @override
  State<DietPrefsScreen> createState() => _DietPrefsScreenState();
}

class _DietPrefsScreenState extends State<DietPrefsScreen> {
  final Set<String> _diets = {};
  final List<String> _allergens = [];
  final _allergen = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _diets.addAll(p.dietaryPrefs);
    _allergens.addAll(p.allergens);
  }

  @override
  void dispose() {
    _allergen.dispose();
    super.dispose();
  }

  void _addAllergen() {
    final v = _allergen.text.trim();
    if (v.isEmpty) return;
    final cap = v[0].toUpperCase() + v.substring(1);
    if (!_allergens.contains(cap)) {
      Haptics.light();
      setState(() => _allergens.add(cap));
    }
    _allergen.clear();
  }

  void _continue() {
    final p = context.read<AppState>().profile
      ..dietaryPrefs = _diets.toList()
      ..allergens = _allergens;
    context.read<AppState>().saveProfile(p);
    context.go('/reminders');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Diet',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: context.fg)),
              const SizedBox(height: 6),
              Text('Tell us how you eat so your meal plans fit you. You can skip anything that does not apply.',
                  style: TextStyle(fontSize: 14, height: 1.3, color: context.fg.withValues(alpha: 0.6))),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(children: [
                  Text('Dietary Needs', style: _label(context)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final d in kDietOptions)
                      FilterChip(
                        label: Text(d),
                        selected: _diets.contains(d),
                        showCheckmark: true,
                        onSelected: (sel) {
                          Haptics.light();
                          setState(() => sel ? _diets.add(d) : _diets.remove(d));
                        },
                      ),
                  ]),
                  const SizedBox(height: 24),
                  Text('Allergies', style: _label(context)),
                  const SizedBox(height: 4),
                  Text('Add anything you need us to avoid.',
                      style: TextStyle(fontSize: 12.5, color: context.fg.withValues(alpha: 0.55))),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _allergen,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _addAllergen(),
                        style: TextStyle(color: context.fg),
                        decoration: InputDecoration(
                          hintText: 'e.g. Peanuts, Shellfish',
                          hintStyle: TextStyle(color: context.fg.withValues(alpha: 0.4)),
                          filled: true,
                          fillColor: context.cardColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: context.fg,
                          foregroundColor: context.isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _addAllergen,
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final a in _allergens)
                      Chip(
                        label: Text(a),
                        onDeleted: () {
                          Haptics.light();
                          setState(() => _allergens.remove(a));
                        },
                      ),
                  ]),
                ]),
              ),
              PillButton('Continue', onPressed: _continue),
            ]),
          ),
        ),
      ),
    );
  }

  TextStyle _label(BuildContext context) =>
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.fg.withValues(alpha: 0.7));
}
