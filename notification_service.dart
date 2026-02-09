import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_model.dart';

import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// ✅ FIX: Proper typed history
  final List<AppNotification> _notificationHistory = [];

  // ───────────────────── INIT ─────────────────────
  Future<void> init() async {
    if (_isInitialized) return;

    // ✅ Request runtime permission for Android 13+
    await Permission.notification.request();

    tz_data.initializeTimeZones();
    _prefs = await SharedPreferences.getInstance();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    await _loadNotificationHistory();
    _isInitialized = true;
  }

  // ───────────────────── STATUS ─────────────────────
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await init();
    return true;
  }

  // ───────────────────── INSTANT ─────────────────────
  Future<void> showNotification(
    String title,
    String body, {
    bool storeInHistory = true,
    String type = 'instant',
  }) async {
    if (!_isInitialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'fitness_main_channel',
      'Fitness Notifications',
      channelDescription: 'Fitness notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );

    if (storeInHistory) {
      _addToHistory(
        AppNotification(
          id: 'instant_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          body: body,
          time:
              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          type: type,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // ───────────────────── DAILY ROUTINE & PRAYERS ─────────────────────
  Future<List<AppNotification>> getDailyNotifications(String userGoal) async {
    if (!_isInitialized) await init();

    final List<AppNotification> notifications = [];
    final now = DateTime.now();
    DateTime today(int h, int m) => DateTime(now.year, now.month, now.day, h, m);

    // 1. PRAYERS (Fixed Approximate Times)
    notifications.addAll([
      AppNotification(id: 'pray_fajr', title: 'Fajr Prayer 🕌', body: 'Time for Fajr prayer.', type: 'prayer', time: '05:00', timestamp: today(5, 0)),
      AppNotification(id: 'pray_dhuhr', title: 'Dhuhr Prayer 🕌', body: 'Time for Dhuhr prayer.', type: 'prayer', time: '13:00', timestamp: today(13, 0)),
      AppNotification(id: 'pray_asr', title: 'Asr Prayer 🕌', body: 'Time for Asr prayer.', type: 'prayer', time: '16:30', timestamp: today(16, 30)),
      AppNotification(id: 'pray_maghrib', title: 'Maghrib Prayer 🕌', body: 'Time for Maghrib prayer.', type: 'prayer', time: '18:30', timestamp: today(18, 30)),
      AppNotification(id: 'pray_isha', title: 'Isha Prayer 🕌', body: 'Time for Isha prayer.', type: 'prayer', time: '20:30', timestamp: today(20, 30)),
    ]);

    // 2. DAILY ROUTINE (Meals, Sleep, Walk)
    notifications.addAll([
      AppNotification(id: 'routine_wake', title: 'Good Morning! ☀️', body: 'Start your day with a smile and a glass of water.', type: 'greeting', time: '06:00', timestamp: today(6, 0)),
      AppNotification(id: 'routine_walk', title: 'Morning Walk 🚶', body: 'Time for a refreshing morning walk.', type: 'workout', time: '06:30', timestamp: today(6, 30)),
      AppNotification(id: 'routine_break', title: 'Breakfast 🍳', body: 'Fuel your body with a healthy breakfast.', type: 'nutrition', time: '08:00', timestamp: today(8, 0)),
      AppNotification(id: 'routine_lunch', title: 'Lunch Time 🥗', body: 'Enjoy a nutritious lunch.', type: 'nutrition', time: '13:30', timestamp: today(13, 30)),
      AppNotification(id: 'routine_snack', title: 'Evening Snack 🍎', body: 'Grab a healthy snack.', type: 'nutrition', time: '17:00', timestamp: today(17, 0)),
      AppNotification(id: 'routine_dinner', title: 'Dinner 🍽️', body: 'Time for a light and healthy dinner.', type: 'nutrition', time: '20:00', timestamp: today(20, 0)),
      AppNotification(id: 'routine_sleep', title: 'Good Night 🌙', body: 'Rest well for a productive tomorrow.', type: 'greeting', time: '22:00', timestamp: today(22, 0)),
    ]);

    // 3. HYDRATION (Periodic)
    final hydrationTimes = [9, 11, 15, 17, 19];
    for (var h in hydrationTimes) {
      notifications.add(
        AppNotification(
          id: 'hyd_$h',
          title: 'Hydration Break 💧',
          body: 'Drink a glass of water to stay hydrated.',
          type: 'hydration',
          time: '${h.toString().padLeft(2, '0')}:00',
          timestamp: today(h, 0),
        ),
      );
    }

    // Schedule them
    for (final n in notifications) {
      await scheduleDailyNotification(
        id: n.id.hashCode,
        title: n.title,
        body: n.body,
        hour: n.timestamp.hour,
        minute: n.timestamp.minute,
        type: n.type,
      );
    }

    return notifications;
  }

  // ───────────────────── CUSTOM REMINDER ─────────────────────
  Future<void> scheduleCustomReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String type = 'custom',
  }) async {
    if (!_isInitialized) await init();

    final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Convert DateTime to TZDateTime
    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'fitness_custom_reminders_channel',
      'User Custom Reminders',
      channelDescription: 'Reminders set by the user',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    _addToHistory(
      AppNotification(
        id: id.toString(),
        title: title,
        body: body,
        time: DateFormat('hh:mm a').format(scheduledTime),
        type: type,
        timestamp: scheduledTime,
      ),
    );
  }

  // ───────────────────── SCHEDULE ─────────────────────
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String type = 'daily',
  }) async {
    if (!_isInitialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'fitness_daily_channel',
      'Daily Reminders',
      channelDescription: 'Daily fitness reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    _addToHistory(
      AppNotification(
        id: id.toString(),
        title: title,
        body: body,
        time:
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        type: type,
        timestamp: DateTime.now(),
      ),
    );
  }

  // ───────────────────── HISTORY ─────────────────────
  void _addToHistory(AppNotification notif) {
    _notificationHistory.insert(0, notif);
    if (_notificationHistory.length > 50) {
      _notificationHistory.removeLast();
    }
    _saveNotificationHistory();
  }

  Future<void> _loadNotificationHistory() async {
    try {
      final jsonStr = _prefs?.getString('notification_history');
      if (jsonStr == null) return;

      final List decoded = jsonDecode(jsonStr);
      _notificationHistory
        ..clear()
        ..addAll(decoded.map(
            (e) => AppNotification.fromMap(e as Map<String, dynamic>))); // ✅ FIXED
    } catch (e) {
      debugPrint('Load history error: $e');
    }
  }

  Future<void> _saveNotificationHistory() async {
    try {
      final jsonStr =
          jsonEncode(_notificationHistory.map((e) => e.toMap()).toList());
      await _prefs?.setString('notification_history', jsonStr);
    } catch (e) {
      debugPrint('Save history error: $e');
    }
  }

  List<AppNotification> getNotificationHistory() =>
      List.unmodifiable(_notificationHistory);

  // ───────────────────── EXTRA METHODS (USED BY UI) ─────────────────────
  Future<void> setupFitnessReminders() async {
    if (!_isInitialized) await init();
  }

  Future<void> clearAllScheduledNotifications() async {
    await _notificationsPlugin.cancelAll();
    _notificationHistory.clear();
    await _saveNotificationHistory();
  }

  // ───────────────────── HYDRATION SPECIFIC ─────────────────────
  Future<void> scheduleHourlyHydrationNotifications({
    int startHour = 7,  // 7 AM
    int endHour = 22,   // 10 PM
  }) async {
    if (!_isInitialized) await init();

    // First cancel existing to avoid duplicates
    await cancelHydrationNotifications();

    final now = DateTime.now();
    int idCounter = 1000; // Base ID for hydration

    for (int hour = startHour; hour <= endHour; hour++) {
      // Schedule for today
      // If hour already passed today, scheduled time logic in zonedSchedule will handle it (or we can add 1 day)
      // Actually `scheduleDailyNotification` handles the "if passed add 1 day" logic.
      
      await scheduleDailyNotification(
        id: idCounter + hour,
        title: 'Hydration Time 💧',
        body: 'Time for a glass of water! Stay hydrated.',
        hour: hour,
        minute: 0,
        type: 'hydration_reminder',
      );
    }
  }

  Future<void> cancelHydrationNotifications() async {
    // Cancel IDs from 1000 to 1024 (covering 24 hours)
    for (int i = 0; i <= 24; i++) {
      await _notificationsPlugin.cancel(1000 + i);
    }
  }

  Future<void> deleteNotification(String id) async {
    final int? numericId = int.tryParse(id);
    if (numericId != null) {
      await _notificationsPlugin.cancel(numericId);
    }
    _notificationHistory.removeWhere((n) => n.id == id);
    await _saveNotificationHistory();
  }

  // ───────────────────── CALLBACKS ─────────────────────
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(
      NotificationResponse response) {
    debugPrint('Background notification: ${response.payload}');
  }
}
