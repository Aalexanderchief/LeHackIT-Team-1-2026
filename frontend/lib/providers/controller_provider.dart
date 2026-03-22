import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:game_controller/models/controller_state.dart';
import 'package:game_controller/services/udp_stick_client.dart';
import 'package:game_controller/utils/controller_logger.dart';

/// Provider that manages the state of the game controller
class ControllerProvider extends ChangeNotifier {
  ControllerState _state = ControllerState.initial();
  final UdpStickClient _udpClient = UdpStickClient();

  ControllerState get state => _state;

  /// Update button state
  void updateButton(String buttonId, bool isPressed) {
    final newState = _updateButtonInState(buttonId, isPressed);
    if (newState != null) {
      _state = newState;
      ControllerLogger.logButtonPress(buttonId, isPressed);
      notifyListeners();
    }
  }

  /// Update left stick position
  void updateLeftStick(double x, double y) {
    final clamped = _clampStick(x, y, _state.leftStick.maxDistance);
    _state = _state.copyWith(
      leftStick: _state.leftStick.copyWith(x: clamped.$1, y: clamped.$2),
    );

    _sendSticks();

    ControllerLogger.logStickMove('LEFT', x, y);
    notifyListeners();
  }

  /// Update right stick position
  void updateRightStick(double x, double y) {
    final clamped = _clampStick(x, y, _state.rightStick.maxDistance);
    _state = _state.copyWith(
      rightStick: _state.rightStick.copyWith(x: clamped.$1, y: clamped.$2),
    );
    _sendSticks();
    ControllerLogger.logStickMove('RIGHT', x, y);
    notifyListeners();
  }

  /// Update left trigger value
  void updateLeftTrigger(double value) {
    _state = _state.copyWith(
      leftTrigger: _state.leftTrigger.copyWith(value: value),
    );
    ControllerLogger.logTriggerEvent('LT', value);
    notifyListeners();
  }

  /// Update right trigger value
  void updateRightTrigger(double value) {
    _state = _state.copyWith(
      rightTrigger: _state.rightTrigger.copyWith(value: value),
    );
    ControllerLogger.logTriggerEvent('RT', value);
    notifyListeners();
  }

  /// Reset all inputs
  void reset() {
    _state = ControllerState.initial();
    _sendSticks();
    ControllerLogger.logReset();
    notifyListeners();
  }

  @override
  void dispose() {
    _udpClient.dispose();
    super.dispose();
  }

  Future<void> _sendSticks() async {
    final left = _state.leftStick.getNormalized();
    final right = _state.rightStick.getNormalized();

    final scaledLeftX = (left.$1 * 1000).round().clamp(-1000, 1000);
    final scaledLeftY = (left.$2 * 1000).round().clamp(-1000, 1000);
    final scaledRightX = (right.$1 * 1000).round().clamp(-1000, 1000);
    final scaledRightY = (right.$2 * 1000).round().clamp(-1000, 1000);

    await _udpClient.sendStickMove(
      x: scaledLeftX,
      y: scaledLeftY,
      rx: scaledRightX,
      ry: scaledRightY,
    );
  }

  (double, double) _clampStick(double x, double y, double maxDistance) {
    final squaredDistance = (x * x) + (y * y);
    if (squaredDistance <= maxDistance * maxDistance) {
      return (x, y);
    }

    final magnitude = math.sqrt(squaredDistance);
    final scale = maxDistance / magnitude;
    return (x * scale, y * scale);
  }

  /// Helper method to update button state
  ControllerState? _updateButtonInState(String buttonId, bool isPressed) {
    late ButtonState updatedButton;

    switch (buttonId) {
      case 'A':
        updatedButton = _state.buttonA.copyWith(isPressed: isPressed);
        return _state.copyWith(buttonA: updatedButton);
      case 'B':
        updatedButton = _state.buttonB.copyWith(isPressed: isPressed);
        return _state.copyWith(buttonB: updatedButton);
      case 'X':
        updatedButton = _state.buttonX.copyWith(isPressed: isPressed);
        return _state.copyWith(buttonX: updatedButton);
      case 'Y':
        updatedButton = _state.buttonY.copyWith(isPressed: isPressed);
        return _state.copyWith(buttonY: updatedButton);
      case 'DU':
        updatedButton = _state.dPadUp.copyWith(isPressed: isPressed);
        return _state.copyWith(dPadUp: updatedButton);
      case 'DD':
        updatedButton = _state.dPadDown.copyWith(isPressed: isPressed);
        return _state.copyWith(dPadDown: updatedButton);
      case 'DL':
        updatedButton = _state.dPadLeft.copyWith(isPressed: isPressed);
        return _state.copyWith(dPadLeft: updatedButton);
      case 'DR':
        updatedButton = _state.dPadRight.copyWith(isPressed: isPressed);
        return _state.copyWith(dPadRight: updatedButton);
      case 'LB':
        updatedButton = _state.buttonLB.copyWith(isPressed: isPressed);
        return _state.copyWith(buttonLB: updatedButton);
      case 'RB':
        updatedButton = _state.buttonRB.copyWith(isPressed: isPressed);
        return _state.copyWith(buttonRB: updatedButton);
      case 'Menu':
        updatedButton = _state.buttonMenu.copyWith(isPressed: isPressed);
        return _state.copyWith(buttonMenu: updatedButton);
      case 'View':
        updatedButton = _state.buttonView.copyWith(isPressed: isPressed);
        return _state.copyWith(buttonView: updatedButton);
      case 'Home':
        updatedButton = _state.buttonHome.copyWith(isPressed: isPressed);
        return _state.copyWith(buttonHome: updatedButton);
      case 'LSP':
        updatedButton = _state.leftStickPress.copyWith(isPressed: isPressed);
        return _state.copyWith(leftStickPress: updatedButton);
      case 'RSP':
        updatedButton = _state.rightStickPress.copyWith(isPressed: isPressed);
        return _state.copyWith(rightStickPress: updatedButton);
      default:
        return null;
    }
  }
}
