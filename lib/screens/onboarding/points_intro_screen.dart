import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

class PointsIntroScreen extends StatelessWidget {
  const PointsIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.fg.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: context.fg, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.fg)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(fontSize: 13, height: 1.3, color: context.fg.withValues(alpha: 0.65))),
              ]),
            ),
          ]),
        );

    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: MaeveColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.track_changes, color: MaeveColors.green, size: 18),
                  const SizedBox(width: 6),
                  Text('earn points', style: TextStyle(color: context.fg, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 18),
              Text('turn healthy habits\ninto real rewards.',
                  style: TextStyle(fontSize: 28, height: 1.15, fontWeight: FontWeight.w700, color: context.fg)),
              const SizedBox(height: 22),
              step(Icons.directions_walk, 'move & log',
                  'earn points for hitting step goals, finishing workouts and logging your meals.'),
              step(Icons.savings_outlined, 'build up a balance',
                  'your points add up over time and never expire while you stay active.'),
              step(Icons.card_giftcard, 'redeem for gift cards',
                  'swap points for gift cards from brands you love — Amazon, Spotify, Apple and more.'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.fg.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 18, color: context.fg.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('rewards are a prototype — redemptions aren\'t fulfilled yet.',
                        style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.6))),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              PillButton('start earning', onPressed: () => context.go('/loading')),
            ]),
          ),
        ),
      ),
    );
  }
}
