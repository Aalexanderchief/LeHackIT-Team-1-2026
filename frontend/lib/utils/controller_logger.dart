import 'package:flutter/foundation.dart';

/// Logging utility for controller events
class ControllerLogger {
  static const String _prefix = '[GameController]';

  /// Log button press events
  static void logButtonPress(String buttonId, bool isPressed) {
    final action = isPressed ? 'PRESSED' : 'RELEASED';
    _log('Button $buttonId $action');
  }

  /// Log stick movement events
  static void logStickMove(String stickId, double x, double y) {
    _log(
        'Stick $stickId moved - X: ${x.toStringAsFixed(2)}, Y: ${y.toStringAsFixed(2)}');
  }

  /// Log trigger events
  static void logTriggerEvent(String triggerId, double value) {
    _log('Trigger $triggerId - Value: ${value.toStringAsFixed(2)}');
  }

  /// Log controller state reset
  static void logReset() {
    _log('Controller state reset');
  }

  /// Log app lifecycle events
  static void logAppEvent(String event) {
    _log('App Event: $event');
  }

  /// Internal logging method
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix $message');
    }
  }

  /// Get formatted timestamp
  static String getTimestamp() {
    return DateTime.now().toIso8601String();
  }
}
