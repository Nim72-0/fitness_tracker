import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/gps_model.dart';

class GPSProvider extends ChangeNotifier {
  final double distanceFilter; // meters
  final double weightKg; // for calorie calculation
  final void Function(String message)? onError;

  GPSProvider({
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

  // ✅ Requested: Real-time lat/lng getters
  double get latitude => _points.isNotEmpty ? _points.last.latitude : 0.0;
  double get longitude => _points.isNotEmpty ? _points.last.longitude : 0.0;

  // ✅ Requested: Manual/Service location update
  void updateLocation(double lat, double lng) {
    final newPoint = GPSPoint(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
    );

    if (_points.isNotEmpty) {
      _totalDistance += GPSPoint.calculateDistance(_points.last, newPoint);
    }

    _points.add(newPoint);
    _endTime = DateTime.now();
    notifyListeners();
    _saveLastLocation(lat, lng);
  }

  Future<void> _saveLastLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', lat);
    await prefs.setDouble('last_lng', lng);
  }

  Future<void> loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble('last_lat');
    double? lng = prefs.getDouble('last_lng');
    if (lat != null && lng != null) {
      _points.add(GPSPoint(latitude: lat, longitude: lng, timestamp: DateTime.now()));
      notifyListeners();
    }
  }

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

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
    if (uid == null || uid.isEmpty) return;

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
      _duration = Duration.zero;
      _startTime = DateTime.now();
      _endTime = null;
      _isTracking = true;

      notifyListeners();

      // 4. Duration timer (every second update)
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

          updateLocation(pos.latitude, pos.longitude);
        },
        onError: (err) {
          onError?.call("Location tracking error: $err");
          stopTracking();
        },
      );

      return true;
    } catch (e) {
      onError?.call("Failed to start tracking: $e");
      _isTracking = false;
      notifyListeners();
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Stop & Reset
  // ──────────────────────────────────────────────
  void stopTracking() {
    if (!_isTracking) return;

    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _endTime = DateTime.now();

    notifyListeners();
  }

  void reset() {
    stopTracking();
    _points.clear();
    _totalDistance = 0.0;
    _duration = Duration.zero;
    _startTime = null;
    _endTime = null;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Calculations
  // ──────────────────────────────────────────────
  double get caloriesBurned {
    final km = totalDistance / 1000;
    return GPSHelper.calculateCalories(km, weightKg);
  }

  double? get currentSpeedKmh {
    if (_points.length < 2) return null;

    final last = _points.last;
    final prev = _points[_points.length - 2];

    final seconds = last.timestamp.difference(prev.timestamp).inSeconds;
    if (seconds <= 0) return 0.0;

    final meters = GPSPoint.calculateDistance(prev, last);
    return (meters / seconds) * 3.6;
  }

  String get currentPaceMinKm {
    final speed = currentSpeedKmh;
    if (speed == null || speed <= 0) return '--:--';

    final pace = 60 / speed;
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return '$min:${sec.toString().padLeft(2, '0')}';
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
        distanceMeters: totalDistance,
        caloriesBurned: caloriesBurned,
        startTime: _startTime!,
        endTime: _endTime ?? DateTime.now(),
        durationSeconds: duration.inSeconds,
      );

      await FirebaseFirestore.instance
          .collection('gps_routes')
          .doc(_userId)
          .collection('routes')
          .add(route.toMap());

      onError?.call("Route saved successfully!");
      return true;
    } catch (e) {
      onError?.call("Failed to save route: $e");
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Fetch Recent Routes
  // ──────────────────────────────────────────────
  Future<List<GPSRoute>> fetchRecentRoutes({int limit = 10}) async {
    if (_userId == null) return [];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('gps_routes')
          .doc(_userId)
          .collection('routes')
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        return GPSRoute.fromMap(data);
      }).toList();
    } catch (e) {
      onError?.call("Failed to load routes: $e");
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // Map Helpers (for Google Maps UI)
  // ──────────────────────────────────────────────
  List<LatLng> get latLngPoints {
    return _points.map((p) => LatLng(p.latitude, p.longitude)).toList();
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
// Static Helper (for calories)
// ──────────────────────────────────────────────
class GPSHelper {
  static double calculateCalories(double km, double weightKg) {
    // Approx: MET 5.0 for moderate running/walking
    const met = 5.0;
    const hours = 1.0 / 60.0; // per minute
    return km * met * weightKg * hours;
  }
}