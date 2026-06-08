import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class LogSet {
  final bool isBodyweight;
  final double? weight; // null si isBodyweight
  final int reps;

  const LogSet({required this.isBodyweight, this.weight, required this.reps});

  factory LogSet.fromJson(Map<String, dynamic> j) => LogSet(
        isBodyweight: j['bw'] == true,
        weight: j['w'] != null ? (j['w'] as num).toDouble() : null,
        reps: j['r'] as int,
      );

  Map<String, dynamic> toJson() => {'bw': isBodyweight, 'w': weight, 'r': reps};

  String get display => isBodyweight ? 'PDC × $reps' : '${weight?.toStringAsFixed(weight! % 1 == 0 ? 0 : 1)}kg × $reps';
  double get score => isBodyweight ? reps.toDouble() : (weight ?? 0) * reps;
}

class LogExercise {
  final String exerciseId;
  final List<LogSet> sets;
  final String? notes;

  const LogExercise({required this.exerciseId, required this.sets, this.notes});

  factory LogExercise.fromJson(Map<String, dynamic> j) => LogExercise(
        exerciseId: j['id'] as String,
        sets: (j['sets'] as List).map((s) => LogSet.fromJson(s as Map<String, dynamic>)).toList(),
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': exerciseId, 'sets': sets.map((s) => s.toJson()).toList(), 'notes': notes};

  double get totalVolume => sets.where((s) => !s.isBodyweight).fold(0.0, (v, s) => v + (s.weight ?? 0) * s.reps);
  LogSet? get bestSet => sets.isEmpty ? null : sets.reduce((a, b) => a.score >= b.score ? a : b);
}

class LogSession {
  final String id;
  final DateTime date;
  final int sessionType;
  final List<LogExercise> exercises;
  final String? notes;

  LogSession({
    String? id,
    required this.date,
    required this.sessionType,
    required this.exercises,
    this.notes,
  }) : id = id ?? _uuid.v4();

  factory LogSession.fromJson(Map<String, dynamic> j) => LogSession(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        sessionType: j['type'] as int,
        exercises: (j['exercises'] as List).map((e) => LogExercise.fromJson(e as Map<String, dynamic>)).toList(),
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'type': sessionType,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'notes': notes,
      };

  double get totalVolume => exercises.fold(0.0, (v, e) => v + e.totalVolume);
  int get totalSets => exercises.fold(0, (v, e) => v + e.sets.length);
}

// Config d'une des 4 séances
class SessionConfig {
  final int type;
  final String name;
  final String subtitle;
  final Color color;
  final List<String> defaultExerciseIds;

  const SessionConfig({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.defaultExerciseIds,
  });
}
