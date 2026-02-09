
enum ExerciseType { strength, cardio, yoga, flexibility, hiit }
enum DifficultyLevel { beginner, intermediate, advanced }

class Exercise {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final ExerciseType type;
  final DifficultyLevel difficulty;
  final List<String> targetMuscleGroups;
  final List<String> equipmentNeeded;
  final int durationSeconds; // Default duration for time-based or estimated for reps
  final double caloriesPerMinute;
  final List<String> steps;
  final List<String> safetyTips;
  final List<String> stepImages;
  final bool isCustom; // If created by user (future proofing)

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.difficulty,
    required this.targetMuscleGroups,
    required this.equipmentNeeded,
    this.durationSeconds = 60,
    required this.caloriesPerMinute,
    required this.steps,
    required this.safetyTips,
    this.stepImages = const [],
    this.isCustom = false,
  });

  // Factory for Firestore
  factory Exercise.fromMap(Map<String, dynamic> data, String id) {
    return Exercise(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      type: ExerciseType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'strength'),
        orElse: () => ExerciseType.strength,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (data['difficulty'] ?? 'beginner'),
        orElse: () => DifficultyLevel.beginner,
      ),
      targetMuscleGroups: List<String>.from(data['targetMuscleGroups'] ?? []),
      equipmentNeeded: List<String>.from(data['equipmentNeeded'] ?? []),
      durationSeconds: data['durationSeconds'] ?? 60,
      caloriesPerMinute: (data['caloriesPerMinute'] ?? 5.0).toDouble(),
      steps: List<String>.from(data['steps'] ?? []),
      safetyTips: List<String>.from(data['safetyTips'] ?? []),
      stepImages: List<String>.from(data['stepImages'] ?? []),
      isCustom: data['isCustom'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'targetMuscleGroups': targetMuscleGroups,
      'equipmentNeeded': equipmentNeeded,
      'durationSeconds': durationSeconds,
      'caloriesPerMinute': caloriesPerMinute,
      'steps': steps,
      'safetyTips': safetyTips,
      'stepImages': stepImages,
      'isCustom': isCustom,
    };
  }

  // To JSON method for SharedPreferences/Local Storage
  Map<String, dynamic> toJson() => toMap();

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise.fromMap(json, json['id'] ?? 'unknown');
}
