import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/exercise.dart';
import '../data/datasources/exercises_data.dart';

// All exercises
final exercisesProvider = Provider<List<Exercise>>((ref) => allExercises);

// Selected muscle filter
final selectedMuscleProvider = StateProvider<MuscleGroup?>((ref) => null);

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Selected difficulty filter
final selectedDifficultyProvider = StateProvider<Difficulty?>((ref) => null);

// Filtered exercises
final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final exercises = ref.watch(exercisesProvider);
  final muscle = ref.watch(selectedMuscleProvider);
  final query = ref.watch(searchQueryProvider);
  final difficulty = ref.watch(selectedDifficultyProvider);

  return exercises.where((e) {
    final matchesMuscle = muscle == null || e.primaryMuscle == muscle;
    final matchesQuery = query.isEmpty ||
        e.name.toLowerCase().contains(query.toLowerCase()) ||
        e.primaryMuscle.label.toLowerCase().contains(query.toLowerCase());
    final matchesDifficulty = difficulty == null || e.difficulty == difficulty;
    return matchesMuscle && matchesQuery && matchesDifficulty;
  }).toList();
});

// Favorites
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({});

  void toggle(String exerciseId) {
    if (state.contains(exerciseId)) {
      state = {...state}..remove(exerciseId);
    } else {
      state = {...state, exerciseId};
    }
  }

  bool isFavorite(String id) => state.contains(id);
}

final favoriteExercisesProvider = Provider<List<Exercise>>((ref) {
  final favorites = ref.watch(favoritesProvider);
  final exercises = ref.watch(exercisesProvider);
  return exercises.where((e) => favorites.contains(e.id)).toList();
});
