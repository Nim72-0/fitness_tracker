// lib/models/gps_model.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Lightweight LatLng for model layer
class SimpleLatLng {
  final double latitude;
  final double longitude;

  const SimpleLatLng(this.latitude, this.longitude);

  LatLng toLatLng() => LatLng(latitude, longitude);

  @override
  String toString() => 'SimpleLatLng($latitude, $longitude)';
}

// ... SimpleLatLngBounds (no change needed as it uses SimpleLatLng) ...
class SimpleLatLngBounds {
  final SimpleLatLng southwest;
  final SimpleLatLng northeast;

  const SimpleLatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  @override
  String toString() =>
      'SimpleLatLngBounds(southwest: $southwest, northeast: $northeast)';
}

// ──────────────────────────────────────────────
// GPS Point (single location record)
class GPSPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitude; // meters
  final double? speed; // m/s

  GPSPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude,
    this.speed,
  });

  /// Convert to LatLng
  LatLng toLatLng() => LatLng(latitude, longitude);

  factory GPSPoint.fromMap(Map<String, dynamic> map) {
    return GPSPoint(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: GPSHelper._parseTimestamp(map['timestamp']),
      altitude: (map['altitude'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
    };
  }

  /// Haversine distance in meters
  static double calculateDistance(GPSPoint p1, GPSPoint p2) {
    const double earthRadius = 6371000;

    final lat1 = p1.latitude * pi / 180;
    final lon1 = p1.longitude * pi / 180;
    final lat2 = p2.latitude * pi / 180;
    final lon2 = p2.longitude * pi / 180;

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  String toString() =>
      'GPSPoint($latitude, $longitude, ${timestamp.toIso8601String()})';
}

// ──────────────────────────────────────────────
// GPS Route (saved workout)
class GPSRoute {
  final String? id;
  final String userId;
  final List<GPSPoint> points;
  final double distanceMeters;
  final double caloriesBurned;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;

  GPSRoute({
    this.id,
    required this.userId,
    required this.points,
    required this.distanceMeters,
    required this.caloriesBurned,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
  });

  factory GPSRoute.fromMap(Map<String, dynamic> data, {String? id}) {
    final pointsList = (data['points'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((p) => GPSPoint.fromMap(p))
        .toList();

    return GPSRoute(
      id: id,
      userId: data['userId'] as String? ?? '',
      points: pointsList,
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      startTime: GPSHelper._parseTimestamp(data['startTime']),
      endTime: GPSHelper._parseTimestamp(data['endTime'] ?? data['startTime']),
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  factory GPSRoute.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GPSRoute.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'points': points.map((p) => p.toMap()).toList(),
      'distanceMeters': distanceMeters,
      'caloriesBurned': caloriesBurned,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationSeconds': durationSeconds,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  double get distanceKm => distanceMeters / 1000;

  String get formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;

    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  double get averageSpeedKmh {
    if (durationSeconds <= 0) return 0.0;
    return distanceKm / (durationSeconds / 3600);
  }

  String get displayTitle =>
      '${distanceKm.toStringAsFixed(2)} km • ${caloriesBurned.round()} kcal';

  String get displaySubtitle =>
      '$formattedDuration • ${startTime.toString().split('.').first}';

  /// Google Maps points for polylines
  List<LatLng> get latLngPoints => points.map((p) => p.toLatLng()).toList();

  @override
  String toString() =>
      'GPSRoute($id, ${points.length} pts, ${distanceKm.toStringAsFixed(2)}km)';
}

// ──────────────────────────────────────────────
// Helpers
class GPSHelper {
  static double calculateCalories(double distanceKm, double weightKg) {
    const double met = 8.0;
    const double hours = 1.0 / 60.0; // per minute
    return distanceKm * met * weightKg * hours * 60;
  }

  static SimpleLatLng getCenterPoint(List<GPSPoint> points) {
    if (points.isEmpty) return const SimpleLatLng(0.0, 0.0);

    double sumLat = 0, sumLng = 0;
    for (var p in points) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    return SimpleLatLng(sumLat / points.length, sumLng / points.length);
  }

  static SimpleLatLngBounds getBounds(List<GPSPoint> points) {
    if (points.isEmpty) {
      return const SimpleLatLngBounds(
        southwest: SimpleLatLng(0, 0),
        northeast: SimpleLatLng(0, 0),
      );
    }

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return SimpleLatLngBounds(
      southwest: SimpleLatLng(minLat, minLng),
      northeast: SimpleLatLng(maxLat, maxLng),
    );
  }

  /// Safely parse Firestore Timestamps, DateTimes, or String dates
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
