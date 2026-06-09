import 'log_models.dart';

/// Séances historiques à injecter une seule fois au démarrage.
/// Clé SharedPreferences : 'ff_log_seeded_v1'
final List<LogSession> kSeedSessions = [

  // ── 2026-05-19 : S2 PULL ──────────────────────────────────
  LogSession(
    id: 'seed_20260519_s2',
    date: DateTime(2026, 5, 19),
    sessionType: 2,
    feeling: 'ok',
    exercises: [
      LogExercise(exerciseId: 'barbell_row', sets: [
        LogSet(isBodyweight: false, weight: 38, reps: 10),
        LogSet(isBodyweight: false, weight: 38, reps: 10),
        LogSet(isBodyweight: false, weight: 38, reps: 10),
        LogSet(isBodyweight: false, weight: 38, reps: 10),
      ]),
      LogExercise(exerciseId: 'dumbbell_row', notes: 'À augmenter', sets: [
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 12, reps: 10),
      ]),
      LogExercise(exerciseId: 'lat_pulldown', notes: 'Dur à gauche', sets: [
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
      ]),
      LogExercise(exerciseId: 'skull_crusher', sets: [
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 12, reps: 10),
      ]),
    ],
  ),

  // ── 2026-05-27 : S1 PUSH ──────────────────────────────────
  LogSession(
    id: 'seed_20260527_s1',
    date: DateTime(2026, 5, 27),
    sessionType: 1,
    exercises: [
      LogExercise(exerciseId: 'bench_press', sets: [
        LogSet(isBodyweight: false, weight: 52, reps: 10),
        LogSet(isBodyweight: false, weight: 52, reps: 10),
        LogSet(isBodyweight: false, weight: 52, reps: 10),
        LogSet(isBodyweight: false, weight: 52, reps: 10),
      ]),
      LogExercise(exerciseId: 'ohp', sets: [
        LogSet(isBodyweight: false, weight: 9, reps: 10),
        LogSet(isBodyweight: false, weight: 9, reps: 10),
        LogSet(isBodyweight: false, weight: 9, reps: 10),
        LogSet(isBodyweight: false, weight: 9, reps: 10),
      ]),
    ],
  ),

  // ── 2026-05-30 : S1 PUSH ──────────────────────────────────
  LogSession(
    id: 'seed_20260530_s1',
    date: DateTime(2026, 5, 30),
    sessionType: 1,
    exercises: [
      LogExercise(exerciseId: 'bench_press', sets: [
        LogSet(isBodyweight: false, weight: 54, reps: 10),
        LogSet(isBodyweight: false, weight: 54, reps: 10),
        LogSet(isBodyweight: false, weight: 54, reps: 10),
        LogSet(isBodyweight: false, weight: 54, reps: 10),
      ]),
      LogExercise(exerciseId: 'incline_bench_press', sets: [
        LogSet(isBodyweight: false, weight: 40, reps: 10),
        LogSet(isBodyweight: false, weight: 40, reps: 10),
        LogSet(isBodyweight: false, weight: 40, reps: 10),
        LogSet(isBodyweight: false, weight: 40, reps: 10),
      ]),
      LogExercise(exerciseId: 'dumbbell_flyes', notes: 'Écarté incliné — à augmenter', sets: [
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
      ]),
      LogExercise(exerciseId: 'barbell_curl', notes: 'Curl incliné', sets: [
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
      ]),
      LogExercise(exerciseId: 'preacher_curl', notes: 'Curl pupitre', sets: [
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
      ]),
    ],
  ),

  // ── 2026-06-01 : S2 PULL + TRI ────────────────────────────
  LogSession(
    id: 'seed_20260601_s2',
    date: DateTime(2026, 6, 1),
    sessionType: 2,
    feeling: 'great',
    exercises: [
      LogExercise(exerciseId: 'barbell_row', notes: 'Rowing buste penché', sets: [
        LogSet(isBodyweight: false, weight: 38, reps: 10),
        LogSet(isBodyweight: false, weight: 38, reps: 10),
        LogSet(isBodyweight: false, weight: 38, reps: 10),
        LogSet(isBodyweight: false, weight: 38, reps: 10),
      ]),
      LogExercise(exerciseId: 'dumbbell_row', notes: 'Rowing 1 bras', sets: [
        LogSet(isBodyweight: false, weight: 18, reps: 10),
        LogSet(isBodyweight: false, weight: 18, reps: 10),
        LogSet(isBodyweight: false, weight: 18, reps: 10),
      ]),
      LogExercise(exerciseId: 'overhead_tricep_extension', sets: [
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
      ]),
      LogExercise(exerciseId: 'skull_crusher', notes: 'Barre au front', sets: [
        LogSet(isBodyweight: false, weight: 20, reps: 10),
        LogSet(isBodyweight: false, weight: 20, reps: 10),
        LogSet(isBodyweight: false, weight: 20, reps: 10),
        LogSet(isBodyweight: false, weight: 20, reps: 10),
      ]),
      LogExercise(exerciseId: 'dips_chest', sets: [
        LogSet(isBodyweight: false, weight: 20, reps: 10),
        LogSet(isBodyweight: false, weight: 20, reps: 10),
        LogSet(isBodyweight: false, weight: 20, reps: 10),
        LogSet(isBodyweight: false, weight: 20, reps: 10),
      ]),
    ],
  ),

  // ── 2026-06-05 : S4 ÉPAULES+ ──────────────────────────────
  LogSession(
    id: 'seed_20260605_s4',
    date: DateTime(2026, 6, 5),
    sessionType: 4,
    feeling: 'great',
    exercises: [
      LogExercise(exerciseId: 'bench_press', sets: [
        LogSet(isBodyweight: false, weight: 54, reps: 10),
        LogSet(isBodyweight: false, weight: 54, reps: 10),
        LogSet(isBodyweight: false, weight: 54, reps: 10),
        LogSet(isBodyweight: false, weight: 54, reps: 10),
      ]),
      LogExercise(exerciseId: 'ohp', notes: 'Développé militaire', sets: [
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 12, reps: 10),
      ]),
      LogExercise(exerciseId: 'lateral_raise', sets: [
        LogSet(isBodyweight: false, weight: 9, reps: 10),
        LogSet(isBodyweight: false, weight: 9, reps: 10),
        LogSet(isBodyweight: false, weight: 9, reps: 10),
        LogSet(isBodyweight: false, weight: 9, reps: 10),
      ]),
      LogExercise(exerciseId: 'dumbbell_flyes', notes: 'Oiseau / Fly haltère', sets: [
        LogSet(isBodyweight: false, weight: 9, reps: 10),
        LogSet(isBodyweight: false, weight: 9, reps: 10),
        LogSet(isBodyweight: false, weight: 9, reps: 10),
        LogSet(isBodyweight: false, weight: 9, reps: 10),
      ]),
      LogExercise(exerciseId: 'hammer_curl', sets: [
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
        LogSet(isBodyweight: false, weight: 10, reps: 10),
      ]),
      LogExercise(exerciseId: 'barbell_row', notes: 'Rowing', sets: [
        LogSet(isBodyweight: false, weight: 38, reps: 10),
        LogSet(isBodyweight: false, weight: 38, reps: 10),
        LogSet(isBodyweight: false, weight: 38, reps: 10),
      ]),
    ],
  ),

  // ── 2026-06-06 : S3 LEGS ──────────────────────────────────
  LogSession(
    id: 'seed_20260606_s3',
    date: DateTime(2026, 6, 6),
    sessionType: 3,
    exercises: [
      LogExercise(exerciseId: 'deadlift', sets: [
        LogSet(isBodyweight: false, weight: 40, reps: 10),
        LogSet(isBodyweight: false, weight: 40, reps: 10),
        LogSet(isBodyweight: false, weight: 40, reps: 10),
        LogSet(isBodyweight: false, weight: 40, reps: 10),
      ]),
      LogExercise(exerciseId: 'squat', sets: [
        LogSet(isBodyweight: false, weight: 30, reps: 10),
        LogSet(isBodyweight: false, weight: 30, reps: 10),
      ]),
      LogExercise(exerciseId: 'lunges', notes: 'Fentes haltères', sets: [
        LogSet(isBodyweight: false, weight: 8, reps: 10),
        LogSet(isBodyweight: false, weight: 8, reps: 10),
        LogSet(isBodyweight: false, weight: 8, reps: 10),
        LogSet(isBodyweight: false, weight: 8, reps: 10),
      ]),
    ],
  ),

  // ── 2026-06-07 : S1 PUSH ──────────────────────────────────
  LogSession(
    id: 'seed_20260607_s1',
    date: DateTime(2026, 6, 7),
    sessionType: 1,
    feeling: 'great',
    exercises: [
      LogExercise(exerciseId: 'bench_press', sets: [
        LogSet(isBodyweight: false, weight: 54, reps: 10),
        LogSet(isBodyweight: false, weight: 56, reps: 10),
        LogSet(isBodyweight: false, weight: 56, reps: 8),
        LogSet(isBodyweight: false, weight: 56, reps: 8),
      ]),
      LogExercise(exerciseId: 'incline_bench_press', sets: [
        LogSet(isBodyweight: false, weight: 40, reps: 10),
        LogSet(isBodyweight: false, weight: 40, reps: 10),
        LogSet(isBodyweight: false, weight: 42, reps: 10),
      ]),
      LogExercise(exerciseId: 'lateral_raise', sets: [
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 12, reps: 10),
        LogSet(isBodyweight: false, weight: 14, reps: 10),
      ]),
      LogExercise(exerciseId: 'overhead_tricep_extension', sets: [
        LogSet(isBodyweight: false, weight: 8, reps: 10),
        LogSet(isBodyweight: false, weight: 8, reps: 10),
        LogSet(isBodyweight: false, weight: 8, reps: 10),
        LogSet(isBodyweight: false, weight: 8, reps: 10),
      ]),
      LogExercise(exerciseId: 'skull_crusher', notes: 'Barre au front', sets: [
        LogSet(isBodyweight: false, weight: 17, reps: 10),
        LogSet(isBodyweight: false, weight: 17, reps: 10),
        LogSet(isBodyweight: false, weight: 17, reps: 10),
      ]),
      LogExercise(exerciseId: 'dips_chest', sets: [
        LogSet(isBodyweight: false, weight: 20, reps: 10),
        LogSet(isBodyweight: false, weight: 20, reps: 10),
        LogSet(isBodyweight: false, weight: 20, reps: 10),
      ]),
    ],
  ),
];
