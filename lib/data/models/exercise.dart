import 'package:flutter/material.dart';
import 'package:fitforge/core/theme/app_colors.dart';

enum ExerciseRole { base, advanced, finishing }

extension ExerciseRoleExt on ExerciseRole {
  String get label {
    switch (this) {
      case ExerciseRole.base: return 'Base';
      case ExerciseRole.advanced: return 'Avancé';
      case ExerciseRole.finishing: return 'Finition';
    }
  }

  String get stars {
    switch (this) {
      case ExerciseRole.base: return '★';
      case ExerciseRole.advanced: return '★★';
      case ExerciseRole.finishing: return '★★★';
    }
  }

  Color get color {
    switch (this) {
      case ExerciseRole.base: return AppColors.accent;
      case ExerciseRole.advanced: return AppColors.secondary;
      case ExerciseRole.finishing: return AppColors.warning;
    }
  }
}

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  legs,
  glutes,
  core,
  cardio,
  fullBody,
}

enum Equipment {
  barbell,
  dumbbell,
  cable,
  machine,
  bodyweight,
  kettlebell,
  resistanceBand,
  pullupBar,
  bench,
  none,
}

enum Difficulty { beginner, intermediate, advanced }

enum ExerciseCategory { compound, isolation, cardio, stretch }

class Exercise {
  final String id;
  final String name;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final List<Equipment> equipment;
  final Difficulty difficulty;
  final ExerciseCategory category;
  final String description;
  final List<String> instructions;
  final List<String> commonMistakes;
  final String? imageUrl;
  final String? videoUrl;
  final String? gifUrl;
  final bool isFavorite;
  final int? defaultSets;
  final String? defaultReps;
  final ExerciseRole role;

  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    required this.difficulty,
    required this.category,
    required this.description,
    this.instructions = const [],
    this.commonMistakes = const [],
    this.imageUrl,
    this.videoUrl,
    this.gifUrl,
    this.isFavorite = false,
    this.defaultSets,
    this.defaultReps,
    this.role = ExerciseRole.base,
  });

  String get youtubeSearchUrl {
    final query = Uri.encodeComponent('technique $name musculation');
    return 'https://www.youtube.com/results?search_query=$query';
  }

  /// Photo réelle de démonstration (free-exercise-db, domaine public).
  /// Retourne null si aucune photo n'a été trouvée pour cet exercice —
  /// dans ce cas l'UI doit retomber sur [iconAsset].
  static const _withPhoto = {
    'machine_converging_press_seated', 'dumbbell_bench_press', 'bench_press',
    'machine_converging_press_flat', 'dumbbell_decline_press', 'decline_bench_press',
    'dumbbell_incline_press', 'incline_bench_press', 'incline_machine_converging_press',
    'dips_chest', 'pullover_barbell', 'pullover_across_bench', 'dumbbell_flyes',
    'decline_dumbbell_flyes', 'incline_dumbbell_flyes', 'machine_flyes', 'push_up',
    'cable_crossover_low', 'cable_crossover', 'machine_chest_press_flat',
    'pull_up', 'deadlift', 'barbell_row', 'lat_pulldown', 'seated_row', 'dumbbell_row',
    't_bar_row', 'shrugs', 'chin_up', 'back_extension',
    'ohp', 'lateral_raise', 'arnold_press', 'front_raise', 'rear_delt_fly',
    'seated_dumbbell_press', 'upright_row',
    'barbell_curl', 'hammer_curl', 'preacher_curl', 'concentration_curl',
    'dumbbell_curl', 'incline_dumbbell_curl',
    'skull_crusher', 'tricep_pushdown', 'close_grip_bench', 'overhead_tricep_extension',
    'tricep_kickback', 'bench_dips',
    'squat', 'leg_press', 'romanian_deadlift', 'lunges', 'leg_extension', 'leg_curl',
    'hip_thrust', 'calf_raise', 'goblet_squat', 'bulgarian_split_squat', 'front_squat',
    'step_up',
    'plank', 'crunch', 'russian_twist', 'leg_raise', 'ab_wheel', 'mountain_climber',
    'side_plank',
    'kettlebell_swing',
  };

  String? get photoAsset =>
      _withPhoto.contains(id) ? 'assets/exercise_photos/$id.jpg' : null;

  String get iconAsset {
    const base = 'assets/exercise_icons/';
    switch (id) {
      case 'bench_press': return '${base}bench_press.svg';
      case 'dumbbell_bench_press': return '${base}bench_press.svg';
      case 'close_grip_bench': return '${base}bench_press.svg';
      case 'incline_bench_press': return '${base}incline_press.svg';
      case 'dumbbell_incline_press': return '${base}incline_press.svg';
      case 'incline_machine_converging_press': return '${base}incline_press.svg';
      case 'decline_bench_press': return '${base}decline_press.svg';
      case 'dumbbell_decline_press': return '${base}decline_press.svg';
      case 'machine_converging_press_seated': return '${base}machine_press.svg';
      case 'machine_converging_press_flat': return '${base}machine_press.svg';
      case 'machine_chest_press_flat': return '${base}machine_press.svg';
      case 'dips_chest': return '${base}dips.svg';
      case 'push_up': return '${base}push_up.svg';
      case 'dumbbell_flyes': return '${base}chest_flyes.svg';
      case 'decline_dumbbell_flyes': return '${base}chest_flyes.svg';
      case 'incline_dumbbell_flyes': return '${base}chest_flyes.svg';
      case 'machine_flyes': return '${base}chest_flyes.svg';
      case 'cable_crossover': return '${base}cable_crossover.svg';
      case 'cable_crossover_low': return '${base}cable_crossover.svg';
      case 'pullover_barbell': return '${base}pullover.svg';
      case 'pullover_across_bench': return '${base}pullover.svg';
      case 'pullover_low_cable': return '${base}pullover.svg';
      case 'pull_up': return '${base}pull_up.svg';
      case 'deadlift': return '${base}deadlift.svg';
      case 'barbell_row': return '${base}bent_row.svg';
      case 'dumbbell_row': return '${base}bent_row.svg';
      case 'lat_pulldown': return '${base}lat_pulldown.svg';
      case 'seated_row': return '${base}seated_row.svg';
      case 'face_pull': return '${base}face_pull.svg';
      case 'ohp': return '${base}overhead_press.svg';
      case 'arnold_press': return '${base}overhead_press.svg';
      case 'lateral_raise': return '${base}lateral_raise.svg';
      case 'front_raise': return '${base}front_raise.svg';
      case 'barbell_curl': return '${base}bicep_curl.svg';
      case 'preacher_curl': return '${base}bicep_curl.svg';
      case 'concentration_curl': return '${base}bicep_curl.svg';
      case 'hammer_curl': return '${base}hammer_curl.svg';
      case 'skull_crusher': return '${base}skull_crusher.svg';
      case 'tricep_pushdown': return '${base}tricep_pushdown.svg';
      case 'overhead_tricep_extension': return '${base}overhead_tricep.svg';
      case 'squat': return '${base}squat.svg';
      case 'leg_press': return '${base}leg_press.svg';
      case 'romanian_deadlift': return '${base}romanian_deadlift.svg';
      case 'lunges': return '${base}lunges.svg';
      case 'leg_extension': return '${base}leg_extension.svg';
      case 'leg_curl': return '${base}leg_curl.svg';
      case 'hip_thrust': return '${base}hip_thrust.svg';
      case 'calf_raise': return '${base}calf_raise.svg';
      case 'plank': return '${base}plank.svg';
      case 'crunch': return '${base}crunch.svg';
      case 'russian_twist': return '${base}russian_twist.svg';
      case 'leg_raise': return '${base}leg_raise.svg';
      case 'ab_wheel': return '${base}ab_wheel.svg';
      case 'kettlebell_swing': return '${base}kettlebell_swing.svg';
      case 'burpee': return '${base}burpee.svg';
      // ─── Ajouts ───
      case 't_bar_row': return '${base}bent_row.svg';
      case 'shrugs': return '${base}shrugs.svg';
      case 'chin_up': return '${base}pull_up.svg';
      case 'back_extension': return '${base}back_extension.svg';
      case 'rear_delt_fly': return '${base}rear_delt_fly.svg';
      case 'seated_dumbbell_press': return '${base}overhead_press.svg';
      case 'upright_row': return '${base}upright_row.svg';
      case 'dumbbell_curl': return '${base}bicep_curl.svg';
      case 'incline_dumbbell_curl': return '${base}bicep_curl.svg';
      case 'tricep_kickback': return '${base}tricep_kickback.svg';
      case 'bench_dips': return '${base}bench_dips.svg';
      case 'goblet_squat': return '${base}squat.svg';
      case 'bulgarian_split_squat': return '${base}lunges.svg';
      case 'front_squat': return '${base}squat.svg';
      case 'step_up': return '${base}step_up.svg';
      case 'bicycle_crunch': return '${base}crunch.svg';
      case 'mountain_climber': return '${base}mountain_climber.svg';
      case 'side_plank': return '${base}side_plank.svg';
      case 'jumping_jack': return '${base}jumping_jack.svg';
      default: return '${base}bench_press.svg';
    }
  }

  Exercise copyWith({bool? isFavorite}) => Exercise(
        id: id,
        name: name,
        primaryMuscle: primaryMuscle,
        secondaryMuscles: secondaryMuscles,
        equipment: equipment,
        difficulty: difficulty,
        category: category,
        description: description,
        instructions: instructions,
        commonMistakes: commonMistakes,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        gifUrl: gifUrl,
        isFavorite: isFavorite ?? this.isFavorite,
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        role: role,
      );
}

extension MuscleGroupExt on MuscleGroup {
  String get label {
    switch (this) {
      case MuscleGroup.chest: return 'Pectoraux';
      case MuscleGroup.back: return 'Dos';
      case MuscleGroup.shoulders: return 'Épaules';
      case MuscleGroup.biceps: return 'Biceps';
      case MuscleGroup.triceps: return 'Triceps';
      case MuscleGroup.legs: return 'Jambes';
      case MuscleGroup.glutes: return 'Fessiers';
      case MuscleGroup.core: return 'Abdos';
      case MuscleGroup.cardio: return 'Cardio';
      case MuscleGroup.fullBody: return 'Full Body';
    }
  }

  Color get color {
    switch (this) {
      case MuscleGroup.chest: return AppColors.chest;
      case MuscleGroup.back: return AppColors.back;
      case MuscleGroup.shoulders: return AppColors.shoulders;
      case MuscleGroup.biceps: return AppColors.arms;
      case MuscleGroup.triceps: return AppColors.arms;
      case MuscleGroup.legs: return AppColors.legs;
      case MuscleGroup.glutes: return AppColors.legs;
      case MuscleGroup.core: return AppColors.core;
      case MuscleGroup.cardio: return AppColors.cardio;
      case MuscleGroup.fullBody: return AppColors.accent;
    }
  }

  String get emoji {
    switch (this) {
      case MuscleGroup.chest: return '🫸';      // poussée pectoraux
      case MuscleGroup.back: return '🫷';       // traction dos
      case MuscleGroup.shoulders: return '🏋️'; // épaules / presses
      case MuscleGroup.biceps: return '💪';     // biceps classique
      case MuscleGroup.triceps: return '👊';    // extension triceps
      case MuscleGroup.legs: return '🦵';       // jambes
      case MuscleGroup.glutes: return '🍑';     // fessiers
      case MuscleGroup.core: return '🔥';       // abdos / gainage
      case MuscleGroup.cardio: return '❤️‍🔥';    // cardio
      case MuscleGroup.fullBody: return '⚡';   // full body
    }
  }
}

extension EquipmentExt on Equipment {
  String get label {
    switch (this) {
      case Equipment.barbell: return 'Barre';
      case Equipment.dumbbell: return 'Haltères';
      case Equipment.cable: return 'Câble';
      case Equipment.machine: return 'Machine';
      case Equipment.bodyweight: return 'Poids du corps';
      case Equipment.kettlebell: return 'Kettlebell';
      case Equipment.resistanceBand: return 'Élastique';
      case Equipment.pullupBar: return 'Barre de traction';
      case Equipment.bench: return 'Banc';
      case Equipment.none: return 'Aucun';
    }
  }
}

extension DifficultyExt on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.beginner: return 'Débutant';
      case Difficulty.intermediate: return 'Intermédiaire';
      case Difficulty.advanced: return 'Avancé';
    }
  }

  Color get color {
    switch (this) {
      case Difficulty.beginner: return AppColors.easy;
      case Difficulty.intermediate: return AppColors.medium;
      case Difficulty.advanced: return AppColors.hard;
    }
  }
}
