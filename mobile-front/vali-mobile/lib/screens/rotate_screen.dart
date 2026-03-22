import 'package:flutter/material.dart';

class RotateDeviceScreen extends StatelessWidget {
  const RotateDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rotating phone icon
              const Icon(
                Icons.screen_rotation_rounded,
                size: 80.0,
                color: Color(0xFF8AB4F8), // Light blue from your design
              ),
              
              const SizedBox(height: 32.0),
              
              // Title text
              const Text(
                'Rotate Device',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              
              const SizedBox(height: 16.0),
              
              // Subtitle text
              Text(
                'Please rotate your device to landscape\nmode for the best experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70, // Slightly dimmed for subtitle
                  fontSize: 16.0,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}