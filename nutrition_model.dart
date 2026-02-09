import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionModel {
  String? id;
  String name;
  String category;
  double calories;
  double protein;
  double carbs;
  double fat;
  double fiber;
  DateTime timestamp;
  String? imageUrl;

  NutritionModel({
    this.id,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.timestamp,
    this.imageUrl,
  });

  factory NutritionModel.fromMap(Map<String, dynamic> data, String id) {
    return NutritionModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Other',
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (data['fiber'] as num?)?.toDouble() ?? 0.0,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      // Save Firestore Timestamp so fromMap can convert it back safely
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      // removed automatic createdAt to avoid extra serverTimestamp field
    };
  }

  double get totalCalories => calories;

  Map<String, double> get macronutrientPercentages {
    final total = protein + carbs + fat;
    if (total == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};
    return {
      'protein': (protein / total) * 100,
      'carbs': (carbs / total) * 100,
      'fat': (fat / total) * 100,
    };
  }

  int get nutritionScore {
    double score = 0;
    score += (protein / 30).clamp(0, 1) * 40;
    score += (fiber / 10).clamp(0, 1) * 20;

    final p = macronutrientPercentages;
    if (p['protein']! >= 15 &&
        p['protein']! <= 35 &&
        p['carbs']! >= 40 &&
        p['carbs']! <= 60 &&
        p['fat']! >= 15 &&
        p['fat']! <= 30) {
      score += 40;
    } else {
      score += 20;
    }

    return score.clamp(0, 100).toInt();
  }

  NutritionModel copyWith({
    String? id,
    String? name,
    String? category,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    DateTime? timestamp,
    String? imageUrl,
  }) {
    return NutritionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'NutritionModel(id: $id, name: $name, category: $category, calories: $calories, protein: $protein, carbs: $carbs, fat: $fat, fiber: $fiber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutritionModel &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.calories == calories &&
        other.protein == protein &&
        other.carbs == carbs &&
        other.fat == fat &&
        other.fiber == fiber;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        category.hashCode ^
        calories.hashCode ^
        protein.hashCode ^
        carbs.hashCode ^
        fat.hashCode ^
        fiber.hashCode;
  }
}