import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/food_estimator.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});
  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  // Gentle glow pulse, only runs while the user is actively typing.
  late final _glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  Timer? _typingStop;
  bool _typing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onType);
    _focus.addListener(() => setState(() {}));
  }

  void _onType() {
    if (!_typing) {
      setState(() => _typing = true);
      _glow.repeat(reverse: true);
    }
    _typingStop?.cancel();
    _typingStop = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _typing = false);
      _glow
        ..stop()
        ..value = 0;
    });
  }

  @override
  void dispose() {
    _typingStop?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    _glow.dispose();
    super.dispose();
  }

  String _ordinal(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    return switch (d % 10) { 1 => '${d}st', 2 => '${d}nd', 3 => '${d}rd', _ => '${d}th' };
  }

  void _submit(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final kcal = FoodEstimator.estimate(t);
    if (kcal == null) {
      setState(() => _error = "Hmm, couldn't read that one. Try something like \"2 eggs and toast\" or \"ran 5km\".");
      return;
    }
    context.read<AppState>().addFood(FoodEntry(t[0].toUpperCase() + t.substring(1), kcal, DateTime.now()));
    _ctrl.clear();
    setState(() => _error = null);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final date = 'Today, ${_ordinal(now.day)} ${DateFormat('MMMM').format(now)}';
    final row = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.fg);
    final kc = TextStyle(fontSize: 14, color: context.fg.withValues(alpha: 0.55));

    return BlurBackground(
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => _focus.requestFocus(),
          behavior: HitTestBehavior.translucent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              MaeveHeader(
                leading: Row(children: [
                  Icon(Icons.calendar_view_day_outlined, size: 20, color: context.fg),
                  const SizedBox(width: 8),
                  Text(date, style: TextStyle(fontSize: 14, color: context.fg)),
                ]),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Text('Total Kcal', style: row.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${s.totalKcal}cal', style: kc),
              ]),
              const SizedBox(height: 6),
              for (var i = 0; i < s.foods.length; i++)
                Dismissible(
                  key: ObjectKey(s.foods[i]),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: const Icon(Icons.delete_outline, color: MaeveColors.red),
                  ),
                  onDismissed: (_) => s.removeFood(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [
                      Expanded(child: Text(s.foods[i].label, style: row)),
                      Text(
                        s.foods[i].kcal < 0 ? '${s.foods[i].kcal} cal' : '${s.foods[i].kcal} cal',
                        style: s.foods[i].kcal < 0
                            ? kc.copyWith(color: MaeveColors.green, fontWeight: FontWeight.w600)
                            : kc,
                      ),
                    ]),
                  ),
                ),
              const SizedBox(height: 10),
              _InputBox(
                controller: _ctrl,
                focus: _focus,
                glow: _glow,
                typing: _typing,
                onSubmit: _submit,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_error!, style: const TextStyle(color: MaeveColors.red, fontSize: 12)),
                ),
              const SizedBox(height: 10),
              Text('Jot down anything you ate or did and Forme works out the calories.',
                  style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.4))),
            ],
          ),
        ),
      ),
    );
  }
}

/// The diet text field. Static bordered box at rest; a soft multi-colour glow
/// that gently pulses only while the user is typing.
class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    required this.focus,
    required this.glow,
    required this.typing,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final AnimationController glow;
  final bool typing;
  final void Function(String) onSubmit;

  @override
  Widget build(BuildContext context) {
    final row = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.fg);
    return AnimatedBuilder(
      animation: glow,
      builder: (context, child) {
        // 0 at rest -> up to ~1 at the peak of a typing pulse.
        final t = typing ? (0.45 + 0.55 * glow.value) : 0.0;
        return Container(
          decoration: BoxDecoration(
            color: context.cardColor.withValues(alpha: context.isDark ? 0.5 : 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: typing
                  ? const Color(0xFF8E7BE0).withValues(alpha: 0.4 + 0.4 * t)
                  : context.fg.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: t == 0
                ? null
                : [
                    BoxShadow(color: const Color(0xFF7BE0A5).withValues(alpha: 0.18 * t), blurRadius: 16 * t, spreadRadius: 1),
                    BoxShadow(color: const Color(0xFF8E7BE0).withValues(alpha: 0.22 * t), blurRadius: 20 * t, spreadRadius: 1),
                  ],
          ),
          child: child,
        );
      },
      child: TextField(
        controller: controller,
        focusNode: focus,
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmit,
        style: row,
        decoration: InputDecoration(
          hintText: 'Write another...',
          hintStyle: TextStyle(color: context.fg.withValues(alpha: 0.4)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          suffixIcon: IconButton(
            icon: Icon(Icons.arrow_upward_rounded, color: context.fg),
            onPressed: () => onSubmit(controller.text),
          ),
        ),
      ),
    );
  }
}
