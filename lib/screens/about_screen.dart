import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// "About Us" — the story behind the name plus a (prototype) Terms of Service.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _terms = <(String, String)>[
    ('1. Your Account',
        'You\'re responsible for keeping your account secure. One human, one account, so please keep your login to yourself.'),
    ('2. Health Data',
        'Forme reads the health data you choose to share to personalise your plan. You can disconnect or delete it at any time from Settings.'),
    ('3. Not Medical Advice',
        'Forme is a wellness companion, not a doctor. Nothing in the app is medical advice. Always consult a professional before making big changes.'),
    ('4. Points & Rewards',
        'Points are earned for activity and have no cash value. Gift-card rewards in this prototype are illustrative and are not fulfilled.'),
    ('5. Fair Use',
        'Don\'t attempt to game points, reverse-engineer the app, or use Forme in any unlawful way. We may pause accounts that abuse the service.'),
    ('6. Your Privacy',
        'We never sell your personal data. Your information stays on your device and private account, encrypted in transit and at rest.'),
    ('7. Changes',
        'We may update these terms as Forme grows. We\'ll let you know in-app when anything meaningful changes.'),
    ('8. Contact',
        'Questions about these terms? Reach the team any time at hello@forme.app.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(children: [
                  IconButton(
                    icon: Icon(Icons.close, color: context.fg),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                  ),
                  Text('About Us',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.fg)),
                ]),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                  children: [
                    // Brand mark
                    Center(
                      child: Column(children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: context.fg,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Center(
                            child: MaeveLogo(size: 44, color: context.isDark ? Colors.black : Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('FORME',
                            style: TextStyle(
                                fontSize: 34, letterSpacing: 5, fontWeight: FontWeight.w800, color: context.fg)),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    GlassCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('The Name',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.fg)),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Forme', style: TextStyle(fontWeight: FontWeight.w700)),
                            const TextSpan(text: ', derived from the French words '),
                            TextSpan(
                                text: 'en forme',
                                style: TextStyle(
                                    fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, color: context.fg)),
                            const TextSpan(text: ' '),
                            const TextSpan(text: '(in shape)', style: TextStyle(fontStyle: FontStyle.italic)),
                            const TextSpan(text: '.'),
                          ]),
                          style: TextStyle(fontSize: 15, height: 1.45, color: context.fg.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                            'We built Forme to make being in shape feel simple. Your health data, meals, workouts and rewards, all in one calm place.',
                            style: TextStyle(fontSize: 14, height: 1.45, color: context.fg.withValues(alpha: 0.65))),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    Text('Terms Of Service',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.fg)),
                    const SizedBox(height: 4),
                    Text('Last updated November 2026',
                        style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.5))),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Column(
                        children: [
                          for (var i = 0; i < _terms.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: context.fg.withValues(alpha: 0.08)),
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                shape: const Border(),
                                collapsedShape: const Border(),
                                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                title: Text(_terms[i].$1,
                                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: context.fg)),
                                iconColor: context.fg,
                                collapsedIconColor: context.fg.withValues(alpha: 0.6),
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(_terms[i].$2,
                                        style: TextStyle(
                                            fontSize: 13.5, height: 1.45, color: context.fg.withValues(alpha: 0.7))),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text('This is a prototype, so these terms are just for show',
                          style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.4))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
