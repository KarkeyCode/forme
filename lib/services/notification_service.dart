import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local (on-device) notifications for workout + water reminders.
///
/// Real notifications fire on Android (and iOS once an iOS target is added).
/// On web everything is a safe no-op, so the app still runs in the browser.
///
/// Scheduling note: times are scheduled as absolute instants (the next local
/// HH:MM converted to UTC) and repeated daily, which avoids needing the
/// device's IANA timezone name. DST shifts are ignored for the prototype.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _workoutId = 1001;
  static const _waterBaseId = 2000;
  static const _androidDetails = AndroidNotificationDetails(
    'maeve_reminders',
    'Reminders',
    channelDescription: 'Workout and water reminders',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _details = NotificationDetails(android: _androidDetails);

  // Friendly, human reminder copy with a little emoji graphic.
  static const List<(String, String)> _workoutLines = [
    ('Ready when you are 👟', 'Your workout slot is here. A quick session now and future you says thanks.'),
    ('Let\'s get moving 💪', 'Even 20 minutes counts. Press play and pick up some points on the way.'),
    ('Time to sweat a little 🔥', 'You said this was your window to train. Go show up for yourself!'),
    ('Movement break 🏃', 'A short workout now beats a long one later. You\'ve got this.'),
  ];

  static const List<(String, String)> _waterLines = [
    ('Little sip reminder 💧', 'A glass of water right now keeps you feeling great. Cheers!'),
    ('Stay hydrated 🥤', 'Quick water break? Your body (and your streak) will love it.'),
    ('Hey, drink up 💦', 'One more glass gets you closer to today\'s goal. Easy win.'),
  ];

  bool get supported => !kIsWeb;

  Future<void> init() async {
    if (!supported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: androidInit));
      _ready = true;
    } catch (e) {
      debugPrint('notif init error: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    try {
      final android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } catch (e) {
      debugPrint('notif permission error: $e');
      return false;
    }
  }

  tz.TZDateTime _nextDaily(int hour, int minute) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
    return tz.TZDateTime.from(target.toUtc(), tz.UTC);
  }

  Future<void> _daily(int id, int hour, int minute, String title, String body) async {
    try {
      await _plugin.zonedSchedule(
        id, title, body, _nextDaily(hour, minute), _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    } catch (e) {
      debugPrint('notif schedule error: $e');
    }
  }

  /// Rebuild all scheduled reminders from the user's current preferences.
  Future<void> sync({
    required bool enabled,
    required bool waterReminders,
    required int workoutHour,
    required int workoutMinute,
  }) async {
    if (!supported) return;
    await init();
    await cancelAll();
    if (!enabled) return;
    // A little rotation so it never feels like the same robotic ping.
    final wk = _workoutLines[DateTime.now().weekday % _workoutLines.length];
    await _daily(_workoutId, workoutHour, workoutMinute, wk.$1, wk.$2);
    if (waterReminders) {
      // Spread a few friendly water nudges across the day.
      const hours = [9, 12, 15, 18, 21];
      for (var i = 0; i < hours.length; i++) {
        final w = _waterLines[(DateTime.now().day + i) % _waterLines.length];
        await _daily(_waterBaseId + i, hours[i], 0, w.$1, w.$2);
      }
    }
  }

  Future<void> cancelAll() async {
    if (!supported) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// A one-off confirmation shown right after the user enables reminders.
  Future<void> showEnabledConfirmation(int hour, int minute) async {
    if (!supported) return;
    await init();
    try {
      final hh = hour.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      await _plugin.show(9999, 'You\'re all set 🎉',
          'We\'ll give you a friendly nudge to move around $hh:$mm, plus the odd reminder to sip some water.',
          _details);
    } catch (e) {
      debugPrint('notif show error: $e');
    }
  }
}
