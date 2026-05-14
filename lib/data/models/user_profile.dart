import 'package:flutter/material.dart';

enum Somatotype { ectomorph, mesomorph, endomorph }

enum FitnessGoal { bulking, cutting, maintenance, strength, endurance }

enum FitnessLevel { beginner, intermediate, advanced }

enum AvailableEquipment { gym, home, bodyweightOnly }

class UserProfile {
  final String id;
  final String name;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final Somatotype? somatotype;
  final FitnessGoal goal;
  final FitnessLevel level;
  final AvailableEquipment equipment;
  final int workoutsPerWeek;
  final bool useMetric;
  final Measurements? measurements;

  const UserProfile({
    required this.id,
    required this.name,
    this.age,
    this.weightKg,
    this.heightCm,
    this.somatotype,
    required this.goal,
    required this.level,
    required this.equipment,
    this.workoutsPerWeek = 4,
    this.useMetric = true,
    this.measurements,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'somatotype': somatotype?.index,
    'goal': goal.index,
    'level': level.index,
    'equipment': equipment.index,
    'workoutsPerWeek': workoutsPerWeek,
    'useMetric': useMetric,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    age: json['age'] as int?,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    somatotype: json['somatotype'] != null
        ? Somatotype.values[json['somatotype'] as int]
        : null,
    goal: FitnessGoal.values[json['goal'] as int],
    level: FitnessLevel.values[json['level'] as int],
    equipment: AvailableEquipment.values[json['equipment'] as int],
    workoutsPerWeek: json['workoutsPerWeek'] as int? ?? 4,
    useMetric: json['useMetric'] as bool? ?? true,
  );

  double? get bmi {
    if (weightKg == null || heightCm == null) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  UserProfile copyWith({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    Somatotype? somatotype,
    FitnessGoal? goal,
    FitnessLevel? level,
    AvailableEquipment? equipment,
    int? workoutsPerWeek,
    Measurements? measurements,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        age: age ?? this.age,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        somatotype: somatotype ?? this.somatotype,
        goal: goal ?? this.goal,
        level: level ?? this.level,
        equipment: equipment ?? this.equipment,
        workoutsPerWeek: workoutsPerWeek ?? this.workoutsPerWeek,
        useMetric: useMetric,
        measurements: measurements ?? this.measurements,
      );
}

class Measurements {
  final double? chest;
  final double? waist;
  final double? hips;
  final double? bicepLeft;
  final double? bicepRight;
  final double? thighLeft;
  final double? thighRight;
  final double? calves;
  final DateTime recordedAt;

  const Measurements({
    this.chest,
    this.waist,
    this.hips,
    this.bicepLeft,
    this.bicepRight,
    this.thighLeft,
    this.thighRight,
    this.calves,
    required this.recordedAt,
  });
}

extension SomatotypeExt on Somatotype {
  String get label {
    switch (this) {
      case Somatotype.ectomorph: return 'Ectomorphe';
      case Somatotype.mesomorph: return 'Mésomorphe';
      case Somatotype.endomorph: return 'Endomorphe';
    }
  }

  String get description {
    switch (this) {
      case Somatotype.ectomorph:
        return 'Métabolisme rapide, difficulté à prendre du volume. Programme axé sur la prise de masse avec peu de cardio.';
      case Somatotype.mesomorph:
        return 'Morphologie athlétique naturelle. Programme équilibré masse/sèche avec progression rapide.';
      case Somatotype.endomorph:
        return 'Tendance à stocker les graisses. Programme combinant musculation et cardio pour la composition corporelle.';
    }
  }
}

extension FitnessGoalExt on FitnessGoal {
  String get label {
    switch (this) {
      case FitnessGoal.bulking: return 'Prise de masse';
      case FitnessGoal.cutting: return 'Sèche';
      case FitnessGoal.maintenance: return 'Maintien';
      case FitnessGoal.strength: return 'Force';
      case FitnessGoal.endurance: return 'Endurance';
    }
  }
}

extension FitnessLevelExt on FitnessLevel {
  String get label {
    switch (this) {
      case FitnessLevel.beginner: return 'Débutant';
      case FitnessLevel.intermediate: return 'Intermédiaire';
      case FitnessLevel.advanced: return 'Avancé';
    }
  }

  Color get color {
    switch (this) {
      case FitnessLevel.beginner: return const Color(0xFF4ADE80);
      case FitnessLevel.intermediate: return const Color(0xFFFBBF24);
      case FitnessLevel.advanced: return const Color(0xFFFF5757);
    }
  }
}
