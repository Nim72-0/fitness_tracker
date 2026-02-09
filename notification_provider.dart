import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _userId;
  String _userGoal = 'weight_loss';

  void setUserId(String? uid) {
    _userId = uid;
  }

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _userId ??= prefs.getString('user_id');
    _userGoal = prefs.getString('user_goal') ?? 'weight_loss';

    if (_userId == null) {
      await _generateDemoNotifications();
    } else {
      await _loadFromFirestore();
      if (_notifications.isEmpty || _shouldGenerateNewNotifications()) {
        await _generateAndStoreNotifications();
      }
    }

    _notifications.sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromFirestore() async {
    try {
      final snap = await _firestore
          .collection('notifications')
          .doc(_userId)
          .collection('items')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _notifications =
          snap.docs.map(NotificationModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Notification load error: $e');
    }
  }

  Future<void> _generateAndStoreNotifications() async {
    final service = NotificationService();
    final templates = await service.getDailyNotifications(_userGoal);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final t in templates) {
      final parts = t.time.split(':');
      final notifTime = DateTime(
        today.year,
        today.month,
        today.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      if (notifTime.isBefore(now)) continue;

      final model = NotificationModel(
        id: '${_userGoal}_${t.time}_${notifTime.millisecondsSinceEpoch}',
        title: t.title,
        body: t.body,
        time: t.time,
        type: t.type,
        timestamp: notifTime,
      );

      await _firestore
          .collection('notifications')
          .doc(_userId)
          .collection('items')
          .doc(model.id)
          .set(model.toMap());

      _notifications.add(model);
    }
  }

  Future<void> _generateDemoNotifications() async {
    final service = NotificationService();
    final templates = await service.getDailyNotifications(_userGoal);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _notifications = templates.map((t) {
      final parts = t.time.split(':');
      final notifTime = DateTime(
        today.year,
        today.month,
        today.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      return NotificationModel(
        id: 'demo_${t.time}_${notifTime.millisecondsSinceEpoch}',
        title: t.title,
        body: t.body,
        time: t.time,
        type: t.type,
        timestamp: notifTime,
      );
    }).toList();
  }

  bool _shouldGenerateNewNotifications() {
    if (_notifications.isEmpty) return true;
    final last = _notifications.first.timestamp;
    final now = DateTime.now();
    return last.day != now.day;
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    _notifications[index] =
        _notifications[index].copyWith(isRead: true);
    notifyListeners();

    if (_userId != null) {
      await _firestore
          .collection('notifications')
          .doc(_userId)
          .collection('items')
          .doc(id)
          .update({'isRead': true});
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] =
            _notifications[i].copyWith(isRead: true);

        if (_userId != null) {
          await _firestore
              .collection('notifications')
              .doc(_userId)
              .collection('items')
              .doc(_notifications[i].id)
              .update({'isRead': true});
        }
      }
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();

    if (_userId != null) {
      final batch = _firestore.batch();
      final snap = await _firestore
          .collection('notifications')
          .doc(_userId)
          .collection('items')
          .get();

      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  List<NotificationModel> getUnreadNotifications() =>
      _notifications.where((n) => !n.isRead).toList();

  Future<void> deleteNotification(String id) async {
    await NotificationService().deleteNotification(id);
    _notifications.removeWhere((n) => n.id == id);
    if (_userId != null) {
      try {
        await _firestore
            .collection('notifications')
            .doc(_userId)
            .collection('items')
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint('Firestore delete error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> addCustomReminder(String title, String body, DateTime scheduledTime) async {
    await NotificationService().scheduleCustomReminder(
      title: title,
      body: body,
      scheduledTime: scheduledTime,
    );
    // After scheduling, refresh local history
    await loadNotifications(); 
  }
}
