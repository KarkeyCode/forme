import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget point(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: MaeveColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: MaeveColors.green, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.fg)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(fontSize: 13, height: 1.35, color: context.fg.withValues(alpha: 0.65))),
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: MaeveColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.verified_user_outlined, color: MaeveColors.green, size: 38),
              ),
              const SizedBox(height: 20),
              Text('Your Data Is Safe With Us',
                  style: TextStyle(fontSize: 28, height: 1.15, fontWeight: FontWeight.w700, color: context.fg)),
              const SizedBox(height: 8),
              Text('Your health is personal. We protect it with the highest standard of security.',
                  style: TextStyle(fontSize: 15, height: 1.35, color: context.fg.withValues(alpha: 0.6))),
              const SizedBox(height: 28),
              point(Icons.lock_outline, 'End-to-End Encryption',
                  'Your health data is encrypted in transit and at rest — unreadable to anyone but you.'),
              point(Icons.block, 'Never Sold, Never Shared',
                  'We don\'t sell or share your personal data with advertisers or third parties. Ever.'),
              point(Icons.phonelink_lock_outlined, 'You Stay In Control',
                  'Your data stays on your device and your private account. Delete it anytime.'),
              const Spacer(),
              PillButton('I Understand, Continue', onPressed: () => context.go('/login')),
              const SizedBox(height: 8),
              Center(
                child: Text('Prototype — no real data is collected or transmitted yet',
                    style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.4))),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
