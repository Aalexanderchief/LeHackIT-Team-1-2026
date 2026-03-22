import 'package:flutter/material.dart';
import 'package:game_controller/providers/controller_provider.dart';

/// D-Pad Widget
class DPadWidget extends StatelessWidget {
  final ControllerProvider controller;

  const DPadWidget({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => controller.updateButton('DU', true),
          onTapUp: (_) => controller.updateButton('DU', false),
          onTapCancel: () => controller.updateButton('DU', false),
          child: DPadButton(
              isPressed: controller.state.dPadUp.isPressed, icon: '↑'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTapDown: (_) => controller.updateButton('DL', true),
              onTapUp: (_) => controller.updateButton('DL', false),
              onTapCancel: () => controller.updateButton('DL', false),
              child: DPadButton(
                  isPressed: controller.state.dPadLeft.isPressed, icon: '←'),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTapDown: (_) => controller.updateButton('DR', true),
              onTapUp: (_) => controller.updateButton('DR', false),
              onTapCancel: () => controller.updateButton('DR', false),
              child: DPadButton(
                  isPressed: controller.state.dPadRight.isPressed, icon: '→'),
            ),
          ],
        ),
        GestureDetector(
          onTapDown: (_) => controller.updateButton('DD', true),
          onTapUp: (_) => controller.updateButton('DD', false),
          onTapCancel: () => controller.updateButton('DD', false),
          child: DPadButton(
              isPressed: controller.state.dPadDown.isPressed, icon: '↓'),
        ),
      ],
    );
  }
}

/// Individual D-Pad Button
class DPadButton extends StatelessWidget {
  final bool isPressed;
  final String icon;

  const DPadButton({
    Key? key,
    required this.isPressed,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isPressed ? Colors.purple.shade400 : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPressed ? Colors.purple.shade300 : Colors.grey.shade600,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          icon,
          style: TextStyle(
            color: isPressed ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Left Stick Widget
class LeftStickWidget extends StatefulWidget {
  final ControllerProvider controller;

  const LeftStickWidget({Key? key, required this.controller}) : super(key: key);

  @override
  State<LeftStickWidget> createState() => _LeftStickWidgetState();
}

class _LeftStickWidgetState extends State<LeftStickWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPosition = details.localPosition;
          final centerX = box.size.width / 2;
          final centerY = box.size.height / 2;
          widget.controller.updateLeftStick(
            localPosition.dx - centerX,
            localPosition.dy - centerY,
          );
        }
      },
      onPanEnd: (_) {
        widget.controller.updateLeftStick(0, 0);
      },
      child: AnalogStick(
        value: widget.controller.state.leftStick,
        label: 'L',
      ),
    );
  }
}

/// Right Stick Widget
class RightStickWidget extends StatefulWidget {
  final ControllerProvider controller;

  const RightStickWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  State<RightStickWidget> createState() => _RightStickWidgetState();
}

class _RightStickWidgetState extends State<RightStickWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPosition = details.localPosition;
          final centerX = box.size.width / 2;
          final centerY = box.size.height / 2;
          widget.controller.updateRightStick(
            localPosition.dx - centerX,
            localPosition.dy - centerY,
          );
        }
      },
      onPanEnd: (_) {
        widget.controller.updateRightStick(0, 0);
      },
      child: AnalogStick(
        value: widget.controller.state.rightStick,
        label: 'R',
      ),
    );
  }
}

/// Analog Stick (Thumbstick) Widget
class AnalogStick extends StatelessWidget {
  final dynamic value;
  final String label;

  const AnalogStick({
    Key? key,
    required this.value,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const stickSize = 80.0;
    const innerSize = 50.0;
    const thumbSize = 24.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer circle
        Container(
          width: stickSize,
          height: stickSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade600,
              width: 1,
            ),
            color: Colors.grey.shade900,
          ),
        ),
        // Inner circle
        Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade600,
              width: 1,
            ),
            color: Colors.transparent,
          ),
        ),
        // Thumb
        Transform.translate(
          offset: Offset(value.x, value.y),
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.shade400,
              border: Border.all(
                color: Colors.purple.shade300,
                width: 1,
              ),
            ),
          ),
        ),
        // Label
        Positioned(
          bottom: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Face Buttons Widget (ABXY)
class FaceButtonsWidget extends StatelessWidget {
  final ControllerProvider controller;

  const FaceButtonsWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade600,
              width: 1,
            ),
            color: Colors.transparent,
          ),
        ),
        // Y Button (Top)
        Positioned(
          top: 0,
          child: FaceButton(
            label: 'Y',
            isPressed: controller.state.buttonY.isPressed,
            onTapDown: () => controller.updateButton('Y', true),
            onTapUp: () => controller.updateButton('Y', false),
            color: Colors.yellow.shade700,
          ),
        ),
        // A Button (Bottom)
        Positioned(
          bottom: 0,
          child: FaceButton(
            label: 'A',
            isPressed: controller.state.buttonA.isPressed,
            onTapDown: () => controller.updateButton('A', true),
            onTapUp: () => controller.updateButton('A', false),
            color: Colors.green.shade700,
          ),
        ),
        // X Button (Left)
        Positioned(
          left: 0,
          child: FaceButton(
            label: 'X',
            isPressed: controller.state.buttonX.isPressed,
            onTapDown: () => controller.updateButton('X', true),
            onTapUp: () => controller.updateButton('X', false),
            color: Colors.blue.shade700,
          ),
        ),
        // B Button (Right)
        Positioned(
          right: 0,
          child: FaceButton(
            label: 'B',
            isPressed: controller.state.buttonB.isPressed,
            onTapDown: () => controller.updateButton('B', true),
            onTapUp: () => controller.updateButton('B', false),
            color: Colors.red.shade700,
          ),
        ),
      ],
    );
  }
}

/// Individual Face Button
class FaceButton extends StatelessWidget {
  final String label;
  final bool isPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final Color color;

  const FaceButton({
    Key? key,
    required this.label,
    required this.isPressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPressed ? color : color.withOpacity(0.6),
          border: Border.all(
            color: isPressed ? Colors.white : color.withOpacity(0.5),
            width: isPressed ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
