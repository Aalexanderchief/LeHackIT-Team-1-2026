import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class UdpStickClient {
  UdpStickClient({
    String? host,
    int? port,
  })  : _host = host ?? const String.fromEnvironment('SERVER_HOST', defaultValue: '255.255.255.255'),
        _port = port ?? const int.fromEnvironment('SERVER_UDP_PORT', defaultValue: 55555);

  final String _host;
  final int _port;

  RawDatagramSocket? _socket;
  InternetAddress? _address;
  Future<void>? _initializing;
  bool _initFailedLogged = false;

  Future<void> sendInputState({
    required double lx,
    required double ly,
    required double rx,
    required double ry,
    required double lt,
    required double rt,
    required Map<String, bool> buttons,
  }) async {
    if (!await _ensureReady()) {
      return;
    }

    final payload = jsonEncode({
      'type': 'INPUT_STATE',
      'lx': lx.clamp(-1.0, 1.0),
      'ly': ly.clamp(-1.0, 1.0),
      'rx': rx.clamp(-1.0, 1.0),
      'ry': ry.clamp(-1.0, 1.0),
      'lt': lt.clamp(0.0, 1.0),
      'rt': rt.clamp(0.0, 1.0),
      'buttons': buttons,
    });

    _socket!.send(utf8.encode(payload), _address!, _port);
  }

  void dispose() {
    _socket?.close();
    _socket = null;
    _address = null;
    _initializing = null;
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
