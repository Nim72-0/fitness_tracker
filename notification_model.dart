import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String time; // HH:mm
  final String type;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final rawTs = data['timestamp'];
    final DateTime ts = rawTs is Timestamp
        ? rawTs.toDate()
        : rawTs is String
            ? DateTime.tryParse(rawTs) ?? DateTime.now()
            : DateTime.now();

    return AppNotification(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
      time: data['time'] ?? DateFormat('HH:mm').format(ts),
      type: data['type'] ?? 'general',
      timestamp: ts,
      isRead: data['isRead'] ?? false,
    );
  }

  // ✅ FIX: Set default empty string for id so you can call with just the map
  factory AppNotification.fromMap(Map<String, dynamic> map, [String id = '']) {
    final rawTs = map['timestamp'];
    final DateTime ts = rawTs is Timestamp
        ? rawTs.toDate()
        : rawTs is String
            ? DateTime.tryParse(rawTs) ?? DateTime.now()
            : DateTime.now();

    return AppNotification(
      id: id,
      title: map['title'] ?? 'Notification',
      body: map['body'] ?? '',
      time: map['time'] ?? DateFormat('HH:mm').format(ts),
      type: map['type'] ?? 'general',
      timestamp: ts,
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'time': time,
      'type': type,
      'timestamp': timestamp.toIso8601String(), // Changed for JSON safety
      'isRead': isRead,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? time,
    String? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// backward compatibility
typedef NotificationModel = AppNotification;

/// ❌ Flutter conflict avoid
class DailyNotificationTemplate {
  final String title;
  final String body;
  final String time;
  final String type;

  DailyNotificationTemplate(
    this.title,
    this.body,
    this.time, [
    this.type = 'general',
  ]);
}
