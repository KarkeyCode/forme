import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/step_ring.dart';
import '../widgets/water_glass.dart';

final _fmt = NumberFormat.decimalPattern('en_US');

class MaeveHeader extends StatelessWidget {
  const MaeveHeader({super.key, this.leading});
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Row(children: [
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: leading ??
              Text('FORME',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.fg)),
        ),
      ),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () => context.push('/pro'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(s.isPro ? 'PRO' : 'Free',
              style: TextStyle(fontSize: 12, color: context.fg, fontWeight: FontWeight.w500)),
        ),
      ),
      const SizedBox(width: 6),
      // Points — tap to open rewards / gift cards.
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/rewards'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.track_changes, size: 18, color: context.fg),
            const SizedBox(width: 3),
            Text('${s.points}', style: TextStyle(fontWeight: FontWeight.w600, color: context.fg)),
          ]),
        ),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.settings_outlined, color: context.fg, size: 20),
        onPressed: () => StatefulNavigationShell.of(context).goBranch(3),
      ),
    ]);
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final today = s.weekSteps.isNotEmpty ? s.weekSteps.last.round() : (s.steps[StepRange.week] ?? 0);
    const goal = 10000;

    return BlurBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: s.refreshSteps,
          child: LayoutBuilder(builder: (context, c) {
            // Scale typography/ring to the available width so the content fits
            // comfortably on small and large phones alike.
            final scale = (c.maxWidth / 390).clamp(0.82, 1.18);
            return ListView(
              padding: EdgeInsets.fromLTRB(20 * scale, 8, 20 * scale, 120),
              children: [
                const MaeveHeader(),
                SizedBox(height: 14 * scale),
                _StepRingCard(today: today, goal: goal, scale: scale),
                SizedBox(height: 14 * scale),
                _MetricCarousel(scale: scale),
                SizedBox(height: 14 * scale),
                const _WaterCard(),
                SizedBox(height: 14 * scale),
                _LifetimeCard(total: s.steps[StepRange.total] ?? 0, scale: scale),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// The step spiral card — no range dots anymore, with a real "View More"
/// button that opens the detailed health overview.
class _StepRingCard extends StatelessWidget {
  const _StepRingCard({required this.today, required this.goal, required this.scale});
  final int today;
  final int goal;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.fromLTRB(18 * scale, 14 * scale, 18 * scale, 14 * scale),
      child: Column(children: [
        StepRing(
          size: 190 * scale,
          progress: today / goal,
          color: context.isDark ? Colors.white : MaeveColors.charcoal,
          track: context.isDark ? Colors.white12 : const Color(0xFFD9D9D9),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Today',
                style: TextStyle(fontSize: 15 * scale, fontWeight: FontWeight.w600, color: context.fg.withValues(alpha: 0.7))),
            Text(_fmt.format(today),
                style: TextStyle(fontSize: 36 * scale, height: 1.05, fontWeight: FontWeight.w700, color: context.fg)),
            SizedBox(height: 4 * scale),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: context.fg.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.directions_walk, size: 12, color: context.fg),
                Text(' ${((today / goal) * 100).clamp(0, 999).round()}% of goal',
                    style: TextStyle(fontSize: 11, color: context.fg)),
              ]),
            ),
          ]),
        ),
        SizedBox(height: 12 * scale),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.fg,
              side: BorderSide(color: context.fg.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => context.push('/overview'),
            icon: const Icon(Icons.insights, size: 18),
            label: const Text('View Detailed Health Overview'),
          ),
        ),
      ]),
    );
  }
}

/// Swipeable graphs: steps / heart rate / stress.
class _MetricCarousel extends StatefulWidget {
  const _MetricCarousel({required this.scale});
  final double scale;
  @override
  State<_MetricCarousel> createState() => _MetricCarouselState();
}

class _MetricCarouselState extends State<_MetricCarousel> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final metrics = [
      _Metric('Steps', 'This Week', s.weekSteps, MaeveColors.blue, (v) => _fmt.format(v.round())),
      _Metric('Heart Rate', 'Avg BPM', s.weekHeartRate, MaeveColors.red, (v) => '${v.round()} bpm'),
      _Metric('Stress', 'Level /100', s.weekStress, const Color(0xFFB57BEA), (v) => '${v.round()}'),
    ];

    return GlassCard(
      padding: EdgeInsets.fromLTRB(14 * widget.scale, 12, 14 * widget.scale, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _page,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: metrics.length,
            itemBuilder: (_, i) => _MetricPage(metrics[i], scale: widget.scale),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < metrics.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _index ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _index ? context.fg : context.fg.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ]),
        Center(
          child: Text('Swipe For More Metrics',
              style: TextStyle(fontSize: 11, color: context.fg.withValues(alpha: 0.4))),
        ),
      ]),
    );
  }
}

class _Metric {
  const _Metric(this.name, this.unit, this.data, this.color, this.fmt);
  final String name;
  final String unit;
  final List<double> data;
  final Color color;
  final String Function(double) fmt;
}

class _MetricPage extends StatelessWidget {
  const _MetricPage(this.m, {required this.scale});
  final _Metric m;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final latest = m.data.isNotEmpty ? m.data.last : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(m.name, style: TextStyle(fontSize: 15 * scale, fontWeight: FontWeight.w700, color: context.fg)),
        const Spacer(),
        Text(m.fmt(latest), style: TextStyle(fontSize: 15 * scale, fontWeight: FontWeight.w700, color: m.color)),
      ]),
      Text(m.unit, style: TextStyle(fontSize: 11, color: context.fg.withValues(alpha: 0.5))),
      const SizedBox(height: 6),
      Expanded(child: _LineGraph(m.data, m.color)),
    ]);
  }
}

class _LineGraph extends StatelessWidget {
  const _LineGraph(this.data, this.color);
  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i])];
    final maxY = data.fold<double>(1, (a, b) => b > a ? b : a) * 1.15;
    final minY = data.fold<double>(data.isEmpty ? 0 : data.first, (a, b) => b < a ? b : a) * 0.85;
    return LineChart(
      LineChartData(
        minY: minY < 0 ? 0 : minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (items) => items
                .map((e) => LineTooltipItem(e.y.round().toString(), const TextStyle(color: Colors.white, fontSize: 12)))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              checkToShowDot: (spot, _) => spot.x == spots.length - 1,
              getDotPainter: (_, __, ___, ____) =>
                  FlDotCirclePainter(radius: 4, color: color, strokeColor: Colors.white, strokeWidth: 2),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Daily water intake with a filling glass. Each glass logged earns 5 points
/// (capped at the 5L daily max).
class _WaterCard extends StatelessWidget {
  const _WaterCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final litres = (s.waterLoggedMl / 1000);
    final goalL = (s.waterGoalMl / 1000);
    final capped = s.waterLoggedMl >= AppState.kMaxWaterMl;
    final done = s.waterLoggedMl >= s.waterGoalMl;

    return GlassCard(
      child: Row(children: [
        WaterGlass(progress: s.waterProgress),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Water', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.fg)),
              const SizedBox(width: 6),
              if (done)
                const Icon(Icons.check_circle, color: MaeveColors.green, size: 16),
            ]),
            const SizedBox(height: 2),
            Text('${litres.toStringAsFixed(litres.truncateToDouble() == litres ? 0 : 2)}L of ${goalL.toStringAsFixed(goalL.truncateToDouble() == goalL ? 0 : 1)}L',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.fg)),
            Text('${s.glassesLogged} glasses · +${s.waterPointsPerGlass} pts each${s.isPro ? ' (PRO)' : ''}',
                style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.55))),
            const SizedBox(height: 10),
            Row(children: [
              _btn(context, Icons.remove, () => s.undoWater(), filled: false),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: capped ? null : () => s.logWater(),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: capped ? context.fg.withValues(alpha: 0.12) : MaeveColors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(capped ? 'Daily Max Reached' : '+ Glass (250ml)',
                        style: TextStyle(
                            color: capped ? context.fg.withValues(alpha: 0.6) : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _btn(BuildContext context, IconData icon, VoidCallback onTap, {bool filled = true}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: context.fg.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: context.fg),
        ),
      );
}

/// "total steps tracked with Forme" — replaces the old global-community card
/// and uses the user's real lifetime step total.
class _LifetimeCard extends StatelessWidget {
  const _LifetimeCard({required this.total, required this.scale});
  final int total;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      color: const Color(0xFF1C1C1C),
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
              center: Alignment(1.2, -0.6), radius: 1.4, colors: [Color(0x553C6E58), Colors.transparent]),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Steps Tracked With Forme',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 2 * scale),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: total.toDouble()),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOut,
                builder: (_, v, __) => Text(_fmt.format(v.round()),
                    style: TextStyle(color: Colors.white, fontSize: 30 * scale, fontWeight: FontWeight.w700)),
              ),
              const Text('Every Step You Take, Counted', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ),
          const Column(children: [
            Icon(Icons.favorite_border, color: Colors.white, size: 22),
            SizedBox(height: 6),
            Icon(Icons.timeline, color: Colors.white, size: 22),
          ]),
        ]),
      ),
    );
  }
}
