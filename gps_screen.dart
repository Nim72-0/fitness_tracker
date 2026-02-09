import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/gps_provider.dart';
import '../utils/theme.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  final MapController mapController = MapController();
  final LatLng fallback = const LatLng(24.8607, 67.0011);
  String? uid;
  String selectedGoal = 'weight_loss';

  @override
  void initState() {
    super.initState();
    uid = context.read<AuthService>().currentUser?.uid;
  }

  void _centerMap(LatLng pos) {
    mapController.move(pos, 16);
  }

  List<Map<String, dynamic>> _getWorkoutRoutes(String goal) {
    switch (goal) {
      case 'weight_loss':
        return [
          {'name': 'Cardio Route', 'distance': 5.0, 'type': 'running', 'icon': Icons.directions_run},
          {'name': 'HIIT Park Circuit', 'distance': 3.0, 'type': 'interval', 'icon': Icons.timer},
          {'name': 'Hill Running Path', 'distance': 4.0, 'type': 'running', 'icon': Icons.landscape},
        ];
      case 'muscle_gain':
        return [
          {'name': 'Outdoor Gym Circuit', 'distance': 2.0, 'type': 'strength', 'icon': Icons.fitness_center},
          {'name': 'Stair Climbing Route', 'distance': 1.5, 'type': 'strength', 'icon': Icons.stairs},
          {'name': 'Park Bench Workout', 'distance': 1.0, 'type': 'bodyweight', 'icon': Icons.chair_alt},
        ];
      case 'weight_gain':
        return [
          {'name': 'Short Sprints', 'distance': 1.5, 'type': 'power', 'icon': Icons.flash_on},
          {'name': 'Walking Lunges', 'distance': 1.0, 'type': 'strength', 'icon': Icons.directions_walk},
        ];
      case 'maintenance':
        return [
          {'name': 'Brisk Walk Loop', 'distance': 4.0, 'type': 'walking', 'icon': Icons.directions_walk},
          {'name': 'Mixed Cardio Trail', 'distance': 6.0, 'type': 'cardio', 'icon': Icons.directions_bike},
        ];
      default:
        return [];
    }
  }

  Map<String, dynamic> _trackOutdoorWorkout({
    required String goal,
    required double distanceKm,
    required Duration time,
    required double calories,
  }) {
    final paceMinPerKm = distanceKm > 0 ? time.inMinutes / distanceKm : 0.0;
    final paceStr = distanceKm > 0
        ? '${paceMinPerKm.floor()}:${((paceMinPerKm - paceMinPerKm.floor()) * 60).round().toString().padLeft(2, '0')} min/km'
        : '--:-- min/km';

    Map<String, dynamic> analysis = {
      'distanceKm': distanceKm.toStringAsFixed(2),
      'time': '${time.inMinutes} min ${time.inSeconds % 60} sec',
      'calories': calories.round(),
      'pace': paceStr,
      'feedback': '',
    };

    switch (goal) {
      case 'weight_loss':
        analysis['feedback'] = calories > 300
            ? 'Great fat-burning session! 🔥 Keep it up!'
            : 'Increase intensity or duration for better results 💪';
        break;
      case 'muscle_gain':
        analysis['feedback'] = distanceKm < 3
            ? 'Good active recovery. Add strength next time!'
            : 'Solid endurance work — perfect for muscle support!';
        break;
      case 'weight_gain':
        analysis['feedback'] = distanceKm < 2
            ? 'Perfect! Short & intense to preserve calories for growth.'
            : 'Careful! Too much cardio handles burn precious calories.';
        break;
      case 'maintenance':
        analysis['feedback'] = 'Balanced session — right on track!';
        break;
      default:
        analysis['feedback'] = 'Great workout!';
    }

    return analysis;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GPSProvider>(
      builder: (context, gps, _) {
        final km = gps.totalDistance / 1000;
        final analysis = _trackOutdoorWorkout(
          goal: selectedGoal,
          distanceKm: km,
          time: gps.duration,
          calories: gps.caloriesBurned,
        );

        final initialPos = gps.points.isNotEmpty
            ? gps.points.last.toLatLng()
            : fallback;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppTheme.appBarBackground,
            elevation: 0,
            title: Text(
              'GPS Tracker',
              style: AppText.headlineMedium.copyWith(color: AppColors.textPrimary),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: DropdownButton<String>(
                    value: selectedGoal,
                    dropdownColor: AppColors.surface,
                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(
                        value: 'weight_loss', 
                        child: Text('Weight Loss', style: TextStyle(fontWeight: FontWeight.w600))
                      ),
                      DropdownMenuItem(
                        value: 'muscle_gain', 
                        child: Text('Muscle Gain', style: TextStyle(fontWeight: FontWeight.w600))
                      ),
                      DropdownMenuItem(
                        value: 'weight_gain', 
                        child: Text('Weight Gain', style: TextStyle(fontWeight: FontWeight.w600))
                      ),
                      DropdownMenuItem(
                        value: 'maintenance', 
                        child: Text('Maintenance', style: TextStyle(fontWeight: FontWeight.w600))
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedGoal = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: initialPos,
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.fitness_tracker_app',
                        ),
                        
                        if (gps.points.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: gps.latLngPoints,
                                strokeWidth: 5,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),

                        MarkerLayer(
                          markers: [
                             if (gps.points.isNotEmpty)
                               Marker(
                                 point: gps.points.first.toLatLng(),
                                 width: 40,
                                 height: 40,
                                 child: const Icon(Icons.location_on, color: AppColors.success, size: 40),
                               ),
                             
                             if (gps.points.isNotEmpty)
                               Marker(
                                 point: gps.points.last.toLatLng(),
                                 width: 40,
                                 height: 40,
                                 child: const Icon(Icons.location_on, color: AppColors.error, size: 40),
                               ),

                             if (gps.points.isEmpty)
                               Marker(
                                 point: fallback,
                                 width: 40,
                                 height: 40,
                                 child: Icon(Icons.location_on, color: AppColors.textMuted, size: 40),
                               ),
                          ],
                        ),
                        
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              'OpenStreetMap contributors',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),

                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Goal: ${selectedGoal.replaceAll('_', ' ').toUpperCase()}',
                                style: AppText.titleMedium.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _infoColumn('Distance', '${km.toStringAsFixed(2)} km', Icons.map),
                                  _infoColumn('Time', '${gps.duration.inMinutes} min', Icons.timer),
                                  _infoColumn('Calories', '${gps.caloriesBurned.round()} kcal', Icons.local_fire_department),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.insights, color: AppColors.success, size: 20),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        analysis['feedback'],
                                        style: AppText.body.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: Icon(gps.isTracking ? Icons.stop : Icons.play_arrow),
                                      label: Text(
                                        gps.isTracking ? 'STOP GPS' : 'START GPS',
                                        style: AppText.button,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: gps.isTracking ? AppColors.error : AppTheme.primaryColor,
                                        foregroundColor: AppColors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (gps.isTracking) {
                                          gps.stopTracking();
                                        } else {
                                          await gps.startTracking();
                                          if (gps.points.isNotEmpty) {
                                             _centerMap(gps.points.last.toLatLng());
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  if (gps.points.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.save, color: AppColors.success),
                                        tooltip: 'Save Route',
                                        onPressed: () async {
                                          if (uid != null) {
                                            final success = await gps.saveRoute();
                                            if (success && context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Route saved successfully!',
                                                    style: AppText.body.copyWith(color: AppColors.white),
                                                  ),
                                                  backgroundColor: AppColors.success,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                                  ),
                                                ),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'User not logged in',
                                                  style: AppText.body.copyWith(color: AppColors.white),
                                                ),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppTheme.smallShadow,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.my_location, color: AppTheme.primaryColor),
                          onPressed: () {
                            if (gps.points.isNotEmpty) {
                              _centerMap(gps.points.last.toLatLng());
                            } else {
                              _centerMap(fallback);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surfaceVariant,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Routes for ${selectedGoal.replaceAll('_', ' ')}',
                      style: AppText.headlineSmall.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _getWorkoutRoutes(selectedGoal).length,
                        itemBuilder: (context, index) {
                          final route = _getWorkoutRoutes(selectedGoal)[index];
                          return Container(
                            margin: EdgeInsets.only(right: index == _getWorkoutRoutes(selectedGoal).length - 1 ? 0 : 12),
                            width: 180,
                            child: Card(
                              color: AppTheme.cardBg,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      route['icon'] as IconData, 
                                      size: 32, 
                                      color: AppTheme.primaryColor
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      route['name'] as String,
                                      textAlign: TextAlign.center,
                                      style: AppText.titleSmall.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${route['distance']} km • ${route['type']}',
                                      style: AppText.caption.copyWith(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(title, style: AppText.label.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value, 
          style: AppText.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary
          )
        ),
      ],
    );
  }
}