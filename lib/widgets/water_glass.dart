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
    // Tapered tumbler, slightly narrower at the base.
    final topInset = w * 0.07, botInset = w * 0.17;
    final rimRy = w * 0.09; // ellipse radius giving the rim its 3D tilt
    final glass = Path()
      ..moveTo(topInset, rimRy)
      ..lineTo(w - topInset, rimRy)
      ..lineTo(w - botInset, h - rimRy)
      ..quadraticBezierTo(w / 2, h, botInset, h - rimRy)
      ..close();

    // Soft drop shadow under the glass for a grounded 3D feel.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h - 1), width: w * 0.6, height: rimRy * 1.4),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Glass body with a left-to-right curvature gradient.
    canvas.drawPath(
      glass,
      Paint()
        ..shader = LinearGradient(
          colors: [
            outline.withValues(alpha: 0.10),
            outline.withValues(alpha: 0.02),
            outline.withValues(alpha: 0.12),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Water fill, clipped to the glass.
    canvas.save();
    canvas.clipPath(glass);
    final level = (h - rimRy) - (h - rimRy * 2) * progress;
    final waterTop = Path()..moveTo(0, level);
    for (double x = 0; x <= w; x += 3) {
      final y = level + math.sin((x / w * 2 * math.pi) + wave * 2 * math.pi) * 2.5;
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6FC3F7), Color(0xFF2E7FD6), Color(0xFF2468C0)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    // Elliptical meniscus (water surface) for depth.
    if (progress > 0.02) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w / 2, level), width: w - topInset * 2, height: rimRy * 1.5),
        Paint()..color = const Color(0xFF8FD2FA).withValues(alpha: 0.9),
      );
    }
    canvas.restore();

    // Specular highlight stripe on the left for a glassy sheen.
    canvas.save();
    canvas.clipPath(glass);
    final hl = Path()
      ..moveTo(topInset + w * 0.08, rimRy + 4)
      ..lineTo(topInset + w * 0.16, rimRy + 4)
      ..lineTo(botInset + w * 0.12, h - rimRy - 4)
      ..lineTo(botInset + w * 0.04, h - rimRy - 4)
      ..close();
    canvas.drawPath(hl, Paint()..color = Colors.white.withValues(alpha: 0.22));
    canvas.restore();

    // Rim ellipse (the open top of the glass).
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, rimRy), width: w - topInset * 2, height: rimRy * 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = outline.withValues(alpha: 0.6),
    );

    // Glass outline.
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = outline.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPainter old) =>
      old.progress != progress || old.wave != wave || old.outline != outline;
}
