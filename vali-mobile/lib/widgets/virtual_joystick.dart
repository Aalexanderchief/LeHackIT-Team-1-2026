import 'dart:math';
import 'package:flutter/material.dart';

class VirtualJoystick extends StatefulWidget {
  final void Function(double x, double y) onUpdate;
  
  const VirtualJoystick({super.key, required this.onUpdate});

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  double _x = 0;
  double _y = 0;
  final double _maxRadius = 60.0; 
  final double _knobRadius = 25.0; 

  void _updatePosition(Offset localPosition) {
    double dx = localPosition.dx - _maxRadius;
    double dy = localPosition.dy - _maxRadius;
    double distance = sqrt(dx * dx + dy * dy);

    if (distance > _maxRadius) {
      dx = (dx / distance) * _maxRadius;
      dy = (dy / distance) * _maxRadius;
    }

    setState(() {
      _x = dx;
      _y = dy;
    });

    widget.onUpdate(dx / _maxRadius, dy / _maxRadius);
  }

  void _onPointerDown(PointerDownEvent event) => _updatePosition(event.localPosition);
  void _onPointerMove(PointerMoveEvent event) => _updatePosition(event.localPosition);
  
  void _resetPosition(dynamic event) {
    setState(() {
      _x = 0;
      _y = 0;
    });
    widget.onUpdate(0.0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _resetPosition,
      onPointerCancel: _resetPosition,
      child: Container(
        width: _maxRadius * 2,
        height: _maxRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E2329),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              left: _maxRadius - _knobRadius + _x,
              top: _maxRadius - _knobRadius + _y,
              child: Container(
                width: _knobRadius * 2,
                height: _knobRadius * 2,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 5)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}