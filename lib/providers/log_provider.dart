import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/log_models.dart';
import '../services/log_service.dart';
import '../services/cloud_sync_service.dart';

// ── Sessions config ──────────────────────────────────────────
const _defaultSessions = [
  SessionConfig(
    type: 1, name: 'PUSH', subtitle: 'Pecs · Épaules · Triceps', color: Color(0xFFE8484F),
    defaultExerciseIds: ['bench_press', 'incline_bench_press', 'lateral_raise', 'overhead_tricep_extension', 'skull_crusher', 'dips_chest'],
  ),
  SessionConfig(
    type: 2, name: 'PULL + BICEPS', subtitle: 'Dos · Biceps', color: Color(0xFF4F9EE8),
    defaultExerciseIds: ['barbell_row', 'dumbbell_row', 'preacher_curl', 'barbell_curl', 'hammer_curl'],
  ),
  SessionConfig(
    type: 3, name: 'LEGS', subtitle: 'Jambes · Ischios · Fessiers', color: Color(0xFF30D158),
    defaultExerciseIds: ['deadlift', 'squat', 'lunges', 'leg_curl'],
  ),
  SessionConfig(
    type: 4, name: 'ÉPAULES +', subtitle: 'Épaules · Biceps · Dos', color: Color(0xFFFF9F0A),
    defaultExerciseIds: ['ohp', 'lateral_raise', 'barbell_row', 'dumbbell_flyes', 'hammer_curl'],
  ),
];

class SessionsConfigNotifier extends StateNotifier<List<SessionConfig>> {
  SessionsConfigNotifier(this.ref) : super(_defaultSessions) {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    final saved = await ref.read(logServiceProvider).loadSessionsConfig();
    if (saved != null && saved.isNotEmpty) state = saved;
  }

  Future<void> _persist() async {
    await ref.read(logServiceProvider).saveSessionsConfig(state);
    CloudSyncService.pushIfSignedIn();
  }

  /// Crée une nouvelle séance personnalisée et retourne son `type` (id).
  int addSession({
    required String name,
    required String subtitle,
    required Color color,
    List<String> exerciseIds = const [],
  }) {
    final nextType = state.isEmpty
        ? 1
        : state.map((s) => s.type).reduce((a, b) => a > b ? a : b) + 1;
    final config = SessionConfig(
      type: nextType,
      name: name,
      subtitle: subtitle,
      color: color,
      defaultExerciseIds: exerciseIds,
    );
    state = [...state, config];
    _persist();
    return nextType;
  }

  /// Renomme / recolore une séance existante.
  void updateSession(int type, {String? name, String? subtitle, Color? color}) {
    state = state
        .map((s) => s.type == type
            ? s.copyWith(name: name, subtitle: subtitle, color: color)
            : s)
        .toList();
    _persist();
  }

  /// Supprime une séance et nettoie les références (planning, exercices perso).
  Future<void> removeSession(int type) async {
    if (state.length <= 1) return; // toujours garder au moins une séance
    state = state.where((s) => s.type != type).toList();
    await _persist();

    final plan = ref.read(planningProvider).value ?? {};
    for (final entry in plan.entries.where((e) => e.value == type).toList()) {
      await ref.read(planningProvider.notifier).setDay(entry.key, null);
    }
    await ref.read(customSessionsProvider.notifier).resetSession(type, const []);
  }
}

final sessionsConfigProvider =
    StateNotifierProvider<SessionsConfigNotifier, List<SessionConfig>>(
        (ref) => SessionsConfigNotifier(ref));

// ── Log service ───────────────────────────────────────────────
final logServiceProvider = Provider<LogService>((ref) => LogService());

// ── History notifier ──────────────────────────────────────────
class LogHistoryNotifier extends AsyncNotifier<List<LogSession>> {
  @override
  Future<List<LogSession>> build() async {
    return ref.read(logServiceProvider).loadHistory();
  }

  Future<void> addSession(LogSession session) async {
    final current = state.value ?? [];
    final updated = [...current, session];
    await ref.read(logServiceProvider).saveHistory(updated);
    state = AsyncData(updated);
    CloudSyncService.pushIfSignedIn();
  }

  Future<void> removeSession(String id) async {
    final current = state.value ?? [];
    final updated = current.where((s) => s.id != id).toList();
    await ref.read(logServiceProvider).saveHistory(updated);
    state = AsyncData(updated);
    CloudSyncService.pushIfSignedIn();
  }

  /// Remplace une séance existante (même id) par sa version modifiée.
  Future<void> updateSession(LogSession updated) async {
    final current = state.value ?? [];
    final list = current.map((s) => s.id == updated.id ? updated : s).toList();
    await ref.read(logServiceProvider).saveHistory(list);
    state = AsyncData(list);
    CloudSyncService.pushIfSignedIn();
  }
}
final logHistoryProvider = AsyncNotifierProvider<LogHistoryNotifier, List<LogSession>>(LogHistoryNotifier.new);

// ── PRs (computed from history) ───────────────────────────────
final personalRecordsProvider = Provider<Map<String, LogSet>>((ref) {
  final history = ref.watch(logHistoryProvider).value ?? [];
  final Map<String, LogSet> prs = {};
  for (final session in history) {
    for (final ex in session.exercises) {
      for (final set in ex.sets) {
        final current = prs[ex.exerciseId];
        if (current == null || set.score > current.score) {
          prs[ex.exerciseId] = set;
        }
      }
    }
  }
  return prs;
});

// ── Exercise history (per exercise) ──────────────────────────
final exerciseHistoryProvider = Provider.family<List<({DateTime date, List<LogSet> sets})>, String>((ref, exerciseId) {
  final history = ref.watch(logHistoryProvider).value ?? [];
  return history
      .where((s) => s.exercises.any((e) => e.exerciseId == exerciseId))
      .map((s) {
        final ex = s.exercises.firstWhere((e) => e.exerciseId == exerciseId);
        return (date: s.date, sets: ex.sets);
      })
      .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
});

// ── Last weights notifier ─────────────────────────────────────
class LastWeightsNotifier extends AsyncNotifier<Map<String, double?>> {
  @override
  Future<Map<String, double?>> build() => ref.read(logServiceProvider).loadLastWeights();

  Future<void> setWeight(String exerciseId, double? weight) async {
    final current = Map<String, double?>.from(state.value ?? {});
    current[exerciseId] = weight;
    await ref.read(logServiceProvider).saveLastWeights(current);
    state = AsyncData(current);
  }
}
final lastWeightsProvider = AsyncNotifierProvider<LastWeightsNotifier, Map<String, double?>>(LastWeightsNotifier.new);

// ── Last reps notifier ────────────────────────────────────────
class LastRepsNotifier extends AsyncNotifier<Map<String, int>> {
  @override
  Future<Map<String, int>> build() => ref.read(logServiceProvider).loadLastReps();

  Future<void> setReps(String exerciseId, int reps) async {
    final current = Map<String, int>.from(state.value ?? {});
    current[exerciseId] = reps;
    await ref.read(logServiceProvider).saveLastReps(current);
    state = AsyncData(current);
  }
}
final lastRepsProvider = AsyncNotifierProvider<LastRepsNotifier, Map<String, int>>(LastRepsNotifier.new);

// ── Planning notifier ─────────────────────────────────────────
class PlanningNotifier extends AsyncNotifier<Map<int, int>> {
  @override
  Future<Map<int, int>> build() => ref.read(logServiceProvider).loadPlanning();

  Future<void> setDay(int dayOfWeek, int? sessionType) async {
    final current = Map<int, int>.from(state.value ?? {});
    if (sessionType == null) { current.remove(dayOfWeek); } else { current[dayOfWeek] = sessionType; }
    await ref.read(logServiceProvider).savePlanning(current);
    state = AsyncData(current);
    CloudSyncService.pushIfSignedIn();
  }
}
final planningProvider = AsyncNotifierProvider<PlanningNotifier, Map<int, int>>(PlanningNotifier.new);

// ── Timer duration notifier ───────────────────────────────────
class TimerDurationNotifier extends AsyncNotifier<int> {
  /// De 1 min à 5 min, par pas de 30 s.
  static const durations = [60, 90, 120, 150, 180, 210, 240, 270, 300];

  @override
  Future<int> build() => ref.read(logServiceProvider).loadTimerDuration();

  Future<void> set(int seconds) async {
    await ref.read(logServiceProvider).saveTimerDuration(seconds);
    state = AsyncData(seconds);
  }
}
final timerDurationProvider = AsyncNotifierProvider<TimerDurationNotifier, int>(TimerDurationNotifier.new);

// ── Timer sound notifier ──────────────────────────────────────
/// id → (libellé, fichier dans assets/sounds/)
/// L'alarme forte est en premier : c'est le son par défaut.
const kTimerSounds = {
  'alarme': ('Carillon', 'sounds/timer_end_loud.wav'),
  'beep': ('Bip', 'sounds/timer_end.wav'),
};

class TimerSoundNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final saved = await ref.read(logServiceProvider).loadTimerSound();
    // Sécurise les valeurs héritées supprimées (ex : ancien « mister_v »).
    return kTimerSounds.containsKey(saved) ? saved : kTimerSounds.keys.first;
  }

  Future<void> cycle() async {
    final ids = kTimerSounds.keys.toList();
    final current = state.value ?? ids.first;
    final next = ids[(ids.indexOf(current) + 1) % ids.length];
    await ref.read(logServiceProvider).saveTimerSound(next);
    state = AsyncData(next);
  }
}
final timerSoundProvider = AsyncNotifierProvider<TimerSoundNotifier, String>(TimerSoundNotifier.new);

// ── Custom sessions notifier ──────────────────────────────────
class CustomSessionsNotifier extends AsyncNotifier<Map<int, List<String>>> {
  @override
  Future<Map<int, List<String>>> build() => ref.read(logServiceProvider).loadCustomSessions();

  Future<void> setSession(int type, List<String> exerciseIds) async {
    final current = Map<int, List<String>>.from(state.value ?? {});
    current[type] = exerciseIds;
    await ref.read(logServiceProvider).saveCustomSessions(current);
    state = AsyncData(current);
    CloudSyncService.pushIfSignedIn();
  }

  Future<void> resetSession(int type, List<String> defaults) async {
    final current = Map<int, List<String>>.from(state.value ?? {});
    current.remove(type);
    await ref.read(logServiceProvider).saveCustomSessions(current);
    state = AsyncData(current);
    CloudSyncService.pushIfSignedIn();
  }
}
final customSessionsProvider = AsyncNotifierProvider<CustomSessionsNotifier, Map<int, List<String>>>(CustomSessionsNotifier.new);

// Helper: get exercise IDs for a session (custom or default)
List<String> getSessionExerciseIds(int type, Map<int, List<String>> custom, List<SessionConfig> configs) {
  if (custom.containsKey(type)) return custom[type]!;
  for (final c in configs) {
    if (c.type == type) return c.defaultExerciseIds;
  }
  return const [];
}
