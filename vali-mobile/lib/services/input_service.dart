import 'package:flutter/foundation.dart';

class InputService {
  static final InputService _instance = InputService._internal();
  factory InputService() => _instance;
  InputService._internal();

  void connectToHost(String ipAddress) {
    debugPrint("Connecting to ws://$ipAddress:8080...");
  }

  void sendButtonPress(String buttonId) {
    final payload = '{"action": "press", "button": "$buttonId"}';
    debugPrint("SENDING: $payload");
  }

  void sendButtonRelease(String buttonId) {
    final payload = '{"action": "release", "button": "$buttonId"}';
    debugPrint("SENDING: $payload");
  }
  
  void sendJoystickUpdate(String stickId, double x, double y) {
    final payload = '{"action": "move", "stick": "$stickId", "x": $x, "y": $y}';
    debugPrint("SENDING: $payload"); 
  }
}