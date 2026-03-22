import 'package:flutter/foundation.dart';
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

  int _leftX = 0;
  int _leftY = 0;

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
    final payload = '{"action": "press", "button": "$buttonId"}';
    debugPrint("SENDING: $payload");
  }

  void sendButtonRelease(String buttonId) {
    final payload = '{"action": "release", "button": "$buttonId"}';
    debugPrint("SENDING: $payload");
  }
  
  Future<void> sendJoystickUpdate(String stickId, double x, double y) async {
    final scaledX = (x.clamp(-1.0, 1.0) * 1000).round().clamp(-1000, 1000);
    final scaledY = (y.clamp(-1.0, 1.0) * 1000).round().clamp(-1000, 1000);

    if (stickId.toUpperCase() == 'LEFT') {
      _leftX = scaledX;
      _leftY = scaledY;
    }

    if (!await _ensureReady()) {
      return;
    }

    // Current backend schema consumes left stick fields x/y.
    final payload = _encodeStickMove(x: _leftX, y: _leftY);
    _socket!.send(payload, _address!, _port);
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

  List<int> _encodeStickMove({required int x, required int y}) {
    return <int>[
      0x08,
      ..._encodeInt32Varint(x),
      0x10,
      ..._encodeInt32Varint(y),
    ];
  }

  List<int> _encodeInt32Varint(int value) {
    final normalized = value < 0 ? (value & 0xFFFFFFFFFFFFFFFF) : value;
    return _encodeVarint(normalized);
  }

  List<int> _encodeVarint(int value) {
    var current = value;
    final bytes = <int>[];
    while (current > 0x7F) {
      bytes.add((current & 0x7F) | 0x80);
      current = current >> 7;
    }
    bytes.add(current & 0x7F);
    return bytes;
  }
}