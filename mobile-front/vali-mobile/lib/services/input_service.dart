import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

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

  double _lx = 0;
  double _ly = 0;
  double _rx = 0;
  double _ry = 0;
  double _lt = 0;
  double _rt = 0;

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

  Future<void> sendButtonPress(String buttonId) async {
    _applyButtonState(buttonId, true);
    await _sendState();
  }

  Future<void> sendButtonRelease(String buttonId) async {
    _applyButtonState(buttonId, false);
    await _sendState();
  }
  
  Future<void> sendJoystickUpdate(String stickId, double x, double y) async {
    final normalizedX = x.clamp(-1.0, 1.0);
    final normalizedY = y.clamp(-1.0, 1.0);

    if (stickId.toUpperCase() == 'LEFT') {
      _lx = normalizedX;
      _ly = normalizedY;
    } else if (stickId.toUpperCase() == 'RIGHT') {
      _rx = normalizedX;
      _ry = normalizedY;
    }

    await _sendState();
  }

  void _applyButtonState(String buttonId, bool pressed) {
    switch (buttonId.toUpperCase()) {
      case 'A':
        _a = pressed;
        break;
      case 'B':
        _b = pressed;
        break;
      case 'X':
        _x = pressed;
        break;
      case 'Y':
        _y = pressed;
        break;
      case 'START':
        _start = pressed;
        break;
      case 'SELECT':
      case 'BACK':
        _back = pressed;
        break;
      case 'L1':
      case 'LEFT_SHOULDER':
        _leftShoulder = pressed;
        break;
      case 'R1':
      case 'RIGHT_SHOULDER':
        _rightShoulder = pressed;
        break;
      case 'L2':
      case 'LEFT_TRIGGER':
        _lt = pressed ? 1.0 : 0.0;
        break;
      case 'R2':
      case 'RIGHT_TRIGGER':
        _rt = pressed ? 1.0 : 0.0;
        break;
      case 'L3':
      case 'LEFT_THUMB':
        _leftThumb = pressed;
        break;
      case 'R3':
      case 'RIGHT_THUMB':
        _rightThumb = pressed;
        break;
      case 'GUIDE':
      case 'HOME':
        _guide = pressed;
        break;
      case 'DPAD_UP':
        _dpadUp = pressed;
        break;
      case 'DPAD_DOWN':
        _dpadDown = pressed;
        break;
      case 'DPAD_LEFT':
        _dpadLeft = pressed;
        break;
      case 'DPAD_RIGHT':
        _dpadRight = pressed;
        break;
      default:
        debugPrint('Unknown buttonId "$buttonId"');
        break;
    }
  }

  Future<void> _sendState() async {
    if (!await _ensureReady()) {
      return;
    }

    final payload = jsonEncode({
      'type': 'INPUT_STATE',
      'lx': _lx,
      'ly': _ly,
      'rx': _rx,
      'ry': _ry,
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
    });

    _socket!.send(utf8.encode(payload), _address!, _port);
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