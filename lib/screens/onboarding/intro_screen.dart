import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

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
                const Spacer(),
                const Text('welcome to', style: TextStyle(fontSize: 20, color: MaeveColors.muted)),
                Text('maeve',
                    style: TextStyle(fontSize: 44, height: 1, fontWeight: FontWeight.w700, color: context.fg)),
                const SizedBox(height: 16),
                Text.rich(
                  const TextSpan(children: [
                    TextSpan(text: 'maeve ', style: TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: 'is your new health companion, track data, plan meals and more!'),
                  ]),
                  style: TextStyle(fontSize: 20, height: 1.3, color: context.fg),
                ),
                const SizedBox(height: 28),
                PillButton('lets go', onPressed: () => context.go('/how')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
