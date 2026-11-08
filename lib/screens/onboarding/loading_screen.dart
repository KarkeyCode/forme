import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/word_loader.dart';

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
            const WordLoader(),
            const SizedBox(height: 28),
            Text('Getting everything ready for you',
                style: TextStyle(color: context.fg.withValues(alpha: 0.7), fontSize: 15, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}
