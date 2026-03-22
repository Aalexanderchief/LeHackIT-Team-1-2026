import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/gamepad_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force landscape orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const VirtualControllerApp());
  });
}

class VirtualControllerApp extends StatelessWidget {
  const VirtualControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const GamepadScreen(),
    );
  }
}