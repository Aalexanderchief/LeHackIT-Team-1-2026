import 'dart:math';

/// Represents the state of a button on the controller
class ButtonState {
  final String id;
  final String label;
  final bool isPressed;

  const ButtonState({
    required this.id,
    required this.label,
    this.isPressed = false,
  });

  ButtonState copyWith({bool? isPressed}) {
    return ButtonState(
      id: id,
      label: label,
      isPressed: isPressed ?? this.isPressed,
    );
  }
}

/// Represents the state of a stick (thumbstick or d-pad)
class StickState {
  final String id;
  final double x;
  final double y;
  final double maxDistance;

  const StickState({
    required this.id,
    this.x = 0.0,
    this.y = 0.0,
    this.maxDistance = 50.0,
  });

  StickState copyWith({double? x, double? y}) {
    return StickState(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      maxDistance: maxDistance,
    );
  }

  /// Get normalized values between -1 and 1
  (double, double) getNormalized() {
    final distance = sqrt(x * x + y * y);
    if (distance == 0) return (0, 0);

    final scale = distance > maxDistance ? maxDistance / distance : 1.0;
    return (x / maxDistance * scale, -y / maxDistance * scale);
  }
}

/// Represents the state of a trigger (LT, RT)
class TriggerState {
  final String id;
  final double value; // 0.0 to 1.0

  const TriggerState({
    required this.id,
    this.value = 0.0,
  });

  TriggerState copyWith({double? value}) {
    return TriggerState(
      id: id,
      value: (value ?? this.value).clamp(0.0, 1.0),
    );
  }
}

/// Represents the complete state of the Xbox controller
class ControllerState {
  // Face buttons (ABXY)
  final ButtonState buttonA;
  final ButtonState buttonB;
  final ButtonState buttonX;
  final ButtonState buttonY;

  // D-Pad
  final ButtonState dPadUp;
  final ButtonState dPadDown;
  final ButtonState dPadLeft;
  final ButtonState dPadRight;

  // Menu buttons
  final ButtonState buttonMenu;
  final ButtonState buttonView;
  final ButtonState buttonHome;

  // Bumpers
  final ButtonState buttonLB;
  final ButtonState buttonRB;

  // Stick presses
  final ButtonState leftStickPress;
  final ButtonState rightStickPress;

  // Analog inputs
  final StickState leftStick;
  final StickState rightStick;
  final TriggerState leftTrigger;
  final TriggerState rightTrigger;

  ControllerState({
    required this.buttonA,
    required this.buttonB,
    required this.buttonX,
    required this.buttonY,
    required this.dPadUp,
    required this.dPadDown,
    required this.dPadLeft,
    required this.dPadRight,
    required this.buttonMenu,
    required this.buttonView,
    required this.buttonHome,
    required this.buttonLB,
    required this.buttonRB,
    required this.leftStickPress,
    required this.rightStickPress,
    required this.leftStick,
    required this.rightStick,
    required this.leftTrigger,
    required this.rightTrigger,
  });

  factory ControllerState.initial() {
    return ControllerState(
      buttonA: const ButtonState(id: 'A', label: 'A'),
      buttonB: const ButtonState(id: 'B', label: 'B'),
      buttonX: const ButtonState(id: 'X', label: 'X'),
      buttonY: const ButtonState(id: 'Y', label: 'Y'),
      dPadUp: const ButtonState(id: 'DU', label: '↑'),
      dPadDown: const ButtonState(id: 'DD', label: '↓'),
      dPadLeft: const ButtonState(id: 'DL', label: '←'),
      dPadRight: const ButtonState(id: 'DR', label: '→'),
      buttonMenu: const ButtonState(id: 'Menu', label: 'Menu'),
      buttonView: const ButtonState(id: 'View', label: 'View'),
      buttonHome: const ButtonState(id: 'Home', label: 'Xbox'),
      buttonLB: const ButtonState(id: 'LB', label: 'LB'),
      buttonRB: const ButtonState(id: 'RB', label: 'RB'),
      leftStickPress: const ButtonState(id: 'LSP', label: 'L3'),
      rightStickPress: const ButtonState(id: 'RSP', label: 'R3'),
      leftStick: const StickState(id: 'LS'),
      rightStick: const StickState(id: 'RS'),
      leftTrigger: const TriggerState(id: 'LT'),
      rightTrigger: const TriggerState(id: 'RT'),
    );
  }

  ControllerState copyWith({
    ButtonState? buttonA,
    ButtonState? buttonB,
    ButtonState? buttonX,
    ButtonState? buttonY,
    ButtonState? dPadUp,
    ButtonState? dPadDown,
    ButtonState? dPadLeft,
    ButtonState? dPadRight,
    ButtonState? buttonMenu,
    ButtonState? buttonView,
    ButtonState? buttonHome,
    ButtonState? buttonLB,
    ButtonState? buttonRB,
    ButtonState? leftStickPress,
    ButtonState? rightStickPress,
    StickState? leftStick,
    StickState? rightStick,
    TriggerState? leftTrigger,
    TriggerState? rightTrigger,
  }) {
    return ControllerState(
      buttonA: buttonA ?? this.buttonA,
      buttonB: buttonB ?? this.buttonB,
      buttonX: buttonX ?? this.buttonX,
      buttonY: buttonY ?? this.buttonY,
      dPadUp: dPadUp ?? this.dPadUp,
      dPadDown: dPadDown ?? this.dPadDown,
      dPadLeft: dPadLeft ?? this.dPadLeft,
      dPadRight: dPadRight ?? this.dPadRight,
      buttonMenu: buttonMenu ?? this.buttonMenu,
      buttonView: buttonView ?? this.buttonView,
      buttonHome: buttonHome ?? this.buttonHome,
      buttonLB: buttonLB ?? this.buttonLB,
      buttonRB: buttonRB ?? this.buttonRB,
      leftStickPress: leftStickPress ?? this.leftStickPress,
      rightStickPress: rightStickPress ?? this.rightStickPress,
      leftStick: leftStick ?? this.leftStick,
      rightStick: rightStick ?? this.rightStick,
      leftTrigger: leftTrigger ?? this.leftTrigger,
      rightTrigger: rightTrigger ?? this.rightTrigger,
    );
  }
}
