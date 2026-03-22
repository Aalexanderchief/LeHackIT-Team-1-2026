import 'package:udp/udp.dart';
import 'package:flutter/foundation.dart';
import '../models/stick_move.dart';
import 'mdns_discoverer.dart';

class ControllerConnectionService extends ChangeNotifier {
  UDP? _socket;
  DiscoveredServer? _server;
  bool _connected = false;
  String _status = 'Disconnected';

  bool get connected => _connected;
  String get status => _status;
  DiscoveredServer? get server => _server;

  /// Connect to the LeHackIT server
  Future<bool> connect({String? manualHost, int? manualPort}) async {
    try {
      _status = 'Discovering server...';
      notifyListeners();

      // Try manual connection first if provided
      if (manualHost != null && manualPort != null) {
        _server = DiscoveredServer(
          host: manualHost,
          port: manualPort,
          target: manualHost,
        );
      } else {
        // Try mDNS discovery
        _server = await ServerDiscovery.discoverServer();
      }

      if (_server == null) {
        _status = 'Server not found. Try manual connection.';
        notifyListeners();
        return false;
      }

      _status = 'Server found: ${_server!.host}:${_server!.port}';
      notifyListeners();

      // Create UDP socket
      _socket = await UDP.bind(
        Endpoint.any(port: Port(0)),
      );

      _connected = true;
      _status = 'Connected to ${_server!.host}:${_server!.port}';
      notifyListeners();

      return true;
    } catch (e) {
      _status = 'Connection failed: $e';
      _connected = false;
      notifyListeners();
      return false;
    }
  }

  /// Send joystick input to server
  Future<void> sendInput(int x, int y) async {
    if (!_connected || _socket == null || _server == null) {
      return;
    }

    try {
      final stickMove = StickMove(x: x, y: y);
      final bytes = stickMove.toProtoBytes();

      await _socket!.send(
        bytes,
        Endpoint.unicast(
          InternetAddress(_server!.host),
          port: Port(_server!.port),
        ),
      );
    } catch (e) {
      print('Error sending input: $e');
    }
  }

  /// Send joystick axes (normalized -1 to 1)
  Future<void> sendJoystickAxes(double x, double y) async {
    // Convert to -1000 to 1000 range
    final ix = (x * 1000).round();
    final iy = (y * 1000).round();
    await sendInput(ix, iy);
  }

  /// Disconnect from server
  Future<void> disconnect() async {
    try {
      await _socket?.close();
    } catch (e) {
      print('Error closing socket: $e');
    } finally {
      _socket = null;
      _connected = false;
      _status = 'Disconnected';
      _server = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
