import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:game_controller/providers/controller_provider.dart';
import 'package:game_controller/screens/splash_screen.dart';
import 'package:game_controller/screens/controller_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ControllerProvider()),
      ],
      child: MaterialApp(
        title: 'Game Controller',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A1428),
        ),
        home: const SplashScreen(),
        routes: {
          '/controller': (context) => const ControllerScreen(),
          '/splash': (context) => const SplashScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
