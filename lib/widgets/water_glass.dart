import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A glass that fills from the bottom to [progress] (0..1) with a gentle wave.
class WaterGlass extends StatefulWidget {
  const WaterGlass({super.key, required this.progress, this.width = 70, this.height = 96});
  final double progress;
  final double width;
  final double height;

  @override
  State<WaterGlass> createState() => _WaterGlassState();
}

class _WaterGlassState extends State<WaterGlass> with SingleTickerProviderStateMixin {
  late final _wave = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _wave,
        builder: (context, _) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.progress.clamp(0, 1)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, p, __) => CustomPaint(
            painter: _GlassPainter(p, _wave.value, context.fg),
          ),
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter(this.progress, this.wave, this.outline);
  final double progress;
  final double wave;
  final Color outline;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    // Tapered glass: slightly narrower at the bottom.
    final topInset = w * 0.06, botInset = w * 0.18;
    final glass = Path()
      ..moveTo(topInset, 2)
      ..lineTo(w - topInset, 2)
      ..lineTo(w - botInset, h - 2)
      ..lineTo(botInset, h - 2)
      ..close();

    // Water fill, clipped to the glass.
    canvas.save();
    canvas.clipPath(glass);
    final level = h - (h - 6) * progress;
    final waterTop = Path()..moveTo(0, level);
    for (double x = 0; x <= w; x += 4) {
      final y = level + math.sin((x / w * 2 * math.pi) + wave * 2 * math.pi) * 3;
      waterTop.lineTo(x, y);
    }
    waterTop
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      waterTop,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5BB8F5), Color(0xFF2E7FD6)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.restore();

    // Glass outline.
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..color = outline.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPainter old) =>
      old.progress != progress || old.wave != wave || old.outline != outline;
}
