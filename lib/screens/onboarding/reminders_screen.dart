import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
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

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _notifs = s.notificationsEnabled;
    _water = s.waterRemindersEnabled;
    _time = TimeOfDay(hour: s.workoutHour, minute: s.workoutMinute);
    _goalMl = s.waterGoalMl;
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
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
                  GlassCard(
                    child: Column(children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _notifs,
                        onChanged: (v) => setState(() => _notifs = v),
                        title: Text('Enable Notifications',
                            style: TextStyle(fontWeight: FontWeight.w600, color: context.fg)),
                        subtitle: Text('Workout and water reminders',
                            style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.6))),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel(context, 'When Are You Most Free To Work Out?'),
                  GlassCard(
                    onTap: _notifs ? _pickTime : null,
                    child: Row(children: [
                      const Icon(Icons.schedule, color: MaeveColors.blue),
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
                        const Icon(Icons.water_drop, color: MaeveColors.blue),
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
