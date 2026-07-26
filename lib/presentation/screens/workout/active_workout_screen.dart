import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/strava_provider.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  late Timer _timer;
  int _elapsed = 0;
  int _restRemaining = 0;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() => _restRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restRemaining <= 0) {
        t.cancel();
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionProvider);
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/workout'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Column(
        children: [
          // ── Sticky header ─────────────────────────────────────────────
          _WorkoutHeader(
            workoutName: session.workout.name,
            timerText: _timerText,
            completedSets: session.completedSets,
            totalSets: session.totalSets,
            restRemaining: _restRemaining,
            onFinish: _confirmFinish,
            onCancel: _confirmCancel,
          ),

          // ── Exercise list ─────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: session.exercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ExerciseBlock(
                workoutExercise: session.exercises[i],
                exerciseIndex: i,
                onSetComplete: (setIndex) {
                  ref.read(activeSessionProvider.notifier).completeSet(i, setIndex);
                  _startRest(90);
                },
                onWeightChanged: (setIndex, w) =>
                    ref.read(activeSessionProvider.notifier).updateSetWeight(i, setIndex, w),
                onRepsChanged: (setIndex, r) =>
                    ref.read(activeSessionProvider.notifier).updateSetReps(i, setIndex, r),
              ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmFinish() {
    final stravaAuth = ref.read(stravaProvider);
    showDialog(
      context: context,
      builder: (_) => _FinishDialog(
        stravaConnected: stravaAuth != null,
        onFinish: (uploadToStrava) async {
          ref.read(activeSessionProvider.notifier).finishSession();
          final session = ref.read(activeSessionProvider);
          if (session != null) {
            ref.read(sessionHistoryProvider.notifier).addSession(session);
            if (uploadToStrava) {
              final ok = await ref.read(stravaProvider.notifier).uploadSession(session);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Séance uploadée sur Strava ! 🧡' : 'Erreur upload Strava'),
                  backgroundColor: ok ? const Color(0xFFFC4C02) : AppColors.error,
                ));
              }
            }
          }
          ref.read(activeSessionProvider.notifier).cancelSession();
          if (mounted) context.go('/home');
        },
      ),
    );
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Abandonner la séance ?'),
        content: const Text('Aucune progression ne sera enregistrée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(activeSessionProvider.notifier).cancelSession();
              Navigator.pop(context);
              context.go('/workout');
            },
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
  }
}

class _FinishDialog extends StatefulWidget {
  final bool stravaConnected;
  final Future<void> Function(bool uploadToStrava) onFinish;
  const _FinishDialog({required this.stravaConnected, required this.onFinish});

  @override
  State<_FinishDialog> createState() => _FinishDialogState();
}

class _FinishDialogState extends State<_FinishDialog> {
  bool _uploadStrava = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Terminer la séance ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Les séries non complétées seront ignorées.'),
          if (widget.stravaConnected) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _uploadStrava = !_uploadStrava),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _uploadStrava
                      ? const Color(0xFFFC4C02).withValues(alpha: 0.12)
                      : AppColors.bgCardElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _uploadStrava
                        ? const Color(0xFFFC4C02).withValues(alpha: 0.5)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🧡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Uploader sur Strava',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      _uploadStrava
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: _uploadStrava
                          ? const Color(0xFFFC4C02)
                          : AppColors.textMuted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  Navigator.pop(context);
                  await widget.onFinish(_uploadStrava);
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Terminer'),
        ),
      ],
    );
  }
}

class _WorkoutHeader extends StatelessWidget {
  final String workoutName;
  final String timerText;
  final int completedSets;
  final int totalSets;
  final int restRemaining;
  final VoidCallback onFinish;
  final VoidCallback onCancel;

  const _WorkoutHeader({
    required this.workoutName,
    required this.timerText,
    required this.completedSets,
    required this.totalSets,
    required this.restRemaining,
    required this.onFinish,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      color: AppColors.bgCard,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workoutName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(timerText,
                            style: const TextStyle(
                                color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        Text('$completedSets/$totalSets séries',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                    tooltip: 'Abandonner',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onFinish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Terminer', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgCardElevated,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 5,
            ),
          ),
          if (restRemaining > 0) ...[
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_bottom_rounded, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Repos: ${restRemaining}s',
                    style: const TextStyle(
                        color: AppColors.secondary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  final WorkoutExercise workoutExercise;
  final int exerciseIndex;
  final Function(int setIndex) onSetComplete;
  final Function(int setIndex, double weight) onWeightChanged;
  final Function(int setIndex, int reps) onRepsChanged;

  const _ExerciseBlock({
    required this.workoutExercise,
    required this.exerciseIndex,
    required this.onSetComplete,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final exercise = workoutExercise.exercise;
    final theme = Theme.of(context);
    final allCompleted = workoutExercise.sets.every((s) => s.completed);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: allCompleted ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: exercise.primaryMuscle.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(exercise.primaryMuscle.emoji, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name, style: theme.textTheme.titleMedium),
                      Text(exercise.primaryMuscle.label,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (allCompleted)
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
              ],
            ),
          ),

          // Sets header
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                SizedBox(width: 32, child: Text('Série', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                SizedBox(width: 16),
                SizedBox(width: 80, child: Text('Poids (kg)', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                SizedBox(width: 12),
                SizedBox(width: 60, child: Text('Reps', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
                Spacer(),
                Text('', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),

          // Sets
          ...workoutExercise.sets.asMap().entries.map(
                (entry) => _SetRow(
                  setNumber: entry.key + 1,
                  set: entry.value,
                  onComplete: () => onSetComplete(entry.key),
                  onWeightChanged: (w) => onWeightChanged(entry.key, w),
                  onRepsChanged: (r) => onRepsChanged(entry.key, r),
                ),
              ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final WorkoutSet set;
  final VoidCallback onComplete;
  final Function(double) onWeightChanged;
  final Function(int) onRepsChanged;

  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.onComplete,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: set.completed ? AppColors.success.withValues(alpha: 0.08) : AppColors.bgCardElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$setNumber',
              style: TextStyle(
                color: set.completed ? AppColors.success : AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _NumberField(
            value: set.weight,
            onChanged: onWeightChanged,
            enabled: !set.completed,
            width: 80,
          ),
          const SizedBox(width: 12),
          _IntField(
            value: set.reps,
            onChanged: onRepsChanged,
            enabled: !set.completed,
            width: 60,
          ),
          const Spacer(),
          GestureDetector(
            onTap: set.completed ? null : onComplete,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: set.completed ? AppColors.success : AppColors.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: set.completed ? AppColors.success : AppColors.border,
                ),
              ),
              child: Icon(
                set.completed ? Icons.check_rounded : Icons.check_rounded,
                color: set.completed ? Colors.white : AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final double value;
  final Function(double) onChanged;
  final bool enabled;
  final double width;

  const _NumberField({
    required this.value,
    required this.onChanged,
    required this.enabled,
    required this.width,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.value == 0 ? '' : widget.value.toString(),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.width,
        height: 36,
        child: TextField(
          controller: _ctrl,
          enabled: widget.enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgSurface,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            if (parsed != null) widget.onChanged(parsed);
          },
        ),
      );
}

class _IntField extends StatefulWidget {
  final int value;
  final Function(int) onChanged;
  final bool enabled;
  final double width;

  const _IntField({
    required this.value,
    required this.onChanged,
    required this.enabled,
    required this.width,
  });

  @override
  State<_IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<_IntField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.width,
        height: 36,
        child: TextField(
          controller: _ctrl,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgSurface,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null) widget.onChanged(parsed);
          },
        ),
      );
}
