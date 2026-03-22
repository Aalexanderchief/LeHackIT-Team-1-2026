import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:game_controller/providers/controller_provider.dart';
import 'package:game_controller/widgets/controller_widgets.dart';
import 'package:game_controller/utils/controller_logger.dart';

/// Main landscape controller screen
class ControllerScreen extends StatefulWidget {
  const ControllerScreen({Key? key}) : super(key: key);

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  @override
  void initState() {
    super.initState();
    ControllerLogger.logAppEvent('Controller screen loaded');
    // Force landscape orientation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    ControllerLogger.logAppEvent('Controller screen disposed');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1428),
      body: SafeArea(
        child: Column(
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Refined Landscape Controller',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Main controller area with border
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.purple.shade300,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Consumer<ControllerProvider>(
                    builder: (context, controller, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side - D-Pad and Left Stick
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // D-Pad
                              DPadWidget(controller: controller),
                              const SizedBox(height: 16),
                              // Left Stick
                              LeftStickWidget(controller: controller),
                            ],
                          ),

                          // Right side - Face Buttons and Right Stick
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Face Buttons (ABXY)
                              FaceButtonsWidget(controller: controller),
                              const SizedBox(height: 16),
                              // Right Stick
                              RightStickWidget(controller: controller),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
