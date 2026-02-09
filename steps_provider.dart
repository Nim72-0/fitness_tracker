import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/step_model.dart';
import '../services/pedometer_service.dart';
import '../services/notification_service.dart';

class StepsProvider extends ChangeNotifier {
  StepModel _todaySteps = StepModel.today();
  StepModel get todaySteps => _todaySteps;
  
  // ✅ Requested: Convenience getters for UI compatibility
  int get steps => _todaySteps.steps;
  int get goal => _todaySteps.goal;

  // ✅ Requested: Update steps manually or from service
  void updateSteps(int newSteps) {
    if (newSteps != _todaySteps.steps) {
      _todaySteps = _todaySteps.copyWith(steps: newSteps);
      notifyListeners();
      _saveToLocal(_todaySteps);
      if (_userId != null) _saveToFirestore(_todaySteps);
    }
  }
  
  double get progressPercentage {
    if (goal == 0) return 0;
    return (steps / goal).clamp(0.0, 1.0);
  }

  List<StepModel> _history = [];
  List<StepModel> get history => _history;

  String? _userId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PedometerService _pedometerService = PedometerService();
  StreamSubscription<int>? _stepStreamSub;

  bool _isGoalNotificationSent = false;

  // ==========================
  // INITIALIZATION
  // ==========================
  void setUserId(String? uid) async {
    _userId = uid;
    _initPedometerService();
    await fetchTodaySteps();
    notifyListeners();
  }

  void _initPedometerService() async {
    // Web check: Pedometer is not supported on web
    if (kIsWeb) return;

    await _pedometerService.init();
    
    _stepStreamSub = _pedometerService.stepCountStream.listen((sensorSteps) {
      updateSteps(sensorSteps);
    });
  }

  @override
  void dispose() {
    _stepStreamSub?.cancel();
    super.dispose();
  }

  // ==========================
  // SENSOR UPDATE LOGIC
  // ==========================
  void _updateFromSensor(int sensorSteps) async {
    // 1. Update the model with sensor steps
    // Note: We might want to keep "manual" steps separate if we wanted intricate logic, 
    // but here we trust the service to give us the "Daily Total".
    
    // Check for new day inside provider too, just in case
    if (!_isSameDay(_todaySteps.date, DateTime.now())) {
      _todaySteps = StepModel.today(goal: _todaySteps.goal);
      _isGoalNotificationSent = false;
    }

    final updated = _todaySteps.copyWith(
      steps: sensorSteps,
      // Recalculate derived
    );
    
    _todaySteps = updated;
    notifyListeners();
    
    // 2. Local Persistence (Debounced slightly ideally, but direct here for simplicity)
    await _saveToLocal(_todaySteps);

    // 3. Firestore (Only periodically or on significant change?)
    // For now, let's update. In prod, maybe debounce this.
    if (_userId != null) {
      await _saveToFirestore(_todaySteps);
    }

    // 4. Check Goal
    _checkGoalAchievement();
  }

  void _checkGoalAchievement() async {
    if (_todaySteps.steps >= _todaySteps.goal && !_isGoalNotificationSent) {
      _isGoalNotificationSent = true;
      await NotificationService().showNotification(
        'Goal Smashed! 🏃🔥', 
        'You reached your daily goal of ${_todaySteps.goal} steps!',
        type: 'goal_reached'
      );
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // ==========================
  // GOAL LOGIC
  // ==========================
  Future<void> updateGoal(int newGoal) async {
    _todaySteps = _todaySteps.setGoal(newGoal);
    notifyListeners();
    await _saveToLocal(_todaySteps);
    if (_userId != null) await _saveToFirestore(_todaySteps);
  }

  void setGoalBasedOnUserType(String goalType) {
    int target = 10000;
    switch (goalType.toLowerCase()) {
      case 'weight_loss': target = 12000; break;
      case 'muscle_gain': target = 8000; break;
      case 'weight_gain': target = 6000; break;
      case 'maintenance': target = 10000; break;
    }
    updateGoal(target);
  }

  // ==========================
  // FETCH TODAY STEPS
  // ==========================
  Future<void> fetchTodaySteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 🔹 Load cached first
      final cached = prefs.getString('today_steps');
      if (cached != null) {
        final loaded = StepModel.fromCacheString(cached);
        // Check if it's today
        if (_isSameDay(loaded.date, DateTime.now())) {
          _todaySteps = loaded;
        } else {
          // It's old data, reset but keep goal
          _todaySteps = StepModel.today(goal: loaded.goal); 
        }
        notifyListeners();
      }

      if (_userId == null) return;

      // 🔹 Fetch today from Firestore
      final docId = _docId(DateTime.now());
      final docRef = _db
          .collection('users')
          .doc(_userId)
          .collection('steps')
          .doc(docId);

      final snap = await docRef.get();

      if (snap.exists && snap.data() != null) {
        final firestoreData = StepModel.fromDailyStats(snap.data()!);
        // We prefer the larger value if sensor was running offline
        if (firestoreData.steps > _todaySteps.steps) {
           _todaySteps = firestoreData;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("⚠ fetchTodaySteps error: $e");
    }
  }

  // ==========================
  // FETCH HISTORY
  // ==========================
  Future<void> fetchHistory({int limit = 7}) async {
    if (_userId == null) return;
    try {
      final querySnap = await _db
          .collection('users')
          .doc(_userId)
          .collection('steps')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      _history = querySnap.docs
          .map((d) => StepModel.fromDailyStats(d.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint("⚠ fetchHistory error: $e");
    }
  }

  // ==========================
  // ADD STEPS (Manual)
  // ==========================
  Future<void> addManualSteps(int steps) async {
    // We delegate to service so it handles the "Offset" logic correctly
    _pedometerService.addManualSteps(steps);
    // The listener on stream will pick it up and run _updateFromSensor
  }

  // ==========================
  // PERSISTENCE HELPERS
  // ==========================
  Future<void> _saveToLocal(StepModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('today_steps', model.toCacheString());
  }

  Future<void> _saveToFirestore(StepModel model) async {
    if (_userId == null) return;
    try {
      final docId = _docId(model.date);
      await _db
          .collection('users')
          .doc(_userId)
          .collection('steps')
          .doc(docId)
          .set(model.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("⚠ Firestore write error: $e");
    }
  }

  String _docId(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}
