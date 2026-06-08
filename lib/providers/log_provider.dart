import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/log_models.dart';
import '../services/log_service.dart';

// ── Sessions config ──────────────────────────────────────────
final sessionsConfigProvider = Provider<List<SessionConfig>>((ref) => [
  const SessionConfig(
    type: 1, name: 'PUSH', subtitle: 'Pecs · Épaules · Triceps', color: Color(0xFFE8484F),
    defaultExerciseIds: ['bench_press', 'incline_bench_press', 'lateral_raise', 'overhead_tricep_extension', 'skull_crusher', 'dips_chest'],
  ),
  const SessionConfig(
    type: 2, name: 'PULL + BICEPS', subtitle: 'Dos · Biceps', color: Color(0xFF4F9EE8),
    defaultExerciseIds: ['barbell_row', 'dumbbell_row', 'preacher_curl', 'barbell_curl', 'hammer_curl'],
  ),
  const SessionConfig(
    type: 3, name: 'LEGS', subtitle: 'Jambes · Ischios · Fessiers', color: Color(0xFF30D158),
    defaultExerciseIds: ['deadlift', 'squat', 'lunges', 'leg_curl'],
  ),
  const SessionConfig(
    type: 4, name: 'ÉPAULES +', subtitle: 'Épaules · Biceps · Dos', color: Color(0xFFFF9F0A),
    defaultExerciseIds: ['bench_press', 'ohp', 'lateral_raise', 'face_pull', 'hammer_curl'],
  ),
]);

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
  }

  Future<void> removeSession(String id) async {
    final current = state.value ?? [];
    final updated = current.where((s) => s.id != id).toList();
    await ref.read(logServiceProvider).saveHistory(updated);
    state = AsyncData(updated);
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

// ── Planning notifier ─────────────────────────────────────────
class PlanningNotifier extends AsyncNotifier<Map<int, int>> {
  @override
  Future<Map<int, int>> build() => ref.read(logServiceProvider).loadPlanning();

  Future<void> setDay(int dayOfWeek, int? sessionType) async {
    final current = Map<int, int>.from(state.value ?? {});
    if (sessionType == null) current.remove(dayOfWeek); else current[dayOfWeek] = sessionType;
    await ref.read(logServiceProvider).savePlanning(current);
    state = AsyncData(current);
  }
}
final planningProvider = AsyncNotifierProvider<PlanningNotifier, Map<int, int>>(PlanningNotifier.new);

// ── Timer duration notifier ───────────────────────────────────
class TimerDurationNotifier extends AsyncNotifier<int> {
  static const durations = [60, 90, 120, 180];

  @override
  Future<int> build() => ref.read(logServiceProvider).loadTimerDuration();

  Future<void> cycle() async {
    final current = state.value ?? 90;
    final idx = durations.indexOf(current);
    final next = durations[(idx + 1) % durations.length];
    await ref.read(logServiceProvider).saveTimerDuration(next);
    state = AsyncData(next);
  }
}
final timerDurationProvider = AsyncNotifierProvider<TimerDurationNotifier, int>(TimerDurationNotifier.new);

// ── Custom sessions notifier ──────────────────────────────────
class CustomSessionsNotifier extends AsyncNotifier<Map<int, List<String>>> {
  @override
  Future<Map<int, List<String>>> build() => ref.read(logServiceProvider).loadCustomSessions();

  Future<void> setSession(int type, List<String> exerciseIds) async {
    final current = Map<int, List<String>>.from(state.value ?? {});
    current[type] = exerciseIds;
    await ref.read(logServiceProvider).saveCustomSessions(current);
    state = AsyncData(current);
  }

  Future<void> resetSession(int type, List<String> defaults) async {
    final current = Map<int, List<String>>.from(state.value ?? {});
    current.remove(type);
    await ref.read(logServiceProvider).saveCustomSessions(current);
    state = AsyncData(current);
  }
}
final customSessionsProvider = AsyncNotifierProvider<CustomSessionsNotifier, Map<int, List<String>>>(CustomSessionsNotifier.new);

// Helper: get exercise IDs for a session (custom or default)
List<String> getSessionExerciseIds(int type, Map<int, List<String>> custom, List<SessionConfig> configs) {
  if (custom.containsKey(type)) return custom[type]!;
  return configs.firstWhere((c) => c.type == type).defaultExerciseIds;
}
