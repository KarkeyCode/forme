import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/common.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      art: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 60),
        child: Transform.rotate(
          angle: -0.12,
          child: Container(
            width: 96,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                  colors: [Color(0xFFFAFAFA), Color(0xFFCFCFCF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 4),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(8, 12))],
            ),
            child: const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 6),
                child: SizedBox(
                    width: 30,
                    height: 8,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.all(Radius.circular(6))))),
              ),
            ),
          ),
        ),
      ),
      lead: 'how it works.',
      body: 'maeve reads your health data automatically!',
      button: 'got it',
      onNext: () => context.go('/security'),
    );
  }
}
