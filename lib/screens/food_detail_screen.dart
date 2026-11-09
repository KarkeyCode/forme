import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/food_facts.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Detailed nutrition breakdown for a single logged item.
class FoodDetailScreen extends StatelessWidget {
  const FoodDetailScreen({super.key, required this.label, required this.kcal});
  final String label;
  final int kcal;

  @override
  Widget build(BuildContext context) {
    final f = factsFor(label, kcal);
    final burned = kcal < 0;

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
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.fg)),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  if (f.servingNote != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(f.servingNote!,
                          style: TextStyle(fontSize: 13, color: context.fg.withValues(alpha: 0.6))),
                    ),
                  // Calories headline
                  GlassCard(
                    child: Row(children: [
                      Icon(burned ? Icons.local_fire_department : Icons.restaurant,
                          color: burned ? MaeveColors.green : context.fg),
                      const SizedBox(width: 12),
                      Text(burned ? 'Calories burned' : 'Calories',
                          style: TextStyle(fontSize: 15, color: context.fg.withValues(alpha: 0.7))),
                      const Spacer(),
                      Text('${f.kcal} cal',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: burned ? MaeveColors.green : context.fg)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel(context, 'Macros'),
                  GlassCard(
                    child: Column(children: [
                      _macroBar(context, 'Protein', f.proteinG, const Color(0xFF3B8EEA)),
                      _macroBar(context, 'Carbohydrates', f.carbsG, const Color(0xFFF5903B)),
                      _macroBar(context, 'Fat', f.fatG, const Color(0xFFE5556B)),
                      _macroBar(context, 'Fibre', f.fiberG, const Color(0xFF34C77B)),
                    ]),
                  ),
                  if (f.micros.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _sectionLabel(context, 'Other Nutrients'),
                    GlassCard(
                      child: Column(children: [
                        for (final e in f.micros.entries) ...[
                          if (e.key != f.micros.keys.first)
                            Divider(height: 14, color: context.fg.withValues(alpha: 0.08)),
                          Row(children: [
                            Text(e.key, style: TextStyle(color: context.fg.withValues(alpha: 0.75))),
                            const Spacer(),
                            Text(e.value, style: TextStyle(fontWeight: FontWeight.w700, color: context.fg)),
                          ]),
                        ],
                      ]),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                        f.estimated
                            ? 'Estimated from calories. Connect a Gemini key for exact values (see AI_SETUP.md).'
                            : 'Typical values per serving.',
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

  Widget _sectionLabel(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.fg.withValues(alpha: 0.5))),
      );

  Widget _macroBar(BuildContext context, String name, double grams, Color color) {
    // Scale the bar against a sensible per-item reference so it reads at a glance.
    final frac = (grams / 50).clamp(0.02, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(name, style: TextStyle(color: context.fg.withValues(alpha: 0.8))),
          const Spacer(),
          Text('${grams.toStringAsFixed(grams == grams.roundToDouble() ? 0 : 1)} g',
              style: TextStyle(fontWeight: FontWeight.w700, color: context.fg)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 7,
            backgroundColor: context.fg.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ]),
    );
  }
}
