import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class HealthSyncScreen extends StatelessWidget {
  const HealthSyncScreen({super.key});

  Future<void> _askAccess(BuildContext context) async {
    final allow = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black12,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFFF4F4F4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('"Forme" would like to access and update your Health Data',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: MaeveColors.ink)),
            const SizedBox(height: 8),
            const Text(
                'Forme uses your steps and workout data to track your progress and personalise your plan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: MaeveColors.muted)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(), foregroundColor: MaeveColors.ink),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      shape: const StadiumBorder(), backgroundColor: MaeveColors.blue),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Allow'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (!context.mounted) return;
    if (allow == true) await context.read<AppState>().requestHealth();
    if (context.mounted) context.go('/profile-setup');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      art: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 70),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (_, v, c) => Transform.scale(scale: v, child: c),
          child: ShaderMask(
            shaderCallback: (r) => const RadialGradient(
              center: Alignment(-0.4, -0.5),
              colors: [Color(0xFF6A6A6A), Colors.black],
            ).createShader(r),
            child: const Icon(Icons.favorite, size: 130, color: Colors.white),
          ),
        ),
      ),
      lead: 'Health Sync',
      body: '\nSync your workouts and health data, make sure to authorise',
      button: 'Continue',
      onNext: () => _askAccess(context),
    );
  }
}
