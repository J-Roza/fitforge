import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/workout.dart';
import '../data/models/exercise.dart';
import '../data/datasources/exercises_data.dart';

const _uuid = Uuid();

// ── Workout templates library ────────────────────────────────────────────────
final workoutTemplatesProvider =
    StateNotifierProvider<WorkoutTemplatesNotifier, List<Workout>>(
  (ref) => WorkoutTemplatesNotifier(),
);

class WorkoutTemplatesNotifier extends StateNotifier<List<Workout>> {
  WorkoutTemplatesNotifier() : super(_defaultWorkouts());

  void addWorkout(Workout w) => state = [...state, w];

  void removeWorkout(String id) =>
      state = state.where((w) => w.id != id).toList();

  void toggleFavorite(String id) {
    state = [
      for (final w in state)
        if (w.id == id)
          Workout(
            id: w.id,
            name: w.name,
            description: w.description,
            exercises: w.exercises,
            lastPerformed: w.lastPerformed,
            estimatedDuration: w.estimatedDuration,
            isFavorite: !w.isFavorite,
          )
        else
          w
    ];
  }
}

// ── Active session ────────────────────────────────────────────────────────────
final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, WorkoutSession?>(
  (ref) => ActiveSessionNotifier(),
);

class ActiveSessionNotifier extends StateNotifier<WorkoutSession?> {
  ActiveSessionNotifier() : super(null);

  void startSession(Workout workout) {
    state = WorkoutSession(
      id: _uuid.v4(),
      workout: workout,
      startTime: DateTime.now(),
      exercises: workout.exercises,
    );
  }

  void completeSet(int exerciseIndex, int setIndex) {
    final session = state;
    if (session == null) return;

    final exercises = List<WorkoutExercise>.from(session.exercises);
    final exercise = exercises[exerciseIndex];
    final sets = List<WorkoutSet>.from(exercise.sets);
    sets[setIndex] = sets[setIndex].copyWith(completed: true);
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);

    state = WorkoutSession(
      id: session.id,
      workout: session.workout,
      startTime: session.startTime,
      exercises: exercises,
    );
  }

  void updateSetWeight(int exerciseIndex, int setIndex, double weight) {
    final session = state;
    if (session == null) return;
    final exercises = List<WorkoutExercise>.from(session.exercises);
    final exercise = exercises[exerciseIndex];
    final sets = List<WorkoutSet>.from(exercise.sets);
    sets[setIndex] = sets[setIndex].copyWith(weight: weight);
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = WorkoutSession(
      id: session.id,
      workout: session.workout,
      startTime: session.startTime,
      exercises: exercises,
    );
  }

  void updateSetReps(int exerciseIndex, int setIndex, int reps) {
    final session = state;
    if (session == null) return;
    final exercises = List<WorkoutExercise>.from(session.exercises);
    final exercise = exercises[exerciseIndex];
    final sets = List<WorkoutSet>.from(exercise.sets);
    sets[setIndex] = sets[setIndex].copyWith(reps: reps);
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = WorkoutSession(
      id: session.id,
      workout: session.workout,
      startTime: session.startTime,
      exercises: exercises,
    );
  }

  void finishSession() {
    if (state == null) return;
    state = WorkoutSession(
      id: state!.id,
      workout: state!.workout,
      startTime: state!.startTime,
      endTime: DateTime.now(),
      exercises: state!.exercises,
    );
  }

  void cancelSession() => state = null;
}

// ── History ───────────────────────────────────────────────────────────────────
final sessionHistoryProvider =
    StateNotifierProvider<SessionHistoryNotifier, List<WorkoutSession>>(
  (ref) => SessionHistoryNotifier(),
);

class SessionHistoryNotifier extends StateNotifier<List<WorkoutSession>> {
  SessionHistoryNotifier() : super([]);

  void addSession(WorkoutSession session) =>
      state = [session, ...state];

  int get weeklyCount {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return state.where((s) => s.startTime.isAfter(weekAgo)).length;
  }
}

// ── Default workout templates ─────────────────────────────────────────────────
List<Workout> _defaultWorkouts() {
  Exercise ex(String id) => allExercises.firstWhere((e) => e.id == id);

  WorkoutExercise we(String exId, int sets, double weight, int reps) =>
      WorkoutExercise(
        exercise: ex(exId),
        sets: List.generate(
          sets,
          (_) => WorkoutSet(weight: weight, reps: reps),
        ),
      );

  return [
    Workout(
      id: _uuid.v4(),
      name: 'Push — Pectoraux & Épaules',
      description: 'Séance de poussée horizontale et verticale',
      estimatedDuration: const Duration(minutes: 55),
      exercises: [
        we('bench_press', 4, 80, 8),
        we('incline_bench_press', 4, 60, 10),
        we('dumbbell_flyes', 3, 20, 12),
        we('ohp', 3, 50, 10),
        we('lateral_raise', 4, 10, 15),
        we('tricep_pushdown', 3, 30, 15),
      ],
    ),
    Workout(
      id: _uuid.v4(),
      name: 'Pull — Dos & Biceps',
      description: 'Séance de tirage et traction',
      estimatedDuration: const Duration(minutes: 50),
      exercises: [
        we('pull_up', 4, 0, 8),
        we('barbell_row', 4, 70, 8),
        we('lat_pulldown', 3, 60, 12),
        we('seated_row', 3, 50, 12),
        we('face_pull', 3, 20, 15),
        we('barbell_curl', 3, 35, 12),
        we('hammer_curl', 3, 15, 12),
      ],
    ),
    Workout(
      id: _uuid.v4(),
      name: 'Legs — Quadriceps & Fessiers',
      description: 'Séance jambes complète',
      estimatedDuration: const Duration(minutes: 60),
      exercises: [
        we('squat', 4, 100, 6),
        we('leg_press', 4, 150, 12),
        we('leg_extension', 3, 50, 15),
        we('romanian_deadlift', 3, 70, 10),
        we('leg_curl', 3, 45, 12),
        we('hip_thrust', 4, 80, 12),
        we('calf_raise', 4, 60, 20),
      ],
    ),
    Workout(
      id: _uuid.v4(),
      name: 'Full Body Force',
      description: 'Mouvements fondamentaux à charge maximale',
      estimatedDuration: const Duration(minutes: 65),
      exercises: [
        we('deadlift', 4, 120, 4),
        we('bench_press', 4, 90, 5),
        we('squat', 4, 110, 5),
        we('ohp', 3, 55, 6),
        we('pull_up', 3, 0, 6),
      ],
    ),
    Workout(
      id: _uuid.v4(),
      name: 'Core & Mobilité',
      description: 'Gainage, abdos et étirements',
      estimatedDuration: const Duration(minutes: 30),
      exercises: [
        we('plank', 3, 0, 1),
        we('crunch', 3, 0, 20),
        we('russian_twist', 3, 5, 20),
        we('leg_raise', 3, 0, 12),
        we('ab_wheel', 3, 0, 10),
      ],
    ),
  ];
}
