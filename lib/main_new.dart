import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/controller_service.dart';
import 'services/joystick_input.dart';
import 'services/gyroscope_input.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ControllerConnectionService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeHackIT Controller',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const ControllerScreen(),
    );
  }
}

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({Key? key}) : super(key: key);

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  late JoystickInputManager _joystickManager;
  late GyroscopeInputManager _gyroscopeManager;
  late AccelerometerInputManager _accelerometerManager;

  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  bool _useGyroscope = false;
  bool _useAccelerometer = false;

  @override
  void initState() {
    super.initState();
    _hostController.text = 'localhost';
    _portController.text = '55555';

    final controllerService = context.read<ControllerConnectionService>();
    _joystickManager = JoystickInputManager(controllerService: controllerService);
    _gyroscopeManager = GyroscopeInputManager(controllerService: controllerService);
    _accelerometerManager = AccelerometerInputManager(controllerService: controllerService);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _gyroscopeManager.stopGyroscope();
    _accelerometerManager.stopAccelerometer();
    super.dispose();
  }

  Future<void> _handleConnect(BuildContext context) async {
    final controllerService = context.read<ControllerConnectionService>();
    final connected = await controllerService.connect(
      manualHost: _hostController.text,
      manualPort: int.parse(_portController.text),
    );

    if (connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to server!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: ${controllerService.status}')),
      );
    }
  }

  void _toggleGyroscope(ControllerConnectionService service) {
    if (!service.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to server first!')),
      );
      return;
    }

    setState(() {
      _useGyroscope = !_useGyroscope;
      if (_useGyroscope) {
        _accelerometerManager.stopAccelerometer();
        _useAccelerometer = false;
        _gyroscopeManager.startGyroscope();
      } else {
        _gyroscopeManager.stopGyroscope();
      }
    });
  }

  void _toggleAccelerometer(ControllerConnectionService service) {
    if (!service.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to server first!')),
      );
      return;
    }

    setState(() {
      _useAccelerometer = !_useAccelerometer;
      if (_useAccelerometer) {
        _gyroscopeManager.stopGyroscope();
        _useGyroscope = false;
        _accelerometerManager.startAccelerometer();
      } else {
        _accelerometerManager.stopAccelerometer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LeHackIT Xbox/PS Controller'),
        elevation: 2,
      ),
      body: Consumer<ControllerConnectionService>(
        builder: (context, controllerService, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Section
                _buildConnectionSection(context, controllerService),
                const SizedBox(height: 24),

                // Status Section
                _buildStatusSection(controllerService),
                const SizedBox(height: 24),

                // Mode Selection
                _buildModeSection(),
                const SizedBox(height: 24),

                // Input Display
                if (!_useGyroscope && !_useAccelerometer)
                  _buildJoystickSection()
                else
                  _buildSensorDisplay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionSection(
    BuildContext context,
    ControllerConnectionService service,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Connection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: 'localhost or IP address',
                border: OutlineInputBorder(),
              ),
              enabled: !service.connected,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '55555',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              enabled: !service.connected,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: service.connected
                    ? () => service.disconnect()
                    : () => _handleConnect(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor:
                      service.connected ? Colors.red : Colors.green,
                ),
                child: Text(
                  service.connected ? 'Disconnect' : 'Connect',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(ControllerConnectionService service) {
    return Card(
      color: service.connected ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: service.connected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(service.status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input Mode',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Consumer<ControllerConnectionService>(
              builder: (context, service, _) {
                return Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Joystick Mode'),
                      value: !_useGyroscope && !_useAccelerometer,
                      onChanged: (_) {},
                    ),
                    CheckboxListTile(
                      title: const Text('Gyroscope Mode (Racing)'),
                      subtitle: const Text('Tilt device to steer'),
                      value: _useGyroscope,
                      onChanged: (_) => _toggleGyroscope(service),
                    ),
                    CheckboxListTile(
                      title: const Text('Accelerometer Mode'),
                      subtitle: const Text('Tilt device to steer'),
                      value: _useAccelerometer,
                      onChanged: (_) => _toggleAccelerometer(service),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoystickSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Joystick Control',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: Consumer<ControllerConnectionService>(
                builder: (context, service, _) {
                  return JoystickWidget(
                    inputManager: _joystickManager,
                    size: 200,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Drag joystick to send input',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDisplay() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _useGyroscope ? 'Gyroscope Active' : 'Accelerometer Active',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.games,
                          size: 48,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _useGyroscope
                              ? 'Tilt your device to steer'
                              : 'Tilt your device to control',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
