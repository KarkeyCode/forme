import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Opening animation: the maeve "M" strokes itself in, the wordmark fades up,
/// then we route to the app (or onboarding).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  late final _draw = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.55, curve: Curves.easeInOut));
  late final _word = CurvedAnimation(parent: _c, curve: const Interval(0.45, 0.8, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _c.forward();
    _c.addStatusListener((st) {
      if (st == AnimationStatus.completed && mounted) {
        final s = context.read<AppState>();
        context.go(s.onboarded ? '/home' : '/welcome');
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlurBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(84, 70),
                  painter: _DrawLogoPainter(_draw.value, context.fg),
                ),
                const SizedBox(height: 18),
                Opacity(
                  opacity: _word.value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - _word.value)),
                    child: Text('maeve health',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.fg)),
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: _word.value * 0.6,
                  child: const Text('your health companion',
                      style: TextStyle(fontSize: 13, color: MaeveColors.muted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawLogoPainter extends CustomPainter {
  _DrawLogoPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.height * 0.22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = p.strokeWidth / 2;
    final path = Path()
      ..moveTo(w, s.height - w)
      ..lineTo(w, w * 1.4)
      ..quadraticBezierTo(s.width * 0.25, w * 0.2, s.width * 0.5, s.height * 0.55)
      ..quadraticBezierTo(s.width * 0.75, w * 0.2, s.width - w, w * 1.4)
      ..lineTo(s.width - w, s.height - w);

    // Draw only the leading `progress` fraction of the stroke.
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress.clamp(0, 1)), p);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawLogoPainter old) =>
      old.progress != progress || old.color != color;
}
