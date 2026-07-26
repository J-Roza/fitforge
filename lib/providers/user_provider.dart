import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/user_profile.dart';
import '../data/models/workout.dart';
import '../data/datasources/exercises_data.dart';
import '../services/cloud_sync_service.dart';

const _uuid = Uuid();

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(),
);

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  static const _key = 'user_profile_v1';

  UserProfileNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        state = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (state != null) {
      await prefs.setString(_key, jsonEncode(state!.toJson()));
    } else {
      await prefs.remove(_key);
    }
    CloudSyncService.pushIfSignedIn();
  }

  void createProfile({
    required String name,
    int? age,
    double? weightKg,
    double? heightCm,
    Somatotype? somatotype,
    required FitnessGoal goal,
    required FitnessLevel level,
    required AvailableEquipment equipment,
    int workoutsPerWeek = 4,
  }) {
    state = UserProfile(
      id: _uuid.v4(),
      name: name,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      somatotype: somatotype,
      goal: goal,
      level: level,
      equipment: equipment,
      workoutsPerWeek: workoutsPerWeek,
    );
    _save();
  }

  void update(UserProfile profile) {
    state = profile;
    _save();
  }

  void updateMeasurements(Measurements measurements) {
    if (state == null) return;
    state = state!.copyWith(measurements: measurements);
    _save();
  }
}

// ── AI Workout Generator ──────────────────────────────────────────────────────
final generatedWorkoutProvider = Provider.family<List<Workout>, UserProfile>(
  (ref, profile) => generateWorkoutsForProfile(profile),
);

List<Workout> generateWorkoutsForProfile(UserProfile profile) {
  // Determine push/pull/legs split based on days per week
  switch (profile.workoutsPerWeek) {
    case 3:
      return _fullBodySplit(profile);
    case 4:
      return _upperLowerSplit(profile);
    case 5:
    case 6:
      return _pplSplit(profile);
    default:
      return _fullBodySplit(profile);
  }
}

List<Workout> _fullBodySplit(UserProfile profile) {
  return [
    _buildWorkout('Full Body A', _fullBodyAExercises(profile), 60),
    _buildWorkout('Full Body B', _fullBodyBExercises(profile), 60),
    _buildWorkout('Full Body C', _fullBodyCExercises(profile), 55),
  ];
}

List<Workout> _upperLowerSplit(UserProfile profile) {
  return [
    _buildWorkout('Haut du corps A', _upperAExercises(profile), 55),
    _buildWorkout('Bas du corps A', _lowerAExercises(profile), 60),
    _buildWorkout('Haut du corps B', _upperBExercises(profile), 55),
    _buildWorkout('Bas du corps B', _lowerBExercises(profile), 60),
  ];
}

List<Workout> _pplSplit(UserProfile profile) {
  return [
    _buildWorkout('Push', _pushExercises(profile), 55),
    _buildWorkout('Pull', _pullExercises(profile), 55),
    _buildWorkout('Legs', _legExercises(profile), 60),
    _buildWorkout('Push (variation)', _pushVariationExercises(profile), 55),
    _buildWorkout('Pull (variation)', _pullVariationExercises(profile), 55),
    if (profile.workoutsPerWeek >= 6)
      _buildWorkout('Legs (variation)', _legExercises(profile), 60),
  ];
}

Workout _buildWorkout(String name, List<WorkoutExercise> exercises, int minutes) =>
    Workout(
      id: const Uuid().v4(),
      name: name,
      exercises: exercises,
      estimatedDuration: Duration(minutes: minutes),
    );

WorkoutExercise _we(String id, int sets, double weight, int reps) {
  from(String exId) {
    try {
      return allExercises.firstWhere((e) => e.id == exId);
    } catch (_) {
      return allExercises.first;
    }
  }

  return WorkoutExercise(
    exercise: from(id),
    sets: List.generate(sets, (_) => WorkoutSet(weight: weight, reps: reps)),
  );
}

List<WorkoutExercise> _pushExercises(UserProfile p) => [
      if (p.equipment != AvailableEquipment.bodyweightOnly)
        _we('bench_press', p.level == FitnessLevel.beginner ? 3 : 4, 70, 8),
      _we('push_up', 3, 0, 15),
      _we('ohp', 3, 40, 10),
      _we('lateral_raise', 3, 8, 15),
      _we('tricep_pushdown', 3, 25, 15),
    ];

List<WorkoutExercise> _pushVariationExercises(UserProfile p) => [
      _we('incline_bench_press', 4, 60, 10),
      _we('dumbbell_flyes', 3, 16, 12),
      _we('arnold_press', 3, 14, 12),
      _we('lateral_raise', 4, 10, 15),
      _we('skull_crusher', 3, 30, 12),
    ];

List<WorkoutExercise> _pullExercises(UserProfile p) => [
      _we('pull_up', 4, 0, p.level == FitnessLevel.beginner ? 5 : 8),
      _we('barbell_row', 4, 60, 8),
      _we('face_pull', 3, 18, 15),
      _we('barbell_curl', 3, 30, 12),
      _we('hammer_curl', 3, 14, 12),
    ];

List<WorkoutExercise> _pullVariationExercises(UserProfile p) => [
      _we('lat_pulldown', 4, 55, 12),
      _we('dumbbell_row', 4, 22, 10),
      _we('seated_row', 3, 45, 12),
      _we('preacher_curl', 3, 20, 12),
      _we('concentration_curl', 3, 12, 15),
    ];

List<WorkoutExercise> _legExercises(UserProfile p) => [
      if (p.equipment != AvailableEquipment.bodyweightOnly)
        _we('squat', 4, p.level == FitnessLevel.beginner ? 60 : 90, 6),
      _we('lunges', 3, 0, 12),
      _we('leg_press', 3, 120, 12),
      _we('romanian_deadlift', 3, 60, 10),
      _we('hip_thrust', 3, 70, 12),
      _we('calf_raise', 4, 0, 20),
    ];

List<WorkoutExercise> _fullBodyAExercises(UserProfile p) => [
      _we('squat', 3, 80, 6),
      _we('bench_press', 3, 70, 8),
      _we('barbell_row', 3, 60, 8),
      _we('ohp', 2, 40, 10),
      _we('plank', 3, 0, 1),
    ];

List<WorkoutExercise> _fullBodyBExercises(UserProfile p) => [
      _we('deadlift', 3, 100, 5),
      _we('incline_bench_press', 3, 55, 10),
      _we('pull_up', 3, 0, 6),
      _we('lateral_raise', 3, 8, 15),
      _we('crunch', 3, 0, 20),
    ];

List<WorkoutExercise> _fullBodyCExercises(UserProfile p) => [
      _we('leg_press', 3, 120, 12),
      _we('dips_chest', 3, 0, 10),
      _we('lat_pulldown', 3, 50, 12),
      _we('hip_thrust', 3, 60, 12),
      _we('plank', 3, 0, 1),
    ];

List<WorkoutExercise> _upperAExercises(UserProfile p) => [
      _we('bench_press', 4, 75, 8),
      _we('barbell_row', 4, 65, 8),
      _we('ohp', 3, 45, 10),
      _we('lat_pulldown', 3, 55, 12),
      _we('barbell_curl', 3, 32, 12),
      _we('skull_crusher', 3, 28, 12),
    ];

List<WorkoutExercise> _upperBExercises(UserProfile p) => [
      _we('incline_bench_press', 4, 60, 10),
      _we('pull_up', 4, 0, 7),
      _we('dumbbell_flyes', 3, 16, 12),
      _we('face_pull', 3, 18, 15),
      _we('hammer_curl', 3, 14, 12),
      _we('tricep_pushdown', 3, 28, 15),
    ];

List<WorkoutExercise> _lowerAExercises(UserProfile p) => [
      _we('squat', 4, 90, 6),
      _we('leg_press', 3, 140, 12),
      _we('leg_extension', 3, 45, 15),
      _we('romanian_deadlift', 3, 65, 10),
      _we('hip_thrust', 4, 75, 12),
    ];

List<WorkoutExercise> _lowerBExercises(UserProfile p) => [
      _we('deadlift', 4, 110, 5),
      _we('lunges', 3, 20, 12),
      _we('leg_curl', 3, 40, 12),
      _we('calf_raise', 4, 50, 20),
      _we('hip_thrust', 3, 70, 10),
    ];
