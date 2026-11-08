import 'dart:math' as math;

import 'package:flutter/material.dart';

class StepRing extends StatelessWidget {
  const StepRing({super.key, required this.progress, required this.child, this.size = 190, this.color, this.track});
  final double progress;
  final Widget child;
  final double size;
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1)),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(v, color ?? const Color(0xFF2B2B2B), track ?? const Color(0xFFD6D6D6)),
        child: SizedBox.square(dimension: size, child: Center(child: child)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.color, this.track);
  final double v;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size s) {
    const sw = 18.0;
    final rect = Rect.fromLTWH(sw / 2, sw / 2, s.width - sw, s.height - sw);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.v != v || o.color != color;
}
