import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'app_state.dart';

class StepResult {
  StepResult(this.totals, this.week);
  final Map<StepRange, int> totals;
  final List<double> week;
}

class BodyResult {
  BodyResult({this.heightCm, this.weightKg});
  final double? heightCm;
  final double? weightKg;
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

  /// Reads the most recent height/weight from Health Connect, if granted.
  /// Returns null on web / non-Android or when unavailable.
  Future<BodyResult?> fetchBody() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      await _configure();
      const types = [HealthDataType.HEIGHT, HealthDataType.WEIGHT];
      final granted = await _health.requestAuthorization(types,
          permissions: [HealthDataAccess.READ]);
      if (!granted) return null;
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 365));
      final points = await _health.getHealthDataFromTypes(
          types: types, startTime: start, endTime: now);
      double? height, weight;
      for (final p in points) {
        final v = (p.value as NumericHealthValue).numericValue.toDouble();
        if (p.type == HealthDataType.HEIGHT) height = v * 100; // metres -> cm
        if (p.type == HealthDataType.WEIGHT) weight = v;
      }
      return BodyResult(heightCm: height, weightKg: weight);
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
      final all = await _health.getTotalStepsInInterval(
              now.subtract(const Duration(days: 365)), now) ??
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
