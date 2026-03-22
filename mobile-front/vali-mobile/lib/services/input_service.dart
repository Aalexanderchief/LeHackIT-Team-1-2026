import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class InputService {
  static final InputService _instance = InputService._internal();
  factory InputService() => _instance;
  InputService._internal();

  String _host = const String.fromEnvironment('SERVER_HOST', defaultValue: '255.255.255.255');
  int _port = const int.fromEnvironment('SERVER_UDP_PORT', defaultValue: 55555);
  RawDatagramSocket? _socket;
  InternetAddress? _address;
  Future<void>? _initializing;
  bool _initFailedLogged = false;

  int _leftX = 0;
  int _leftY = 0;
  int _rightX = 0;
  int _rightY = 0;

  bool _a = false;
  bool _b = false;
  bool _x = false;
  bool _y = false;
  bool _start = false;
  bool _back = false;
  bool _leftShoulder = false;
  bool _rightShoulder = false;
  bool _leftThumb = false;
  bool _rightThumb = false;
  bool _guide = false;
  bool _dpadUp = false;
  bool _dpadDown = false;
  bool _dpadLeft = false;
  bool _dpadRight = false;
  double _lt = 0;
  double _rt = 0;

  void connectToHost(String ipAddress) {
    final trimmed = ipAddress.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _host = trimmed;
    _address = null;
    _socket?.close();
    _socket = null;
    _initializing = null;
    debugPrint('InputService target set to $_host:$_port');
  }

  void sendButtonPress(String buttonId) {
    _setButtonState(buttonId, true);
    _sendCurrentState();
  }

  void sendButtonRelease(String buttonId) {
    _setButtonState(buttonId, false);
    _sendCurrentState();
  }
  
  Future<void> sendJoystickUpdate(String stickId, double x, double y) async {
    final scaledX = (x.clamp(-1.0, 1.0) * 1000).round().clamp(-1000, 1000);
    final scaledY = (y.clamp(-1.0, 1.0) * 1000).round().clamp(-1000, 1000);

    final normalizedStickId = stickId.toUpperCase();
    if (normalizedStickId == 'LEFT') {
      _leftX = scaledX;
      _leftY = scaledY;
    } else if (normalizedStickId == 'RIGHT') {
      _rightX = scaledX;
      _rightY = scaledY;
    }

    await _sendCurrentState();
  }

  Future<void> _sendCurrentState() async {

    if (!await _ensureReady()) {
      return;
    }

    final payload = utf8.encode(
      jsonEncode({
        'type': 'INPUT_STATE',
        'lx': _leftX / 1000,
        'ly': _leftY / 1000,
        'rx': _rightX / 1000,
        'ry': _rightY / 1000,
        'lt': _lt,
        'rt': _rt,
        'buttons': {
          'a': _a,
          'b': _b,
          'x': _x,
          'y': _y,
          'start': _start,
          'back': _back,
          'leftShoulder': _leftShoulder,
          'rightShoulder': _rightShoulder,
          'leftThumb': _leftThumb,
          'rightThumb': _rightThumb,
          'guide': _guide,
          'dpadUp': _dpadUp,
          'dpadDown': _dpadDown,
          'dpadLeft': _dpadLeft,
          'dpadRight': _dpadRight,
        }
      }),
    );
    _socket!.send(payload, _address!, _port);
  }

  void _setButtonState(String buttonId, bool isPressed) {
    switch (buttonId.toUpperCase()) {
      case 'A':
        _a = isPressed;
        break;
      case 'B':
        _b = isPressed;
        break;
      case 'X':
        _x = isPressed;
        break;
      case 'Y':
        _y = isPressed;
        break;
      case 'START':
        _start = isPressed;
        break;
      case 'SELECT':
      case 'BACK':
        _back = isPressed;
        break;
      case 'L1':
        _leftShoulder = isPressed;
        break;
      case 'R1':
        _rightShoulder = isPressed;
        break;
      case 'L2':
        _lt = isPressed ? 1 : 0;
        break;
      case 'R2':
        _rt = isPressed ? 1 : 0;
        break;
      case 'L3':
        _leftThumb = isPressed;
        break;
      case 'R3':
        _rightThumb = isPressed;
        break;
      case 'HOME':
      case 'GUIDE':
        _guide = isPressed;
        break;
      case 'DPAD_UP':
        _dpadUp = isPressed;
        break;
      case 'DPAD_DOWN':
        _dpadDown = isPressed;
        break;
      case 'DPAD_LEFT':
        _dpadLeft = isPressed;
        break;
      case 'DPAD_RIGHT':
        _dpadRight = isPressed;
        break;
      default:
        break;
    }
  }

  Future<bool> _ensureReady() async {
    if (_socket != null && _address != null) {
      return true;
    }

    _initializing ??= _init();
    await _initializing;
    return _socket != null && _address != null;
  }

  Future<void> _init() async {
    try {
      _address = await InternetAddress.lookup(_host).then((result) => result.first);
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;
      _initFailedLogged = false;
      debugPrint('[udp] ready target=${_address!.address}:$_port');
    } catch (error) {
      if (!_initFailedLogged) {
        debugPrint('[udp] failed to initialize socket for $_host:$_port ($error)');
        _initFailedLogged = true;
      }
      _socket = null;
      _address = null;
    } finally {
      _initializing = null;
    }
  }

}