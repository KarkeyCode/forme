import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 2600), _next);
  }

  void _next() {
    _t?.cancel();
    if (mounted) context.go('/intro');
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _next,
        child: BlurBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  builder: (_, v, c) => Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: c)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('welcome to',
                          style: TextStyle(fontSize: 26, color: MaeveColors.muted)),
                      Text('maeve',
                          style: TextStyle(
                              fontSize: 64, height: 1, fontWeight: FontWeight.w700, color: context.fg)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
