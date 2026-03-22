import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/touch_button.dart';
import '../widgets/virtual_joystick.dart';
import '../services/input_service.dart';

class GamepadScreen extends StatefulWidget {
  const GamepadScreen({super.key});

  @override
  State<GamepadScreen> createState() => _GamepadScreenState();
}

class _GamepadScreenState extends State<GamepadScreen> {
  final InputService inputService = InputService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isDisposed = false;
  String? _currentlyHeldButton; 
  String _hudMessage = "Voice Active. Say 'Hold L1'";

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initAndStartSpeech();
  }

  Future<void> _initAndStartSpeech() async {
    bool isAvailable = await _speech.initialize(
      onError: (val) async {
        if (!_isDisposed) {
          await Future.delayed(const Duration(milliseconds: 300));
          _startListening();
        }
      },
      onStatus: (status) async {
        if ((status == 'done' || status == 'notListening') && !_isDisposed) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (!_isDisposed) _startListening();
        }
      },
    );

    if (isAvailable && !_isDisposed) {
      _startListening(); 
    }
  }

  void _startListening() async {
    if (_isDisposed) return;
    try {
      await _speech.listen(
        onResult: (result) => _processSpokenWords(result.recognizedWords),
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: false, 
          partialResults: true,
          listenMode: stt.ListenMode.dictation, 
        ),
      );
    } catch (e) {
      debugPrint("Failed to start listening: $e");
    }
  }

  void _processSpokenWords(String spokenText) {
    String cleanText = spokenText.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
    List<String> words = cleanText.split(RegExp(r'\s+'));

    if ((words.contains('release') || words.contains('stop')) && _currentlyHeldButton != null) {
      inputService.sendButtonRelease(_currentlyHeldButton!);
      setState(() {
        _hudMessage = "Released $_currentlyHeldButton";
        _currentlyHeldButton = null;
      });
      _speech.cancel(); 
      _startListening();
      return; 
    }

    if (words.contains('hold')) {
      String? targetButtonId;
      if (cleanText.contains('l1') || cleanText.contains('l 1') || cleanText.contains('left bumper')) targetButtonId = 'L1';
      else if (cleanText.contains('l2') || cleanText.contains('l 2') || cleanText.contains('left trigger')) targetButtonId = 'L2';
      else if (cleanText.contains('r1') || cleanText.contains('r 1') || cleanText.contains('right bumper')) targetButtonId = 'R1';
      else if (cleanText.contains('r2') || cleanText.contains('r 2') || cleanText.contains('right trigger')) targetButtonId = 'R2';

      if (targetButtonId != null && targetButtonId != _currentlyHeldButton) {
        if (_currentlyHeldButton != null) inputService.sendButtonRelease(_currentlyHeldButton!);
        inputService.sendButtonPress(targetButtonId);
        setState(() {
          _currentlyHeldButton = targetButtonId;
          _hudMessage = "Holding $targetButtonId...";
        });
        _speech.cancel();
        _startListening();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // BACKGROUND IMAGE
          Center(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/controller_bg.png',
                width: 450,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // UI LAYER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 40.0),
              child: Column(
                children: [
                  // TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white54, size: 32),
                        onPressed: () => inputService.sendButtonPress('SELECT'),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: _currentlyHeldButton != null 
                              ? Colors.red.withValues(alpha: 0.3) 
                              : const Color(0xFF1E2329).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: _currentlyHeldButton != null ? Colors.redAccent : Colors.cyanAccent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _hudMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentlyHeldButton != null ? Colors.white : Colors.cyanAccent, 
                            fontSize: 14, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white54, size: 32),
                        onPressed: () => inputService.sendButtonPress('START'),
                      ),
                    ],
                  ),
                  
                  const Spacer(),

                  // BOTTOM CONTROLS (XBOX STYLE LAYOUT)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // LEFT SIDE: Stick UP, D-Pad DOWN
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -80), // Left Stick is now HIGH
                            child: VirtualJoystick(onUpdate: (x, y) => inputService.sendJoystickUpdate('LEFT', x, y)),
                          ),
                          const SizedBox(width: 20),
                          Transform.translate(
                            offset: const Offset(0, 0), // D-Pad is now LOW
                            child: _buildDPad(),
                          ),
                        ],
                      ),
                      // RIGHT SIDE: Stick LOW, Buttons UP
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, 0), // Right Stick stays LOW
                            child: VirtualJoystick(onUpdate: (x, y) => inputService.sendJoystickUpdate('RIGHT', x, y)),
                          ),
                          const SizedBox(width: 20),
                          Transform.translate(
                            offset: const Offset(0, -80), // Action Buttons stay HIGH
                            child: _buildActionButtons(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDPad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TouchButton(color: Colors.grey, onPressed: () => inputService.sendButtonPress('DPAD_UP'), onReleased: () => inputService.sendButtonRelease('DPAD_UP'), child: const Icon(Icons.keyboard_arrow_up, color: Colors.grey, size: 36)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TouchButton(color: Colors.grey, onPressed: () => inputService.sendButtonPress('DPAD_LEFT'), onReleased: () => inputService.sendButtonRelease('DPAD_LEFT'), child: const Icon(Icons.keyboard_arrow_left, color: Colors.grey, size: 36)),
            const SizedBox(width: 50),
            TouchButton(color: Colors.grey, onPressed: () => inputService.sendButtonPress('DPAD_RIGHT'), onReleased: () => inputService.sendButtonRelease('DPAD_RIGHT'), child: const Icon(Icons.keyboard_arrow_right, color: Colors.grey, size: 36)),
          ],
        ),
        TouchButton(color: Colors.grey, onPressed: () => inputService.sendButtonPress('DPAD_DOWN'), onReleased: () => inputService.sendButtonRelease('DPAD_DOWN'), child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 36)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: 170, height: 170,
      child: Stack(
        children: [
          Positioned(top: 0, left: 55, child: TouchButton(color: Colors.yellow, onPressed: () => inputService.sendButtonPress('Y'), onReleased: () => inputService.sendButtonRelease('Y'), child: const Text('Y', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.yellow)))),
          Positioned(bottom: 0, left: 55, child: TouchButton(color: Colors.green, onPressed: () => inputService.sendButtonPress('A'), onReleased: () => inputService.sendButtonRelease('A'), child: const Text('A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)))),
          Positioned(left: 0, top: 55, child: TouchButton(color: Colors.blue, onPressed: () => inputService.sendButtonPress('X'), onReleased: () => inputService.sendButtonRelease('X'), child: const Text('X', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)))),
          Positioned(right: 0, top: 55, child: TouchButton(color: Colors.red, onPressed: () => inputService.sendButtonPress('B'), onReleased: () => inputService.sendButtonRelease('B'), child: const Text('B', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)))),
        ],
      ),
    );
  }
}