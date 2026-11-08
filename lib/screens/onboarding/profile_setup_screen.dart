import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/workout_plan.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _age = TextEditingController();
  Sex _sex = Sex.male;
  final Set<String> _goals = {};
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    if (p.heightCm != null) _height.text = p.heightCm!.round().toString();
    if (p.weightKg != null) _weight.text = p.weightKg!.round().toString();
    if (p.age != null) _age.text = p.age!.toString();
    if (p.sex != null) _sex = p.sex!;
    _goals.addAll(p.goals);
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    await context.read<AppState>().syncProfileFromHealth();
    if (!mounted) return;
    final p = context.read<AppState>().profile;
    _height.text = p.heightCm?.round().toString() ?? _height.text;
    _weight.text = p.weightKg?.round().toString() ?? _weight.text;
    _age.text = p.age?.toString() ?? _age.text;
    if (p.sex != null) _sex = p.sex!;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Synced steps, heart rate & body composition from your health data')));
  }

  void _continue() {
    if (_goals.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick at least one goal to continue')));
      return;
    }
    final p = context.read<AppState>().profile
      ..heightCm = double.tryParse(_height.text)
      ..weightKg = double.tryParse(_weight.text)
      ..age = int.tryParse(_age.text)
      ..sex = _sex
      ..goals = _goals.toList();
    context.read<AppState>().saveProfile(p);
    context.go('/reminders');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Body Stats',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: context.fg)),
              const SizedBox(height: 6),
              Text('Maeve uses these to personalise your plan. Enter them manually or sync from your health app.',
                  style: TextStyle(fontSize: 14, height: 1.3, color: context.fg.withValues(alpha: 0.6))),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.fg,
                    side: BorderSide(color: context.fg.withValues(alpha: 0.25)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _syncing ? null : _sync,
                  icon: _syncing
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: context.fg))
                      : const Icon(Icons.favorite_border, size: 20),
                  label: Text(_syncing ? 'Syncing…' : 'Sync From Health App'),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Divider(color: context.fg.withValues(alpha: 0.15))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Or Enter Manually', style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.5))),
                ),
                Expanded(child: Divider(color: context.fg.withValues(alpha: 0.15))),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(children: [
                  Row(children: [
                    Expanded(child: _num(_height, 'Height', 'cm')),
                    const SizedBox(width: 12),
                    Expanded(child: _num(_weight, 'Weight', 'kg')),
                  ]),
                  const SizedBox(height: 12),
                  _num(_age, 'Age', 'yrs'),
                  const SizedBox(height: 16),
                  Text('Sex', style: TextStyle(fontSize: 13, color: context.fg.withValues(alpha: 0.6))),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, children: [
                    for (final x in Sex.values)
                      ChoiceChip(
                        label: Text(_cap(x.name)),
                        selected: _sex == x,
                        onSelected: (_) => setState(() => _sex = x),
                      ),
                  ]),
                  const SizedBox(height: 18),
                  Row(children: [
                    Text('Your Goals', style: TextStyle(fontSize: 13, color: context.fg.withValues(alpha: 0.6))),
                    const SizedBox(width: 6),
                    Text('(pick as many as you like)',
                        style: TextStyle(fontSize: 11, color: context.fg.withValues(alpha: 0.4))),
                  ]),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final g in kAllGoals)
                      FilterChip(
                        label: Text(g),
                        selected: _goals.contains(g),
                        showCheckmark: true,
                        onSelected: (sel) => setState(() => sel ? _goals.add(g) : _goals.remove(g)),
                      ),
                  ]),
                  if (_goals.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Maeve will build a workout plan from these goals.',
                        style: TextStyle(fontSize: 12, color: MaeveColors.green, fontWeight: FontWeight.w500)),
                  ],
                ]),
              ),
              PillButton('Continue', onPressed: _continue),
            ]),
          ),
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Widget _num(TextEditingController c, String hint, String unit) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(color: context.fg, fontSize: 18, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(color: context.fg.withValues(alpha: 0.6)),
          suffixText: unit,
          suffixStyle: TextStyle(color: context.fg.withValues(alpha: 0.5)),
          filled: true,
          fillColor: context.cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );
}
