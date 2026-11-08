import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/haptics.dart';
import '../services/workout_plan.dart';
import '../theme.dart';
import '../widgets/common.dart';

// Fresh, upbeat accents + icons cycled across the exercise list.
const _accents = [
  Color(0xFF34C77B),
  Color(0xFF3B8EEA),
  Color(0xFFB57BEA),
  Color(0xFFF5903B),
  Color(0xFFE5556B),
  Color(0xFF17B5B0),
];
const _icons = [
  Icons.directions_run,
  Icons.fitness_center,
  Icons.self_improvement,
  Icons.sports_gymnastics,
  Icons.favorite,
  Icons.bolt,
];

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Timer? _timer;
  int _seconds = 0;

  bool get _running => _timer != null;

  void _toggleTimer() {
    setState(() {
      if (_running) {
        _timer!.cancel();
        _timer = null;
      } else {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showVideo(Exercise e) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 56)),
            ),
          ),
          const SizedBox(height: 14),
          Text(e.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(e.detail),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final exercises = recommendedWorkouts(s.profile.goals);
    final mm = (_seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_seconds % 60).toString().padLeft(2, '0');

    return BlurBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Row(children: [
              Text('FORME',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.fg)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: context.fg, borderRadius: BorderRadius.circular(10)),
                child: Text(s.isPro ? 'PRO' : 'FREE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.isDark ? Colors.black : Colors.white)),
              ),
              const Spacer(),
              Icon(Icons.track_changes, size: 18, color: context.fg),
              Text(' ${s.points}', style: TextStyle(fontWeight: FontWeight.w600, color: context.fg)),
            ]),
            const SizedBox(height: 22),
            Text('Ready For Your',
                style: TextStyle(fontSize: 30, height: 1.1, fontWeight: FontWeight.w700, color: context.fg)),
            Text('Workout?',
                style: TextStyle(
                    fontSize: 30, height: 1.1, fontWeight: FontWeight.w700, color: context.fg.withValues(alpha: 0.45))),
            const SizedBox(height: 12),
            // Which goals this plan is built from.
            if (s.profile.goals.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final g in s.profile.goals)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: MaeveColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(g, style: const TextStyle(fontSize: 12, color: MaeveColors.green, fontWeight: FontWeight.w600)),
                  ),
              ]),
            const SizedBox(height: 16),
            for (var i = 0; i < exercises.length; i++) ...[
              _ExerciseCard(
                e: exercises[i],
                accent: _accents[i % _accents.length],
                icon: _icons[i % _icons.length],
                done: s.completedExercises.contains(i),
                onToggle: () {
                  Haptics.light();
                  s.toggleExercise(i, exercises[i].points);
                },
                onVideo: () => _showVideo(exercises[i]),
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 6),
            Center(
              child: GestureDetector(
                onTap: _toggleTimer,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.isDark ? Colors.white10 : Colors.white,
                    border: Border.all(color: context.fg, width: 1.6),
                  ),
                  child: Icon(_running ? Icons.pause : Icons.play_arrow_rounded, size: 44, color: context.fg),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(_seconds == 0 && !_running ? 'Start Workout' : '$mm:$ss',
                  style: TextStyle(color: context.fg.withValues(alpha: 0.6))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard(
      {required this.e,
      required this.accent,
      required this.icon,
      required this.done,
      required this.onToggle,
      required this.onVideo});
  final Exercise e;
  final Color accent;
  final IconData icon;
  final bool done;
  final VoidCallback onToggle, onVideo;

  @override
  Widget build(BuildContext context) {
    final cardBg = context.isDark
        ? Color.alphaBlend(accent.withValues(alpha: 0.12), const Color(0xFF1E1E1E))
        : Color.alphaBlend(accent.withValues(alpha: 0.08), Colors.white);

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: done ? 0.5 : 0.22), width: 1.3),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          // Colourful activity icon tile.
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [accent, Color.alphaBlend(Colors.black.withValues(alpha: 0.15), accent)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(done ? Icons.check_rounded : icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.fg,
                    decoration: done ? TextDecoration.lineThrough : null,
                  )),
              const SizedBox(height: 3),
              Text(e.detail, style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.65))),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bolt, size: 13, color: accent),
                    Text(' ${e.points} pts',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
                  ]),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onVideo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: context.fg.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_circle_outline, size: 13, color: context.fg.withValues(alpha: 0.7)),
                      Text(' Watch',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.fg.withValues(alpha: 0.7))),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
