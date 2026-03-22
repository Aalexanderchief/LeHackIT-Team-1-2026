import 'package:multicast_dns/multicast_dns.dart';

class ServerDiscovery {
  static const String _serviceName = '_lehackit-controller._udp.local';
  
  /// Discover the LeHackIT server on the network
  static Future<DiscoveredServer?> discoverServer({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final mdnsClient = MDnsClient();
    
    try {
      await mdnsClient.start();
      
      // Query for the service
      await mdnsClient.lookup(
        RecordType.srv,
        fullName: _serviceName,
        duration: timeout,
      ).firstWhere(
        (event) {
          if (event is SrvResourceRecord) {
            return event.name == _serviceName;
          }
          return false;
        },
        orElse: () => null,
      ).then((srvRecord) async {
        if (srvRecord is SrvResourceRecord) {
          final target = srvRecord.target;
          final port = srvRecord.port;

          // Query for the A record to get IP address
          final aRecords = await mdnsClient
              .lookup(RecordType.a, fullName: target)
              .where((event) => event is AResourceRecord)
              .cast<AResourceRecord>()
              .timeout(const Duration(seconds: 2), onTimeout: () async* {})
              .toList();

          if (aRecords.isNotEmpty) {
            final ipAddress = aRecords.first.address.toString();
            return DiscoveredServer(
              host: ipAddress,
              port: port,
              target: target,
            );
          }
        }
        return null;
      });
    } catch (e) {
      print('mDNS discovery error: $e');
    } finally {
      mdnsClient.stop();
    }
    
    return null;
  }
}

class DiscoveredServer {
  final String host;
  final int port;
  final String target;

  DiscoveredServer({
    required this.host,
    required this.port,
    required this.target,
  });

  @override
  String toString() => 'DiscoveredServer($host:$port)';
}
