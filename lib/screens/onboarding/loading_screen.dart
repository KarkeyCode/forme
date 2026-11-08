import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      context.read<AppState>().completeOnboarding();
      context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlurBackground(
        child: Center(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                    strokeWidth: 4, strokeCap: StrokeCap.round, color: context.fg),
              ),
              const SizedBox(height: 14),
              Text('setting things up', style: TextStyle(color: context.fg, fontSize: 15)),
              const SizedBox(height: 2),
              const Text(' ', style: TextStyle(color: MaeveColors.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}
