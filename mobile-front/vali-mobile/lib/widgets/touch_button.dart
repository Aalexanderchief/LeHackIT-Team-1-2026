import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TouchButton extends StatefulWidget {
  final Widget child;
  final Color color;
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  const TouchButton({
    super.key,
    required this.child,
    required this.color,
    required this.onPressed,
    required this.onReleased,
  });

  @override
  State<TouchButton> createState() => _TouchButtonState();
}

class _TouchButtonState extends State<TouchButton> {
  bool isPressed = false;

  void _handlePointerDown(PointerDownEvent event) {
    HapticFeedback.lightImpact();
    setState(() => isPressed = true);
    widget.onPressed();
  }

  void _handlePointerUp(PointerUpEvent event) {
    setState(() => isPressed = false);
    widget.onReleased();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    setState(() => isPressed = false);
    widget.onReleased();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPressed ? widget.color.withValues(alpha: 0.5) : const Color(0xFF1E2329),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.8),
            width: isPressed ? 4 : 2,
          ),
          boxShadow: isPressed 
              ? [BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 10)] 
              : [],
        ),
        child: Center(
          child: widget.child,
        ),
      ),
    );
  }
}