import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:permission_handler/permission_handler.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;

  late SharedPreferences _prefs;
  
  // Stream Controllers
  final StreamController<int> _stepCountController = StreamController<int>.broadcast();
  final StreamController<String> _pedestrianStatusController = StreamController<String>.broadcast();

  Stream<int> get stepCountStream => _stepCountController.stream;
  Stream<String> get pedestrianStatusStream => _pedestrianStatusController.stream;

  // Variables
  int _dailySteps = 0; // Steps taken today
  int _stepsAtReset = 0; // Sensor value when we last reset (or start of day)
  final int _lastSavedSteps = 0; 
  String _status = 'unknown';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // ✅ Request runtime permission for Android 10+
    await Permission.activityRecognition.request();
    
    _prefs = await SharedPreferences.getInstance();
    
    // Load saved state
    _dailySteps = _prefs.getInt('daily_steps') ?? 0;
    _stepsAtReset = _prefs.getInt('steps_at_reset') ?? 0;
    
    // Check if new day
    _checkNewDay();

    _initPedometer();
    _isInitialized = true;
  }

  void _checkNewDay() {
    final lastDay = _prefs.getString('last_step_day');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastDay != today) {
      // It's a new day, reset daily steps
      _dailySteps = 0;
      // We'll update _stepsAtReset when the first sensor event comes in
      _prefs.setString('last_step_day', today);
      _saveData();
    }
  }

  void _initPedometer() {
    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );
    
    _statusSubscription = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatus,
      onError: _onPedestrianStatusError,
    );
  }

  void _onStepCount(StepCount event) {
    if (_stepsAtReset == 0) {
      // First event after install or reboot logic (simplified)
      // If we have 0 daily steps, assume this is the baseline
       if (_dailySteps == 0) {
         _stepsAtReset = event.steps;
         _prefs.setInt('steps_at_reset', _stepsAtReset);
       } else {
         // If we have daily steps but lost offset (e.g. reboot), 
         // try to reconstruct offset: Offset = Current - Daily
         _stepsAtReset = event.steps - _dailySteps;
       }
    }

    // Handle Reboot (Sensor resets to 0)
    if (event.steps < _stepsAtReset) {
      _stepsAtReset = 0; // Reset offset as sensor reset
      _dailySteps += event.steps; // Add whatever these new steps are
    } else {
      _dailySteps = event.steps - _stepsAtReset;
    }
    
    // Prevent negative
    if (_dailySteps < 0) _dailySteps = 0;

    _stepCountController.add(_dailySteps);
    _saveData();
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _status = event.status;
    _pedestrianStatusController.add(_status);
  }

  void _onStepCountError(error) {
    debugPrint('Pedometer Error: $error');
    _stepCountController.add(_dailySteps); // Emit last known
  }

  void _onPedestrianStatusError(error) {
    debugPrint('Pedestrian Status Error: $error');
    _pedestrianStatusController.add('unknown');
  }

  Future<void> _saveData() async {
    await _prefs.setInt('daily_steps', _dailySteps);
    await _prefs.setInt('steps_at_reset', _stepsAtReset);
  }

  // Allow manual addition (for testing or non-sensor steps)
  void addManualSteps(int count) {
    _dailySteps += count;
    // Adjust offset so sensor doesn't overwrite manual
    // Equation: Daily = Sensor - Offset
    // NewDaily = Sensor - NewOffset => NewOffset = Sensor - NewDaily
    // But we don't have current sensor value here easily without storing it. 
    // Simplified: Just add to daily and trust next sensor event to recalculate? 
    // No, next sensor event will interpret based on old offset. 
    // We strictly need to shift the offset DOWN by 'count' to increase result.
    _stepsAtReset -= count;
    
    _stepCountController.add(_dailySteps);
    _saveData();
  }

  int get currentSteps => _dailySteps;
  String get status => _status;
}
