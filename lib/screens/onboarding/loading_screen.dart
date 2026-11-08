import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/star_loader.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            StarLoader(size: 140, color: context.fg),
            const SizedBox(height: 28),
            Text('Setting things up',
                style: TextStyle(color: context.fg, fontSize: 16, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}
