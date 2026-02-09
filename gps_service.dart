import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../models/gps_model.dart';
import 'firestore_service.dart';

typedef GPSServiceErrorCallback = void Function(String message);

class GPSService extends ChangeNotifier {
  final double distanceFilter; // meters
  final double weightKg;       // for calories
  final GPSServiceErrorCallback? onError;

  GPSService({
    this.distanceFilter = 5.0,
    this.weightKg = 70.0,
    this.onError,
  });

  // ──────────────────────────────────────────────
  // State
  // ──────────────────────────────────────────────
  final List<GPSPoint> _points = [];
  List<GPSPoint> get points => List.unmodifiable(_points);

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  double _totalDistance = 0.0;
  double get totalDistance => _totalDistance;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  double _calories = 0.0;
  double get calories => _calories;

  DateTime? _startTime;
  DateTime? get startTime => _startTime;

  DateTime? _endTime;
  DateTime? get endTime => _endTime;

  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;

  String? _userId;
  String? get userId => _userId;

  // ──────────────────────────────────────────────
  // User Setup
  // ──────────────────────────────────────────────
  void setUserId(String? uid) {
    _userId = uid;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Start Tracking
  // ──────────────────────────────────────────────
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      // 1. Location services check
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          onError?.call("Location services are disabled. Please enable them.");
          return false;
        }
      }

      // 2. Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          (permission != LocationPermission.always &&
              permission != LocationPermission.whileInUse)) {
        onError?.call("Location permission denied. Please allow access.");
        return false;
      }

      // 3. Reset state
      _points.clear();
      _totalDistance = 0.0;
      _calories = 0.0;
      _duration = Duration.zero;
      _startTime = DateTime.now();
      _endTime = null;
      _isTracking = true;

      notifyListeners();

      // 4. Duration timer
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_startTime != null && _isTracking) {
          _duration = DateTime.now().difference(_startTime!);
          notifyListeners();
        }
      });

      // 5. Position stream
      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: distanceFilter.toInt(),
          timeLimit: const Duration(seconds: 10),
        ),
      ).listen(
        (Position pos) {
          if (!_isTracking) return;

          final newPoint = GPSPoint(
            latitude: pos.latitude,
            longitude: pos.longitude,
            timestamp: pos.timestamp ?? DateTime.now(),
            altitude: pos.altitude,
            speed: pos.speed,
          );

          if (_points.isNotEmpty) {
            _totalDistance += GPSPoint.calculateDistance(_points.last, newPoint);
            _calories = GPSHelper.calculateCalories(_totalDistance / 1000, weightKg);
          }

          _points.add(newPoint);
          _endTime = DateTime.now();
          notifyListeners();
        },
        onError: (err) {
          final msg = "Location tracking error: $err";
          debugPrint(msg);
          onError?.call(msg);
          stopTracking();
        },
      );

      return true;
    } catch (e) {
      final msg = "Failed to start tracking: $e";
      debugPrint(msg);
      onError?.call(msg);
      _isTracking = false;
      notifyListeners();
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Stop Tracking
  // ──────────────────────────────────────────────
  void stopTracking() {
    if (!_isTracking) return;

    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _endTime ??= DateTime.now();

    if (_startTime != null) {
      _duration = _endTime!.difference(_startTime!);
    }

    _calories = GPSHelper.calculateCalories(_totalDistance / 1000, weightKg);
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Reset Everything
  // ──────────────────────────────────────────────
  void reset() {
    stopTracking();
    _points.clear();
    _totalDistance = 0.0;
    _calories = 0.0;
    _duration = Duration.zero;
    _startTime = null;
    _endTime = null;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Save Route to Firestore
  // ──────────────────────────────────────────────
  Future<bool> saveRoute() async {
    if (_userId == null || _points.isEmpty || _startTime == null) {
      onError?.call("No route data available or user not set");
      return false;
    }

    try {
      final route = GPSRoute(
        userId: _userId!,
        points: List<GPSPoint>.from(_points),
        distanceMeters: _totalDistance,
        caloriesBurned: _calories,
        startTime: _startTime!,
        endTime: _endTime ?? DateTime.now(),
        durationSeconds: _duration.inSeconds,
      );

      final firestore = FirestoreService();
      await firestore.saveGPSRoute(_userId!, route);

      onError?.call("Route saved successfully!");
      return true;
    } catch (e) {
      final msg = "Error saving route: $e";
      debugPrint(msg);
      onError?.call(msg);
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Map Helpers
  // ──────────────────────────────────────────────
  List<LatLng> get latLngPoints => _points.map((p) => p.toLatLng()).toList();

  double? get currentSpeedKmh {
    if (_points.length < 2) return null;

    final p1 = _points[_points.length - 2];
    final p2 = _points.last;

    final seconds = p2.timestamp.difference(p1.timestamp).inSeconds;
    if (seconds <= 0) return 0.0;

    final meters = GPSPoint.calculateDistance(p1, p2);
    return (meters / seconds) * 3.6; // m/s → km/h
  }

  String get currentPaceMinKm {
    final speed = currentSpeedKmh;
    if (speed == null || speed <= 0) return '--:--';

    final pace = 60 / speed;
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return '$min:${sec.toString().padLeft(2, '0')} min/km';
  }

  double get distanceKm => _totalDistance / 1000;

  String get formattedDuration {
    final h = _duration.inHours;
    final m = _duration.inMinutes.remainder(60);
    final s = _duration.inSeconds.remainder(60);

    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  // ──────────────────────────────────────────────
  // Cleanup
  // ──────────────────────────────────────────────
  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}

// ──────────────────────────────────────────────
// Static Helper for Calories (consistent across app)
// ──────────────────────────────────────────────
class GPSHelper {
  static double calculateCalories(double distanceKm, double weightKg) {
    // MET ≈ 8.0 for moderate running/walking (adjustable)
    const double met = 8.0;
    const double hours = 1.0 / 60.0; // per minute
    return distanceKm * met * weightKg * hours * 60;
  }
}