import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Soft grey blurred blobs that slowly drift — the Figma backdrop.
class BlurBackground extends StatefulWidget {
  const BlurBackground({super.key, required this.child, this.dark});
  final Widget child;
  final bool? dark;

  @override
  State<BlurBackground> createState() => _BlurBackgroundState();
}

class _BlurBackgroundState extends State<BlurBackground>
    with SingleTickerProviderStateMixin {
  late final _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark ?? context.isDark;
    final base = dark ? const Color(0xFF141414) : Colors.white;
    final blob = dark ? const Color(0xFF3A3A3A) : const Color(0xFFBDBDBD);
    return ColoredBox(
      color: base,
      child: Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value * 2 * math.pi;
              return ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: LayoutBuilder(builder: (context, c) {
                  final w = c.maxWidth, h = c.maxHeight;
                  Widget b(double x, double y, double r, double o) => Positioned(
                        left: x - r,
                        top: y - r,
                        child: Container(
                          width: r * 2,
                          height: r * 2,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: blob.withValues(alpha: o)),
                        ),
                      );
                  return Stack(children: [
                    b(w * (0.7 + 0.08 * math.sin(t)), h * 0.18, w * 0.32, 0.7),
                    b(w * (0.25 + 0.06 * math.cos(t)), h * (0.42 + 0.03 * math.sin(t)), w * 0.3, 0.55),
                    b(w * 0.8, h * (0.62 + 0.04 * math.cos(t)), w * 0.25, 0.5),
                  ]);
                }),
              );
            },
          ),
        ),
        widget.child,
      ]),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color, this.onTap, this.radius = 24});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (context.isDark
            ? Colors.white.withValues(alpha: 0.07)
            : const Color(0xFFEDEDED).withValues(alpha: 0.85));
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: c,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                    color: (context.isDark ? Colors.white : Colors.white)
                        .withValues(alpha: context.isDark ? 0.08 : 0.6)),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  const PillButton(this.label, {super.key, required this.onPressed, this.light = false});
  final String label;
  final VoidCallback onPressed;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: light ? Colors.white : MaeveColors.charcoal,
          foregroundColor: light ? MaeveColors.ink : Colors.white,
          shape: const StadiumBorder(),
          textStyle: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

/// Onboarding layout: art in the top area, bold-lead text + button at bottom.
class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout(
      {super.key, this.art, required this.lead, required this.body, required this.button, required this.onNext});
  final Widget? art;
  final String lead;
  final String body;
  final String button;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Center(child: art ?? const SizedBox())),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '$lead ', style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: body),
                  ]),
                  style: TextStyle(fontSize: 22, height: 1.3, color: context.fg),
                ),
                const SizedBox(height: 28),
                PillButton(button, onPressed: onNext),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MaeveLogo extends StatelessWidget {
  const MaeveLogo({super.key, this.size = 28, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size * 1.2, size),
        painter: _MPainter(color ?? context.fg),
      );
}

class _MPainter extends CustomPainter {
  _MPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.height * 0.26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = p.strokeWidth / 2;
    final path = Path()
      ..moveTo(w, s.height - w)
      ..lineTo(w, w * 1.4)
      ..quadraticBezierTo(s.width * 0.25, w * 0.2, s.width * 0.5, s.height * 0.55)
      ..quadraticBezierTo(s.width * 0.75, w * 0.2, s.width - w, w * 1.4)
      ..lineTo(s.width - w, s.height - w);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _MPainter old) => old.color != color;
}
