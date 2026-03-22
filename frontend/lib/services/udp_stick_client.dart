import 'dart:async';
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

  Future<void> sendStickMove({
    required int x,
    required int y,
    required int rx,
    required int ry,
  }) async {
    if (!await _ensureReady()) {
      return;
    }

    final payload = _encodeStickMove(x: x, y: y, rx: rx, ry: ry);
    _socket!.send(payload, _address!, _port);
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

  List<int> _encodeStickMove({
    required int x,
    required int y,
    required int rx,
    required int ry,
  }) {
    return <int>[
      0x08,
      ..._encodeInt32Varint(x),
      0x10,
      ..._encodeInt32Varint(y),
      0x18,
      ..._encodeInt32Varint(rx),
      0x20,
      ..._encodeInt32Varint(ry),
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
