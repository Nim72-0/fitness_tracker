import '../models/exercise_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  final String id;
  final String name;
  final String category;
  final String goal;
  final String level; // 'beginner', 'intermediate', 'advanced'
  final String gender; // 'male', 'female', 'both'
  final int duration; // in minutes
  final int caloriesBurned;
  final List<Exercise> exercises;
  final List<String> instructions;
  final String imageUrl;
  final List<String> equipment;
  final DateTime createdAt;
  bool isFavorite;
  final String splitType;

  // Optional fields
  final String? description;
  final int? sets;
  final int? reps;
  final int? steps;

  Workout({
    required this.id,
    required this.name,
    required this.category,
    required this.goal,
    required this.level,
    required this.gender,
    required this.duration,
    required this.caloriesBurned,
    this.exercises = const [],
    this.instructions = const [],
    this.imageUrl = '',
    this.equipment = const [],
    required this.createdAt,
    this.isFavorite = false,
    this.splitType = 'Full Body',
    this.description,
    this.sets,
    this.reps,
    this.steps,
  });

  factory Workout.fromMap(Map<String, dynamic> map, {String? id}) {
    // Null safety + fallback values
    final safeMap = map;

    return Workout(
      id: id ?? safeMap['id']?.toString() ?? '',
      name: safeMap['name']?.toString() ?? safeMap['title']?.toString() ?? 'Unnamed Workout',
      category: safeMap['category']?.toString() ?? 'strength',
      goal: safeMap['goal']?.toString() ?? 'General Fitness',
      level: (safeMap['level']?.toString() ?? 'beginner').toLowerCase(),
      gender: safeMap['gender']?.toString() ?? 'both',
      duration: _safeParseInt(safeMap['duration'] ?? safeMap['minutes']),
      caloriesBurned: _safeParseInt(safeMap['caloriesBurned'] ?? safeMap['calories']),
      exercises: _parseExercises(safeMap['exercises']),
      instructions: _safeParseStringList(safeMap['instructions']),
      imageUrl: safeMap['imageUrl']?.toString() ?? '',
      equipment: _safeParseStringList(safeMap['equipment']),
      createdAt: _safeParseDateTime(safeMap['createdAt']),
      isFavorite: safeMap['isFavorite'] as bool? ?? false,
      splitType: safeMap['splitType']?.toString() ?? 'Full Body',
      description: safeMap['description']?.toString(),
      sets: _safeParseIntNullable(safeMap['sets']),
      reps: _safeParseIntNullable(safeMap['reps']),
      steps: _safeParseIntNullable(safeMap['steps']),
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json) => Workout.fromMap(json);

  factory Workout.empty({String id = ''}) {
    return Workout(
      id: id,
      name: 'No Workout',
      category: 'strength',
      goal: 'General',
      level: 'beginner',
      gender: 'both',
      duration: 0,
      caloriesBurned: 0,
      createdAt: DateTime.now(),
      isFavorite: false,
      splitType: 'Full Body',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'goal': goal,
      'level': level,
      'gender': gender,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'instructions': instructions,
      'imageUrl': imageUrl,
      'equipment': equipment,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFavorite': isFavorite,
      'splitType': splitType,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (description != null) map['description'] = description;
    if (sets != null) map['sets'] = sets;
    if (reps != null) map['reps'] = reps;
    if (steps != null) map['steps'] = steps;

    // Remove null values (optional - Firestore handles null well)
    map.removeWhere((key, value) => value == null);

    return map;
  }

  Map<String, dynamic> toJson() => toMap();

  Workout copyWith({
    String? id,
    String? name,
    String? category,
    String? goal,
    String? level,
    String? gender,
    int? duration,
    int? caloriesBurned,
    List<Exercise>? exercises,
    List<String>? instructions,
    String? imageUrl,
    List<String>? equipment,
    DateTime? createdAt,
    bool? isFavorite,
    String? splitType,
    String? description,
    int? sets,
    int? reps,
    int? steps,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      goal: goal ?? this.goal,
      level: level ?? this.level,
      gender: gender ?? this.gender,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      exercises: exercises ?? this.exercises,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      equipment: equipment ?? this.equipment,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      splitType: splitType ?? this.splitType,
      description: description ?? this.description,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      steps: steps ?? this.steps,
    );
  }

  @override
  String toString() {
    return 'Workout(id: $id, name: $name, duration: $duration min, cal: $caloriesBurned)';
  }

  // ─── Helper Methods ────────────────────────────────────────────────────────

  static int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _safeParseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _safeParseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  static DateTime _safeParseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static List<Exercise> _parseExercises(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) {
        if (e is Map<String, dynamic>) {
          return Exercise.fromMap(e, e['id'] ?? '');
        }
        return null;
      }).whereType<Exercise>().toList();
    }
    return [];
  }
}

// ──────────────────────────────────────────────

class WorkoutSession {
  final String id;
  final String workoutId;
  final Workout workout;
  final DateTime completedAt;
  final int duration;
  final int caloriesBurned;

  WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.workout,
    required this.completedAt,
    required this.duration,
    required this.caloriesBurned,
  });

  factory WorkoutSession.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return WorkoutSession(
        id: '',
        workoutId: '',
        workout: Workout.empty(),
        completedAt: DateTime.now(),
        duration: 0,
        caloriesBurned: 0,
      );
    }

    final workoutData = map['workout'] as Map<String, dynamic>?;
    final workout = workoutData != null
        ? Workout.fromMap(workoutData)
        : Workout.empty(id: map['workoutId']?.toString() ?? '');

    return WorkoutSession(
      id: map['id']?.toString() ?? '',
      workoutId: map['workoutId']?.toString() ?? workout.id,
      workout: workout,
      completedAt: Workout._safeParseDateTime(map['completedAt']),
      duration: Workout._safeParseInt(map['duration']),
      caloriesBurned: Workout._safeParseInt(map['caloriesBurned']),
    );
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'workout': workout.toMap(),
      'completedAt': Timestamp.fromDate(completedAt),
      'duration': duration,
      'caloriesBurned': caloriesBurned,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  WorkoutSession copyWith({
    String? id,
    String? workoutId,
    Workout? workout,
    DateTime? completedAt,
    int? duration,
    int? caloriesBurned,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      workout: workout ?? this.workout,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }
}