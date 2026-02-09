import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../providers/hydration_provider.dart';
import '../utils/theme.dart';
import '../models/hydration_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  late HydrationProvider _provider;
  String? _uid;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // UI default glass options
  final List<Map<String, dynamic>> _glassSizes = [
    {'name': 'Small Glass', 'amount': 200, 'icon': Icons.water_drop, 'color': Colors.blueAccent},
    {'name': 'Regular Glass', 'amount': 300, 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Large Glass', 'amount': 500, 'icon': Icons.water_drop, 'color': Colors.lightBlue},
    {'name': 'Bottle', 'amount': 1000, 'icon': Icons.local_drink, 'color': Colors.blueGrey},
  ];

  // Wake-up time (will be loaded from prefs or profile)
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 0);

  // Reusable controller for set-goal dialog (so we can dispose it)
  final TextEditingController _goalController = TextEditingController();

  // Preferred glass size (ml) loaded from provider/profile/prefs
  int _preferredGlassSize = 250;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initProvider());
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showGoalAchievedNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'hydration_goal_channel',
      'Hydration Goal Notifications',
      channelDescription: 'Notifications for when you reach your hydration goal',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'Congratulations!', 'You reached your hydration goal for today!', platformChannelSpecifics);
  }

  bool _isRemindersEnabled = false;

  Future<void> _initProvider() async {
    _provider = Provider.of<HydrationProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    _uid = authService.user?.uid;

    if (_uid != null) {
      debugPrint('HydrationScreen: Setting User ID $_uid');
      try {
        await _provider.setUserId(_uid!);
      } catch (e) {
        debugPrint('HydrationScreen: Failed to set UID on provider: $e');
      }
    } else {
      debugPrint('HydrationScreen: User ID is null. Cannot initialize hydration properly.');
    }

    // Load Reminder State
    _isRemindersEnabled = await _provider.areRemindersEnabled();

    // Load provider data if method exists
    try {
      final res = (_provider as dynamic).loadHydrationData();
      if (res is Future) await res;
    } catch (_) {}

    _loadLocalPreferences();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // preferred glass size: provider -> prefs -> default
      try {
        final dynamic pgs = (_provider as dynamic).preferredGlassSize;
        if (pgs is int && pgs > 0) {
          _preferredGlassSize = pgs;
        } else {
          _preferredGlassSize = prefs.getInt('preferred_glass_size') ?? _preferredGlassSize;
        }
      } catch (_) {
        _preferredGlassSize = prefs.getInt('preferred_glass_size') ?? _preferredGlassSize;
      }

      // wake up time: provider.user?.wakeUpTime (ISO) -> prefs -> default (7:00)
      DateTime? wakeFromProfile;
      try {
        final dynamic user = (_provider as dynamic).user;
        if (user != null) {
          final dyn = (user as dynamic);
          if (dyn.wakeUpTime is String) {
            wakeFromProfile = DateTime.tryParse(dyn.wakeUpTime as String);
          } else if (dyn.wakeUpTime is DateTime) {
            wakeFromProfile = dyn.wakeUpTime as DateTime;
          }
        }
      } catch (_) {}

      if (wakeFromProfile != null) {
        _wakeUpTime = TimeOfDay(hour: wakeFromProfile.hour, minute: wakeFromProfile.minute);
      } else {
        // fallback to prefs
        final wakeStr = prefs.getString('wake_up_time');
        if (wakeStr != null) {
          final parsed = DateTime.tryParse(wakeStr);
          if (parsed != null) {
            _wakeUpTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
          }
        }
      }
    } catch (e) {
      debugPrint('HydrationScreen: Prefs load error: $e');
    }
  }

  Future<void> _toggleReminders(bool value) async {
    setState(() => _isRemindersEnabled = value);
    if (value) {
      await _provider.enableHourlyReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hourly hydration reminders enabled ⏰'),
            backgroundColor: AppColors.success, // ✅ Fixed
          ),
        );
      }
    } else {
      await _provider.disableHourlyReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reminders disabled'),
            backgroundColor: AppColors.textMuted, // ✅ Fixed
          ),
        );
      }
    }
  }

  // ── Water goal calculation based on fitness goal & weight ────────────────
  int _calculateWaterGoal(String fitnessGoal, double weightKg) {
    final Map<String, double> multipliers = {
      'weight_loss': 35.0,
      'muscle_gain': 40.0,
      'weight_gain': 35.0,
      'maintenance': 30.0,
    };
    final double multiplier = multipliers[fitnessGoal] ?? 30.0;
    return (weightKg * multiplier).round();
  }

  // ── Hydration schedule: uses preferred glass size (dynamic) ──────────────
  List<Map<String, dynamic>> _getHydrationSchedule(
      HydrationModel hydration, HydrationProvider provider, int glassSize) {
    final String fitnessGoal =
        (provider.user != null ? (provider.user!.goal ?? '') : '').toLowerCase() ??
            (provider.fitnessGoal ?? 'maintenance');
    final double weight = provider.user?.weight ?? provider.userWeight ?? 60.0;
    final int totalMl = hydration.dailyGoal.toInt() > 0
        ? hydration.dailyGoal.toInt()
        : _calculateWaterGoal(fitnessGoal, weight);

    final int usingGlassSize = glassSize > 0 ? glassSize : 250;
    final int totalGlasses = (totalMl / usingGlassSize).ceil().clamp(1, 100);

    final List<Map<String, dynamic>> schedule = [];

    // Distribute glasses across waking hours (simple +1 hour increments)
    for (int i = 0; i < totalGlasses; i++) {
      final now = DateTime.now();
      final DateTime base =
          DateTime(now.year, now.month, now.day, _wakeUpTime.hour, _wakeUpTime.minute);
      final DateTime time = base.add(Duration(hours: i + 1));

      String message = 'Stay hydrated for better health! 💧';
      switch (fitnessGoal) {
        case 'weight_loss':
          message = i == 0
              ? 'Drink on empty stomach for metabolism boost 🔥'
              : 'Stay hydrated to reduce appetite';
          break;
        case 'muscle_gain':
          message = (i == 2) ? 'Post-workout hydration is crucial 💪' : 'Keep muscles hydrated for growth';
          break;
        case 'weight_gain':
          message = 'Fuel your gains with consistent hydration';
          break;
        default:
          message = 'Stay hydrated throughout the day';
      }

      schedule.add({
        'time': time,
        'amount': usingGlassSize,
        'message': message,
        'icon': i < totalGlasses ~/ 2 ? '🌞' : '🌙',
      });
    }

    return schedule;
  }

  // Helper to call provider methods defensively and normalize boolean response
  Future<bool> _callProviderBool(dynamic maybeFuture) async {
    try {
      if (maybeFuture is Future<bool>) return await maybeFuture;
      if (maybeFuture is Future) {
        await maybeFuture;
        return true;
      }
      if (maybeFuture is bool) return maybeFuture;
      return true;
    } catch (e) {
      debugPrint('Provider call failed: $e');
      return false;
    }
  }

  Future<void> _addWater(int amount, [String? glassName]) async {
    final provider = Provider.of<HydrationProvider>(context, listen: false);
    bool success = false;
    try {
      final dyn = provider as dynamic;
      if (dyn.addWater != null) {
        success = await _callProviderBool(dyn.addWater(amount.toDouble(), glassName: glassName));
      } else if (dyn.recordWater != null) {
        success = await _callProviderBool(dyn.recordWater(amount.toDouble(), glassName: glassName));
      } else {
        success = false;
      }
    } catch (e) {
      debugPrint('Error calling provider.addWater: $e');
      success = false;
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $amount ml 💦'),
          backgroundColor: AppColors.success, // ✅ Fixed
        ),
      );
      final prov = Provider.of<HydrationProvider>(context, listen: false);
      final hydration = prov.hydration;
      final achieved = (prov as dynamic).isGoalAchieved ?? hydration.isGoalAchieved ?? false;
      if (achieved) {
        _showGoalDialog();
        _showGoalAchievedNotification();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add water 😕'),
          backgroundColor: AppColors.error, // ✅ Fixed
        ),
      );
    }
  }

  Future<void> _setGoal(double newGoal) async {
    final provider = Provider.of<HydrationProvider>(context, listen: false);
    bool success = false;
    try {
      final dyn = provider as dynamic;
      if (dyn.updateGoal != null) {
        success = await _callProviderBool(dyn.updateGoal(newGoal.toInt()));
      } else if (dyn.updateWaterGoal != null) {
        success = await _callProviderBool(dyn.updateWaterGoal(newGoal.toInt()));
      } else {
        success = false;
      }
    } catch (e) {
      debugPrint('Error calling provider update goal: $e');
      success = false;
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal updated to ${newGoal.toInt()} ml 🎯'),
          backgroundColor: AppColors.progressStart, // ✅ Fixed (now exists in AppColors)
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update goal'),
          backgroundColor: AppColors.error, // ✅ Fixed
        ),
      );
    }
  }

  void _showGoalDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: const Text('You crushed your hydration goal today! Keep it up! 💧'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<double?> _showSetGoalDialog(double currentGoal) async {
    _goalController.text = currentGoal.toInt().toString();
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Goal (ml)'),
        content: TextField(
          controller: _goalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter water goal in ml'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(_goalController.text);
              if (val != null && val > 0) Navigator.pop(context, val);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HydrationProvider>(context);
    final hydration = provider.hydration;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Determine preferred glass size (provider -> prefs -> UI default)
    int glassSize = _preferredGlassSize;
    try {
      final dyn = provider as dynamic;
      if (dyn.preferredGlassSize != null && dyn.preferredGlassSize is int && dyn.preferredGlassSize > 0) {
        glassSize = dyn.preferredGlassSize as int;
      }
    } catch (_) {}

    final schedule = _getHydrationSchedule(hydration, provider, glassSize);

    return Scaffold(
      backgroundColor: AppColors.screenBg, // ✅ Fixed
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Text(
              'Hydration Tracker',
              style: AppText.titleMedium.copyWith(color: AppColors.textPrimary), // ✅ Fixed
            ),
            backgroundColor: AppColors.surface, // ✅ Fixed
            foregroundColor: AppColors.textPrimary, // ✅ Fixed
            elevation: 0,
            pinned: true,
            actions: [
              Switch(
                value: _isRemindersEnabled,
                onChanged: _toggleReminders,
                activeColor: AppColors.hydrationColor, // ✅ Fixed
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Current Goal & Progress
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface, // ✅ Fixed
                    borderRadius: BorderRadius.circular(AppRadius.lg), // ✅ Fixed
                    border: Border.all(color: AppColors.borderGrey), // ✅ Fixed
                    boxShadow: AppShadows.card, // ✅ Fixed
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${hydration.waterIntake.toInt()} / ${hydration.dailyGoal.toInt()} ml',
                        style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary), // ✅ Fixed
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hydration.remainingWater > 0 
                            ? '${hydration.remainingWater.toInt()} ml left to reach your goal'
                            : 'Goal Achieved! You\'re doing great!',
                        style: AppText.body.copyWith(color: AppColors.textSecondary), // ✅ Fixed
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Stack(
                        children: [
                          Container(
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.progressBg, // ✅ Fixed
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: hydration.progressPercentage.clamp(0.0, 1.0),
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.hydrationColor, const Color(0xFF60A5FA)], // ✅ Fixed
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.hydrationColor.withOpacity(0.3), // ✅ Fixed
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${(hydration.progressPercentage * 100).toInt()}%',
                                  style: AppText.titleMedium.copyWith( // ✅ Fixed
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Quick Add Glasses
                Text(
                  'Quick Add',
                  style: AppText.title.copyWith(color: AppColors.textPrimary), // ✅ Fixed
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: _glassSizes.map((glass) {
                    final int amt = glass['amount'] as int;
                    final Color color = glass['color'] as Color;
                    return InkWell(
                      onTap: () => _addWater(amt, glass['name'] as String),
                      borderRadius: BorderRadius.circular(AppRadius.lg), // ✅ Fixed
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg), // ✅ Fixed
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(glass['icon'] as IconData, color: color, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${glass['amount']} ml',
                                    style: AppText.bodyLarge.copyWith( // ✅ Fixed
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    glass['name'] as String,
                                    style: AppText.bodySmall.copyWith(color: color.withOpacity(0.8)), // ✅ Fixed
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Personalized Hydration Schedule
                Text(
                  'Hydration Schedule',
                  style: AppText.title.copyWith(color: AppColors.textPrimary), // ✅ Fixed
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: schedule.length,
                  itemBuilder: (context, index) {
                    final item = schedule[index];
                    final time = item['time'] as DateTime;
                    final timeStr = DateFormat('hh:mm a').format(time);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface, // ✅ Fixed
                        borderRadius: BorderRadius.circular(AppRadius.lg), // ✅ Fixed
                        border: Border.all(color: AppColors.borderGrey), // ✅ Fixed
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.hydrationColorLight, // ✅ Fixed
                              shape: BoxShape.circle,
                            ),
                            child: Text(item['icon'] as String, style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeStr,
                                  style: AppText.bodyLarge.copyWith( // ✅ Fixed
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  item['message'] as String,
                                  style: AppText.bodySmall.copyWith(color: AppColors.textSecondary), // ✅ Fixed
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${item['amount']} ml',
                            style: AppText.body.copyWith( // ✅ Fixed
                              color: AppColors.hydrationColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Set Goal Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface, // ✅ Fixed
                      foregroundColor: AppColors.primary, // ✅ Fixed
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.primary), // ✅ Fixed
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg), // ✅ Fixed
                      ),
                    ),
                    onPressed: () async {
                      final newGoal = await _showSetGoalDialog(hydration.dailyGoal);
                      if (newGoal != null) _setGoal(newGoal);
                    },
                    child: Text(
                      'Adjust Daily Goal',
                      style: AppText.button.copyWith(color: AppColors.primary), // ✅ Fixed
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}