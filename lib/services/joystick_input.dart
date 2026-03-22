import 'package:flutter/material.dart';
import 'controller_service.dart';

/// Manages joystick input from on-screen thumb stick
class JoystickInputManager {
  static const double _deadzone = 0.1;
  static const double _maxDistance = 100.0;

  final ControllerConnectionService controllerService;

  double _lastX = 0;
  double _lastY = 0;

  JoystickInputManager({required this.controllerService});

  /// Process joystick movement from on-screen gesture
  /// offset: position relative to joystick center
  /// size: size of the joystick area
  void processJoystickInput(Offset offset, Size size) {
    double dx = offset.dx / (size.width / 2);
    double dy = offset.dy / (size.height / 2);

    // Clamp to unit circle
    double distance = dx * dx + dy * dy;
    if (distance > 1.0) {
      final mag = distance.ceilToDouble();
      dx /= mag;
      dy /= mag;
    }

    // Apply deadzone
    if (distance.abs() < (_deadzone * _deadzone)) {
      dx = 0;
      dy = 0;
    }

    // Only send if changed
    if (dx != _lastX || dy != _lastY) {
      _lastX = dx;
      _lastY = dy;
      controllerService.sendJoystickAxes(dx, -dy); // Invert Y for gaming convention
    }
  }

  /// Reset joystick to center
  void reset() {
    _lastX = 0;
    _lastY = 0;
    controllerService.sendJoystickAxes(0, 0);
  }
}

/// Widget for on-screen joystick
class JoystickWidget extends StatefulWidget {
  final JoystickInputManager inputManager;
  final Color backgroundColor;
  final Color stickColor;
  final double size;

  const JoystickWidget({
    Key? key,
    required this.inputManager,
    this.backgroundColor = const Color(0xFF333333),
    this.stickColor = const Color(0xFF0099FF),
    this.size = 200.0,
  }) : super(key: key);

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget> {
  late Offset _stickPosition;

  @override
  void initState() {
    super.initState();
    _stickPosition = Offset.zero;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final center = Offset(widget.size / 2, widget.size / 2);
    final localPosition = box.globalToLocal(details.globalPosition);

    final offset = localPosition - center;
    final distance = offset.distance;

    if (distance > widget.size / 2) {
      // Clamp to circle boundary
      final angle = (offset / distance) * (widget.size / 2);
      setState(() {
        _stickPosition = angle;
      });
    } else {
      setState(() {
        _stickPosition = offset;
      });
    }

    widget.inputManager.processJoystickInput(
      offset,
      Size(widget.size, widget.size),
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _stickPosition = Offset.zero;
    });
    widget.inputManager.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.size / 2),
          border: Border.all(color: const Color(0xFF666666), width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.stickColor.withAlpha(100),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Stick position indicator
            Transform.translate(
              offset: _stickPosition,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.stickColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: widget.stickColor.withAlpha(50),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${(_stickPosition.dx / (widget.size / 2)).toStringAsFixed(2)},${(_stickPosition.dy / (widget.size / 2)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
