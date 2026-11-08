import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

final _fmt = NumberFormat.decimalPattern('en_US');

class HealthOverviewScreen extends StatelessWidget {
  const HealthOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile;

    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(children: [
                IconButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                    icon: Icon(Icons.arrow_back, color: context.fg)),
                Text('Health Overview',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.fg)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  // Today's activity
                  _sectionTitle(context, 'Today'),
                  Row(children: [
                    Expanded(child: _stat(context, Icons.directions_walk, 'Steps', _fmt.format(s.weekSteps.last.round()), MaeveColors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _stat(context, Icons.favorite, 'Resting HR', '${s.restingHr} bpm', MaeveColors.red)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _stat(context, Icons.self_improvement, 'Stress', '${s.currentStress}/100', const Color(0xFFB57BEA))),
                    const SizedBox(width: 12),
                    Expanded(child: _stat(context, Icons.local_fire_department, 'Active Kcal', _fmt.format((s.weekSteps.last * 0.04).round()), const Color(0xFFF59E0B))),
                  ]),
                  const SizedBox(height: 20),

                  // Steps totals
                  _sectionTitle(context, 'Steps'),
                  GlassCard(
                    child: Column(children: [
                      _row(context, 'This Week', _fmt.format(s.steps[StepRange.week] ?? 0)),
                      _divider(context),
                      _row(context, 'This Month', _fmt.format(s.steps[StepRange.month] ?? 0)),
                      _divider(context),
                      _row(context, 'Lifetime With Forme', _fmt.format(s.steps[StepRange.total] ?? 0)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Heart Rate · This Week', style: TextStyle(fontWeight: FontWeight.w600, color: context.fg)),
                      const SizedBox(height: 8),
                      SizedBox(height: 90, child: _MiniChart(s.weekHeartRate, MaeveColors.red)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Stress · This Week', style: TextStyle(fontWeight: FontWeight.w600, color: context.fg)),
                      const SizedBox(height: 8),
                      SizedBox(height: 90, child: _MiniChart(s.weekStress, const Color(0xFFB57BEA))),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Body composition
                  _sectionTitle(context, 'Body Composition'),
                  if (!p.hasBody)
                    GlassCard(
                      child: Row(children: [
                        Icon(Icons.info_outline, color: context.fg.withValues(alpha: 0.6)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Add your height and weight in your profile to see body composition.',
                              style: TextStyle(color: context.fg.withValues(alpha: 0.7), fontSize: 13)),
                        ),
                      ]),
                    )
                  else
                    GlassCard(
                      child: Column(children: [
                        if (p.heightCm != null) _row(context, 'Height', '${p.heightCm!.round()} cm'),
                        if (p.weightKg != null) ...[_divider(context), _row(context, 'Weight', '${p.weightKg!.round()} kg')],
                        if (p.bmi != null) ...[_divider(context), _row(context, 'BMI', p.bmi!.toStringAsFixed(1))],
                        if (p.bodyFatPct != null) ...[_divider(context), _row(context, 'Body Fat', '${p.bodyFatPct!.round()}%')],
                        if (p.leanMassKg != null) ...[_divider(context), _row(context, 'Lean Mass', '${p.leanMassKg!.round()} kg')],
                        if (p.bmr != null) ...[_divider(context), _row(context, 'BMR', '${_fmt.format(p.bmr)} kcal/day')],
                      ]),
                    ),
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'Goals'),
                  GlassCard(
                    child: p.goals.isEmpty
                        ? Row(children: [
                            Icon(Icons.flag_outlined, color: context.fg.withValues(alpha: 0.6)),
                            const SizedBox(width: 12),
                            Text('No goals set yet',
                                style: TextStyle(fontSize: 15, color: context.fg.withValues(alpha: 0.6))),
                          ])
                        : Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final g in p.goals)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: MaeveColors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.flag, color: MaeveColors.green, size: 15),
                                  const SizedBox(width: 6),
                                  Text(g, style: const TextStyle(fontSize: 13, color: MaeveColors.green, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                          ]),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.fg.withValues(alpha: 0.5))),
      );

  Widget _stat(BuildContext context, IconData icon, String label, String value, Color c) => GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.fg)),
          Text(label, style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.6))),
        ]),
      );

  Widget _row(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Text(label, style: TextStyle(color: context.fg.withValues(alpha: 0.7))),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: context.fg)),
        ]),
      );

  Widget _divider(BuildContext context) => Divider(height: 1, color: context.fg.withValues(alpha: 0.1));
}

class _MiniChart extends StatelessWidget {
  const _MiniChart(this.data, this.color);
  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i])];
    final maxY = data.fold<double>(1, (a, b) => b > a ? b : a) * 1.2;
    final minY = data.fold<double>(data.first, (a, b) => b < a ? b : a) * 0.8;
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
