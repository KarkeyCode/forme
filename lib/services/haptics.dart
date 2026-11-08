import 'package:flutter/services.dart';

/// Lightweight global haptics gate. [enabled] is kept in sync with the user's
/// setting from AppState, so any widget can fire a buzz without a context.
class Haptics {
  static bool enabled = true;

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  static void select() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void success() {
    if (!enabled) return;
    // A short escalating celebration: medium then heavy.
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 90), HapticFeedback.heavyImpact);
    Future.delayed(const Duration(milliseconds: 200), HapticFeedback.heavyImpact);
  }
}
