import 'exercise.dart';

class WorkoutSet {
  final double weight;
  final int reps;
  final bool completed;
  final Duration? restTime;

  const WorkoutSet({
    required this.weight,
    required this.reps,
    this.completed = false,
    this.restTime,
  });

  WorkoutSet copyWith({double? weight, int? reps, bool? completed}) => WorkoutSet(
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        completed: completed ?? this.completed,
        restTime: restTime,
      );
}

class WorkoutExercise {
  final Exercise exercise;
  final List<WorkoutSet> sets;
  final String? notes;

  const WorkoutExercise({
    required this.exercise,
    required this.sets,
    this.notes,
  });

  WorkoutExercise copyWith({List<WorkoutSet>? sets, String? notes}) => WorkoutExercise(
        exercise: exercise,
        sets: sets ?? this.sets,
        notes: notes ?? this.notes,
      );

  int get totalVolume =>
      sets.where((s) => s.completed).fold(0, (sum, s) => sum + (s.weight * s.reps).toInt());
}

class Workout {
  final String id;
  final String name;
  final String? description;
  final List<WorkoutExercise> exercises;
  final DateTime? lastPerformed;
  final Duration? estimatedDuration;
  final bool isFavorite;

  const Workout({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
    this.lastPerformed,
    this.estimatedDuration,
    this.isFavorite = false,
  });

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
  List<MuscleGroup> get muscleGroups =>
      exercises.map((e) => e.exercise.primaryMuscle).toSet().toList();
}

class WorkoutSession {
  final String id;
  final Workout workout;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutExercise> exercises;
  final String? notes;

  const WorkoutSession({
    required this.id,
    required this.workout,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.notes,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  int get totalVolume =>
      exercises.fold(0, (sum, e) => sum + e.totalVolume);

  int get completedSets =>
      exercises.fold(0, (sum, e) => sum + e.sets.where((s) => s.completed).length);

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  bool get isCompleted => endTime != null;
}
