import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/workout_plan.dart';
import '../theme.dart';
import '../widgets/common.dart';

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
              Text('maeve health',
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
            Text('ready for your',
                style: TextStyle(fontSize: 30, height: 1.1, fontWeight: FontWeight.w700, color: context.fg)),
            Text('workout?',
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
                done: s.completedExercises.contains(i),
                onToggle: () => s.toggleExercise(i, exercises[i].points),
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
              child: Text(_seconds == 0 && !_running ? 'start workout' : '$mm:$ss',
                  style: TextStyle(color: context.fg.withValues(alpha: 0.6))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.e, required this.done, required this.onToggle, required this.onVideo});
  final Exercise e;
  final bool done;
  final VoidCallback onToggle, onVideo;

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      GlassCard(
        onTap: onToggle,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(e.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.fg,
                        decoration: done ? TextDecoration.lineThrough : null,
                      )),
                ),
                if (done) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle, color: MaeveColors.green, size: 18),
                ],
              ]),
              const SizedBox(height: 4),
              Text(e.detail, style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.7))),
            ]),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onVideo,
            child: Column(children: [
              Icon(Icons.smart_display_outlined, color: context.fg, size: 28),
              Text('Watch Video', style: TextStyle(fontSize: 9, color: context.fg.withValues(alpha: 0.6))),
            ]),
          ),
        ]),
      ),
      Positioned(
        right: 8,
        top: -10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.track_changes, size: 12, color: context.fg),
            Text(' ${e.points.toString().padLeft(3, '0')}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.fg)),
          ]),
        ),
      ),
    ]);
  }
}
