import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/haptics.dart';
import '../../services/notification_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late bool _notifs;
  late bool _water;
  late TimeOfDay _time;
  late int _goalMl;
  late ThemeMode _theme;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _notifs = s.notificationsEnabled;
    _water = s.waterRemindersEnabled;
    _time = TimeOfDay(hour: s.workoutHour, minute: s.workoutMinute);
    _goalMl = s.waterGoalMl;
    _theme = s.themeMode;
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _setTheme(ThemeMode m) {
    setState(() => _theme = m);
    context.read<AppState>().setThemeMode(m); // apply live
  }

  Future<void> _continue() async {
    final s = context.read<AppState>();
    s.setReminderPrefs(
        notifications: _notifs, water: _water, hour: _time.hour, minute: _time.minute);
    s.setWaterGoal(_goalMl);
    if (_notifs) {
      final granted = await NotificationService.instance.requestPermission();
      if (granted) {
        await NotificationService.instance.sync(
          enabled: true,
          waterReminders: _water,
          workoutHour: _time.hour,
          workoutMinute: _time.minute,
        );
        await NotificationService.instance.showEnabledConfirmation(_time.hour, _time.minute);
      }
    }
    if (mounted) context.go('/points-intro');
  }

  @override
  Widget build(BuildContext context) {
    final goalL = _goalMl / 1000;

    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Stay On Track',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: context.fg)),
              const SizedBox(height: 6),
              Text('Forme can send gentle reminders so you never miss a workout or forget to hydrate.',
                  style: TextStyle(fontSize: 14, height: 1.3, color: context.fg.withValues(alpha: 0.6))),
              const SizedBox(height: 22),
              Expanded(
                child: ListView(children: [
                  // Clean, minimal reminders toggle with an Apple-style switch.
                  GlassCard(
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.fg.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                            _notifs ? Icons.notifications_active_outlined : Icons.notifications_none,
                            color: context.fg, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Turn On Reminders',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.fg)),
                          const SizedBox(height: 2),
                          Text('We will nudge you to move and hydrate. You can change this any time.',
                              style: TextStyle(
                                  fontSize: 12.5, height: 1.3, color: context.fg.withValues(alpha: 0.6))),
                        ]),
                      ),
                      const SizedBox(width: 6),
                      CupertinoSwitch(
                        value: _notifs,
                        activeTrackColor: const Color(0xFF0A84FF), // Apple blue when on
                        onChanged: (v) {
                          Haptics.light();
                          setState(() => _notifs = v);
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel(context, 'Appearance'),
                  GlassCard(
                    child: Row(children: [
                      _ThemeChoice(
                          label: 'Light', icon: Icons.light_mode_outlined, mode: ThemeMode.light,
                          selected: _theme == ThemeMode.light, onTap: _setTheme),
                      _ThemeChoice(
                          label: 'Dark', icon: Icons.dark_mode_outlined, mode: ThemeMode.dark,
                          selected: _theme == ThemeMode.dark, onTap: _setTheme),
                      _ThemeChoice(
                          label: 'Auto', icon: Icons.brightness_auto_outlined, mode: ThemeMode.system,
                          selected: _theme == ThemeMode.system, onTap: _setTheme),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel(context, 'When Are You Most Free To Work Out?'),
                  GlassCard(
                    onTap: _notifs ? _pickTime : null,
                    child: Row(children: [
                      Icon(Icons.schedule, color: context.fg.withValues(alpha: 0.7)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Preferred Workout Time',
                              style: TextStyle(fontSize: 13, color: context.fg.withValues(alpha: 0.6))),
                          Text(_time.format(context),
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.fg)),
                        ]),
                      ),
                      Opacity(
                        opacity: _notifs ? 1 : 0.4,
                        child: Icon(Icons.edit_outlined, color: context.fg.withValues(alpha: 0.6)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel(context, 'Daily Water Goal'),
                  GlassCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.water_drop, color: context.fg.withValues(alpha: 0.7)),
                        const SizedBox(width: 10),
                        Text('${goalL.toStringAsFixed(goalL.truncateToDouble() == goalL ? 0 : 1)} L',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.fg)),
                        const Spacer(),
                        Text('${(goalL / 0.25).round()} glasses',
                            style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.55))),
                      ]),
                      Slider(
                        value: _goalMl.toDouble(),
                        min: 1000,
                        max: 5000,
                        divisions: 16,
                        label: '${goalL.toStringAsFixed(2)} L',
                        onChanged: (v) => setState(() => _goalMl = (v / 250).round() * 250),
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('1L', style: TextStyle(fontSize: 11, color: context.fg.withValues(alpha: 0.5))),
                        Text('5L', style: TextStyle(fontSize: 11, color: context.fg.withValues(alpha: 0.5))),
                      ]),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _water,
                        onChanged: _notifs ? (v) => setState(() => _water = v) : null,
                        title: Text('Water Reminders',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.fg)),
                        subtitle: Text('A few gentle nudges through the day',
                            style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.6))),
                      ),
                    ]),
                  ),
                ]),
              ),
              PillButton('Continue', onPressed: _continue),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.fg.withValues(alpha: 0.7))),
      );
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice(
      {required this.label,
      required this.icon,
      required this.mode,
      required this.selected,
      required this.onTap});
  final String label;
  final IconData icon;
  final ThemeMode mode;
  final bool selected;
  final ValueChanged<ThemeMode> onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? context.fg : context.fg.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Icon(icon,
                color: selected ? (context.isDark ? Colors.black : Colors.white) : context.fg.withValues(alpha: 0.7),
                size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? (context.isDark ? Colors.black : Colors.white) : context.fg.withValues(alpha: 0.7))),
          ]),
        ),
      ),
    );
  }
}
