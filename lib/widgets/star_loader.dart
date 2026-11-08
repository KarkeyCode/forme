import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Flutter port of the Uiverse "crack" loader (narmesh_sah): concentric
/// 5-point stars of increasing size, each spinning continuously with a
/// staggered phase so they drift in and out of alignment, with a soft glow.
class StarLoader extends StatefulWidget {
  const StarLoader({super.key, this.size = 120, this.color});
  final double size;
  final Color? color;

  @override
  State<StarLoader> createState() => _StarLoaderState();
}

class _StarLoaderState extends State<StarLoader> with SingleTickerProviderStateMixin {
  // 6s rotation, matching the CSS `animation: rotate 6s infinite`.
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  // Relative sizes (10%..18%) and delays (0, 1, 1.5, 2, 2.5s) from the CSS.
  static const _scales = [0.56, 0.67, 0.78, 0.89, 1.0];
  static const _delays = [0.0, 1.0, 1.5, 2.0, 2.5];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < _scales.length; i++)
              Transform.rotate(
                // phase = base rotation + per-star delay (as a fraction of 6s)
                angle: ((_c.value + _delays[i] / 6.0) % 1.0) * 2 * math.pi,
                child: CustomPaint(
                  size: Size.square(widget.size * _scales[i]),
                  painter: _StarPainter(color.withValues(alpha: 0.32 + 0.11 * i)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final outer = size.width / 2;
    final inner = outer * 0.42; // star point depth
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5; // start at top, 36° steps
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    // Soft glow (the CSS drop-shadow), then the filled star.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.color != color;
}
