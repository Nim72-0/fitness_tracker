// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notificationHistory = [];
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.init();
      _notificationsEnabled = await _notificationService.areNotificationsEnabled();
      _notificationHistory = _notificationService.getNotificationHistory();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setupFitnessReminders() async {
    try {
      await _notificationService.setupFitnessReminders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fitness reminders scheduled!',
            style: AppText.body.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
      _notificationHistory = _notificationService.getNotificationHistory();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error scheduling reminders: $e',
            style: AppText.body.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await _notificationService.clearAllScheduledNotifications();
      _notificationHistory = [];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All notifications cleared!',
            style: AppText.body.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error clearing notifications: $e',
            style: AppText.body.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showNotification(
      'Test Notification',
      'This is a test notification from your fitness app!',
      storeInHistory: true,
    );
    _notificationHistory = _notificationService.getNotificationHistory();
    setState(() {});
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _notificationService.deleteNotification(id);
      _notificationHistory = _notificationService.getNotificationHistory();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showAddReminderDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(const Duration(minutes: 5));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStfState) => AlertDialog(
          title: Text(
            'Add Custom Reminder',
            style: AppText.title.copyWith(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Drink Water',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    hintText: 'e.g. Time for your next glass!',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: Text(
                    'Time: ${DateFormat('hh:mm a').format(selectedDateTime)}',
                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                  ),
                  trailing: Icon(Icons.access_time, color: AppColors.primary),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (time != null) {
                      setStfState(() {
                        final now = DateTime.now();
                        selectedDateTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          time.hour,
                          time.minute,
                        );
                        if (selectedDateTime.isBefore(now)) {
                          selectedDateTime = selectedDateTime.add(const Duration(days: 1));
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppText.button.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  _notificationService.scheduleCustomReminder(
                    title: titleController.text,
                    body: bodyController.text,
                    scheduledTime: selectedDateTime,
                  );
                  Navigator.pop(context);
                  _initializeNotifications();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'Schedule',
                style: AppText.button.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'hydration':
        return Icons.water_drop;
      case 'workout':
        return Icons.fitness_center;
      case 'summary':
        return Icons.assessment;
      case 'instant':
        return Icons.notifications;
      case 'scheduled':
        return Icons.schedule;
      case 'prayer':
        return Icons.mosque;
      case 'custom':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'hydration':
        return AppColors.hydrationColor;
      case 'workout':
        return AppColors.workout;
      case 'summary':
        return AppColors.info;
      case 'scheduled':
        return AppColors.primary;
      case 'prayer':
        return AppColors.prayer;
      case 'custom':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: AppText.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _notificationHistory.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _notificationsEnabled
                        ? AppColors.hydrationColorLight
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(
                      color: _notificationsEnabled
                          ? AppColors.hydrationColor.withOpacity(0.2)
                          : AppColors.error.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: _notificationsEnabled
                            ? AppColors.hydrationColor
                            : AppColors.error,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _notificationsEnabled
                                  ? 'Notifications Enabled'
                                  : 'Notifications Disabled',
                              style: AppText.titleMedium.copyWith(
                                color: _notificationsEnabled
                                    ? AppColors.hydrationColor
                                    : AppColors.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _notificationsEnabled
                                  ? 'You\'ll receive fitness reminders'
                                  : 'Enable notifications for reminders',
                              style: AppText.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showAddReminderDialog,
                          icon: Icon(Icons.add_alarm, size: 20, color: AppColors.white),
                          label: Text(
                            'Add Reminder',
                            style: AppText.button,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _setupFitnessReminders,
                          icon: Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
                          label: Text(
                            'Auto Setup',
                            style: AppText.button.copyWith(color: AppColors.primary),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              side: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Notification History',
                        style: AppText.headlineSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          '${_notificationHistory.length}',
                          style: AppText.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _notificationHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications yet',
                                style: AppText.titleMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Notifications will appear here',
                                style: AppText.body.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            _notificationHistory = _notificationService.getNotificationHistory();
                            setState(() {});
                          },
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notificationHistory.length,
                            itemBuilder: (context, index) {
                              final notif = _notificationHistory[index];
                              final type = notif.type;
                              final timestamp = notif.timestamp;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBg,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  boxShadow: AppTheme.cardShadow,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _getNotificationColor(type).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: Icon(
                                      _getNotificationIcon(type),
                                      color: _getNotificationColor(type),
                                      size: 24,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: AppText.titleMedium.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close, size: 18),
                                        onPressed: () => _deleteNotification(notif.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.body,
                                        style: AppText.body.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('hh:mm a').format(timestamp),
                                            style: AppText.caption.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (type != 'instant')
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getNotificationColor(type).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(AppRadius.md),
                                                border: Border.all(
                                                  color: _getNotificationColor(type).withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                type.toUpperCase(),
                                                style: AppText.labelSmall.copyWith(
                                                  color: _getNotificationColor(type),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}