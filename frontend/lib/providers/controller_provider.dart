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
      _sendState();
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

    _sendState();

    ControllerLogger.logStickMove('LEFT', x, y);
    notifyListeners();
  }

  /// Update right stick position
  void updateRightStick(double x, double y) {
    final clamped = _clampStick(x, y, _state.rightStick.maxDistance);
    _state = _state.copyWith(
      rightStick: _state.rightStick.copyWith(x: clamped.$1, y: clamped.$2),
    );
    _sendState();
    ControllerLogger.logStickMove('RIGHT', x, y);
    notifyListeners();
  }

  /// Update left trigger value
  void updateLeftTrigger(double value) {
    _state = _state.copyWith(
      leftTrigger: _state.leftTrigger.copyWith(value: value),
    );
    _sendState();
    ControllerLogger.logTriggerEvent('LT', value);
    notifyListeners();
  }

  /// Update right trigger value
  void updateRightTrigger(double value) {
    _state = _state.copyWith(
      rightTrigger: _state.rightTrigger.copyWith(value: value),
    );
    _sendState();
    ControllerLogger.logTriggerEvent('RT', value);
    notifyListeners();
  }

  /// Reset all inputs
  void reset() {
    _state = ControllerState.initial();
    _sendState();
    ControllerLogger.logReset();
    notifyListeners();
  }

  @override
  void dispose() {
    _udpClient.dispose();
    super.dispose();
  }

  Future<void> _sendState() async {
    final left = _state.leftStick.getNormalized();
    final right = _state.rightStick.getNormalized();

    await _udpClient.sendInputState(
      lx: left.$1,
      ly: left.$2,
      rx: right.$1,
      ry: right.$2,
      lt: _state.leftTrigger.value,
      rt: _state.rightTrigger.value,
      buttons: {
        'a': _state.buttonA.isPressed,
        'b': _state.buttonB.isPressed,
        'x': _state.buttonX.isPressed,
        'y': _state.buttonY.isPressed,
        'start': _state.buttonMenu.isPressed,
        'back': _state.buttonView.isPressed,
        'leftShoulder': _state.buttonLB.isPressed,
        'rightShoulder': _state.buttonRB.isPressed,
        'leftThumb': _state.leftStickPress.isPressed,
        'rightThumb': _state.rightStickPress.isPressed,
        'guide': _state.buttonHome.isPressed,
        'dpadUp': _state.dPadUp.isPressed,
        'dpadDown': _state.dPadDown.isPressed,
        'dpadLeft': _state.dPadLeft.isPressed,
        'dpadRight': _state.dPadRight.isPressed,
      },
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
