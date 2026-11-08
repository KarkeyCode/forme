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
    await _daily(_workoutId, workoutHour, workoutMinute,
        'Time to move 💪', 'Your workout window is now — let\'s get those points.');
    if (waterReminders) {
      // Spread a few water nudges across the day.
      const hours = [9, 12, 15, 18, 21];
      for (var i = 0; i < hours.length; i++) {
        await _daily(_waterBaseId + i, hours[i], 0,
            'Hydrate 💧', 'Log a glass of water to stay on track and earn points.');
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
      await _plugin.show(9999, 'Reminders on ✅',
          'We\'ll nudge you to work out around $hh:$mm and to drink water through the day.',
          _details);
    } catch (e) {
      debugPrint('notif show error: $e');
    }
  }
}
