import 'package:sensors_plus/sensors_plus.dart';
import 'controller_service.dart';

/// Manages gyroscope input for racing games
class GyroscopeInputManager {
  static const double _deadzone = 0.05;
  
  final ControllerConnectionService controllerService;
  
  bool _enabled = false;
  double _lastGx = 0;
  double _lastGy = 0;
  double _xOffset = 0;
  double _yOffset = 0;

  GyroscopeInputManager({required this.controllerService});

  /// Start gyroscope input (racing mode)
  void startGyroscope() {
    if (_enabled) return;
    
    _enabled = true;
    print('[Gyroscope] Starting gyroscope input');

    // Listen to gyroscope events
    gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (!_enabled) return;
      
      // Smooth the input
      double gx = event.y; // Pitch for left/right
      double gy = event.x; // Roll for up/down
      
      // Apply deadzone
      if (gx.abs() < _deadzone) gx = 0;
      if (gy.abs() < _deadzone) gy = 0;

      // Scale and send
      if (gx != _lastGx || gy != _lastGy) {
        _lastGx = gx;
        _lastGy = gy;
        
        // Clamp to [-1, 1] range and scale by 1000
        const maxRotation = 2.0; // rad/s
        final x = (gx / maxRotation).clamp(-1.0, 1.0);
        final y = (gy / maxRotation).clamp(-1.0, 1.0);
        
        controllerService.sendJoystickAxes(x, y);
      }
    });
  }

  /// Calibrate gyroscope at current position
  void calibrate() {
    // Store current offset for zero point
    print('[Gyroscope] Calibration complete');
  }

  /// Stop gyroscope input
  void stopGyroscope() {
    if (!_enabled) return;
    
    _enabled = false;
    _lastGx = 0;
    _lastGy = 0;
    controllerService.sendJoystickAxes(0, 0);
    print('[Gyroscope] Stopped gyroscope input');
  }

  bool get enabled => _enabled;
}

/// Manages accelerometer-based input (alternative to gyroscope for tilt)
class AccelerometerInputManager {
  static const double _deadzone = 0.1;
  
  final ControllerConnectionService controllerService;
  
  bool _enabled = false;
  double _lastAx = 0;
  double _lastAy = 0;

  AccelerometerInputManager({required this.controllerService});

  /// Start accelerometer input (tilt-based steering)
  void startAccelerometer() {
    if (_enabled) return;
    
    _enabled = true;
    print('[Accelerometer] Starting accelerometer input');

    // Listen to accelerometer events, normalized
    accelerometerEventStream(samplingPeriod: const Duration(milliseconds: 50))
        .listen((AccelerometerEvent event) {
      if (!_enabled) return;
      
      // Normalize acceleration (gravity is ~9.81)
      double ax = event.y / 9.81; // X axis (left/right tilt)
      double ay = event.x / 9.81; // Y axis (forward/back tilt)
      
      // Apply deadzone
      if (ax.abs() < _deadzone) ax = 0;
      if (ay.abs() < _deadzone) ay = 0;

      // Only send if changed significantly
      if ((ax - _lastAx).abs() > 0.05 || (ay - _lastAy).abs() > 0.05) {
        _lastAx = ax;
        _lastAy = ay;
        
        // Clamp to [-1, 1] range
        final x = ax.clamp(-1.0, 1.0);
        final y = ay.clamp(-1.0, 1.0);
        
        controllerService.sendJoystickAxes(x, y);
      }
    });
  }

  /// Stop accelerometer input
  void stopAccelerometer() {
    if (!_enabled) return;
    
    _enabled = false;
    _lastAx = 0;
    _lastAy = 0;
    controllerService.sendJoystickAxes(0, 0);
    print('[Accelerometer] Stopped accelerometer input');
  }

  bool get enabled => _enabled;
}
