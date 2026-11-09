import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'app_state.dart';

class StepResult {
  StepResult(this.totals, this.week);
  final Map<StepRange, int> totals;
  final List<double> week;
}

class BodyResult {
  BodyResult({
    this.heightCm,
    this.weightKg,
    this.bodyFatPct,
    this.restingHr,
    this.weekHeartRate,
  });
  final double? heightCm;
  final double? weightKg;
  final double? bodyFatPct;
  final int? restingHr;
  final List<double>? weekHeartRate; // avg bpm per day, last 7 days
}

/// Reads steps from Android Health Connect. Returns null on any failure so
/// the UI keeps showing demo data.
class HealthService {
  final _health = Health();
  bool _configured = false;
  static const _types = [HealthDataType.STEPS];

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      await _configure();
      final status = await _health.getHealthConnectSdkStatus();
      if (status != HealthConnectSdkStatus.sdkAvailable) {
        await _health.installHealthConnect();
        return false;
      }
      return await _health.requestAuthorization(_types,
          permissions: [HealthDataAccess.READ]);
    } catch (e) {
      debugPrint('health permission error: $e');
      return false;
    }
  }

  /// On startup: if Health Connect access hasn't been granted yet, trigger the
  /// Health Connect "allow access" prompt (not the app's own screen) so the
  /// user can approve it after installing or updating the app.
  Future<bool> ensurePermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      await _configure();
      final has = await _health.hasPermissions(_types) ?? false;
      if (has) return true;
      return await requestPermission();
    } catch (e) {
      debugPrint('health ensure error: $e');
      return false;
    }
  }

  /// Reads height/weight/body-fat and heart rate from Health Connect, if
  /// granted. Returns null on web / non-Android or when unavailable.
  ///
  /// Note: there is no cross-platform "stress" metric in Health Connect, so
  /// stress is estimated elsewhere rather than read here.
  Future<BodyResult?> fetchBody() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      await _configure();
      const types = [
        HealthDataType.HEIGHT,
        HealthDataType.WEIGHT,
        HealthDataType.BODY_FAT_PERCENTAGE,
        HealthDataType.HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
      ];
      final granted = await _health.requestAuthorization(types,
          permissions: types.map((_) => HealthDataAccess.READ).toList());
      if (!granted) return null;
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 365));
      final points = await _health.getHealthDataFromTypes(
          types: types, startTime: start, endTime: now);

      double? height, weight, bodyFat, resting;
      double n(HealthDataPoint p) => (p.value as NumericHealthValue).numericValue.toDouble();
      // latest value wins (points come back chronologically)
      for (final p in points) {
        switch (p.type) {
          case HealthDataType.HEIGHT:
            height = n(p) * 100; // metres -> cm
          case HealthDataType.WEIGHT:
            weight = n(p);
          case HealthDataType.BODY_FAT_PERCENTAGE:
            bodyFat = n(p);
          case HealthDataType.RESTING_HEART_RATE:
            resting = n(p);
          default:
            break;
        }
      }

      // Average heart rate per day for the last 7 days.
      final today = DateTime(now.year, now.month, now.day);
      final week = <double>[];
      for (var i = 6; i >= 0; i--) {
        final dayStart = today.subtract(Duration(days: i));
        final dayEnd = i == 0 ? now : dayStart.add(const Duration(days: 1));
        final hrs = points.where((p) =>
            p.type == HealthDataType.HEART_RATE &&
            !p.dateFrom.isBefore(dayStart) &&
            p.dateFrom.isBefore(dayEnd));
        if (hrs.isEmpty) {
          week.add(resting ?? 0);
        } else {
          week.add(hrs.map(n).reduce((a, b) => a + b) / hrs.length);
        }
      }
      final hasHr = week.any((v) => v > 0);

      return BodyResult(
        heightCm: height,
        weightKg: weight,
        bodyFatPct: bodyFat,
        restingHr: resting?.round(),
        weekHeartRate: hasHr ? week : null,
      );
    } catch (e) {
      debugPrint('health body fetch error: $e');
      return null;
    }
  }

  Future<StepResult?> fetch() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      await _configure();
      final has = await _health.hasPermissions(_types) ?? false;
      if (!has) return null;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final week = <double>[];
      for (var i = 6; i >= 0; i--) {
        final start = today.subtract(Duration(days: i));
        final end = i == 0 ? now : start.add(const Duration(days: 1));
        final s = await _health.getTotalStepsInInterval(start, end) ?? 0;
        week.add(s.toDouble());
      }
      final weekTotal = week.fold<double>(0, (a, b) => a + b).round();
      final month = await _health.getTotalStepsInInterval(
              DateTime(now.year, now.month), now) ??
          0;
      // Lifetime: go back as far as the health store keeps data (up to ~10 yrs).
      final all = await _health.getTotalStepsInInterval(
              now.subtract(const Duration(days: 3650)), now) ??
          0;
      return StepResult(
          {StepRange.week: weekTotal, StepRange.month: month, StepRange.total: all},
          week);
    } catch (e) {
      debugPrint('health fetch error: $e');
      return null;
    }
  }
}
