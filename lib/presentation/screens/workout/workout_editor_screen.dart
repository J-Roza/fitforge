import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/exercise_provider.dart';

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  final String workoutId;
  const WorkoutEditorScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late TextEditingController _nameCtrl;
  late List<WorkoutExercise> _exercises;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _init(Workout workout) {
    if (_initialized) return;
    _nameCtrl = TextEditingController(text: workout.name);
    _exercises = List.from(workout.exercises);
    _initialized = true;
  }

  void _save() {
    final templates = ref.read(workoutTemplatesProvider);
    final original = templates.firstWhere((w) => w.id == widget.workoutId);
    ref.read(workoutTemplatesProvider.notifier).updateWorkout(
          Workout(
            id: widget.workoutId,
            name: _nameCtrl.text.trim().isEmpty ? original.name : _nameCtrl.text.trim(),
            description: original.description,
            exercises: _exercises,
            estimatedDuration: Duration(minutes: (_exercises.fold(0, (s, e) => s + e.sets.length) * 3).clamp(10, 120)),
            isFavorite: original.isFavorite,
          ),
        );
    context.pop();
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  void _addSets(int exerciseIndex) {
    setState(() {
      final ex = _exercises[exerciseIndex];
      final lastSet = ex.sets.isNotEmpty ? ex.sets.last : const WorkoutSet(weight: 0, reps: 10);
      _exercises[exerciseIndex] = ex.copyWith(
        sets: [...ex.sets, WorkoutSet(weight: lastSet.weight, reps: lastSet.reps)],
      );
    });
  }

  void _removeSets(int exerciseIndex) {
    setState(() {
      final ex = _exercises[exerciseIndex];
      if (ex.sets.length <= 1) return;
      _exercises[exerciseIndex] = ex.copyWith(sets: ex.sets.sublist(0, ex.sets.length - 1));
    });
  }

  void _updateWeight(int exIdx, int setIdx, double w) {
    setState(() {
      final sets = List<WorkoutSet>.from(_exercises[exIdx].sets);
      sets[setIdx] = sets[setIdx].copyWith(weight: w);
      _exercises[exIdx] = _exercises[exIdx].copyWith(sets: sets);
    });
  }

  void _updateReps(int exIdx, int setIdx, int r) {
    setState(() {
      final sets = List<WorkoutSet>.from(_exercises[exIdx].sets);
      sets[setIdx] = sets[setIdx].copyWith(reps: r);
      _exercises[exIdx] = _exercises[exIdx].copyWith(sets: sets);
    });
  }

  Future<void> _showExercisePicker() async {
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ExercisePickerSheet(
        alreadyAdded: _exercises.map((e) => e.exercise.id).toSet(),
      ),
    );
    if (picked != null) {
      setState(() {
        _exercises.add(WorkoutExercise(
          exercise: picked,
          sets: List.generate(3, (_) => const WorkoutSet(weight: 0, reps: 10)),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(workoutTemplatesProvider);
    final workoutOpt = templates.where((w) => w.id == widget.workoutId).toList();
    if (workoutOpt.isEmpty) {
      return const Scaffold(body: Center(child: Text('Séance introuvable')));
    }
    _init(workoutOpt.first);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Éditeur de séance'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Enregistrer',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Name field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: TextField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Nom de la séance',
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          // Exercise list
          Expanded(
            child: _exercises.isEmpty
                ? _EmptyExercises(onAdd: _showExercisePicker)
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx--;
                        final item = _exercises.removeAt(oldIdx);
                        _exercises.insert(newIdx, item);
                      });
                    },
                    itemCount: _exercises.length,
                    itemBuilder: (ctx, i) => _ExerciseEditorCard(
                      key: ValueKey(_exercises[i].exercise.id + i.toString()),
                      workoutExercise: _exercises[i],
                      index: i,
                      onRemove: () => _removeExercise(i),
                      onAddSet: () => _addSets(i),
                      onRemoveSet: () => _removeSets(i),
                      onWeightChanged: (si, w) => _updateWeight(i, si, w),
                      onRepsChanged: (si, r) => _updateReps(i, si, r),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _exercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showExercisePicker,
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}

// ── Exercise editor card ────────────────────────────────────────────────────

class _ExerciseEditorCard extends StatelessWidget {
  final WorkoutExercise workoutExercise;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onAddSet;
  final VoidCallback onRemoveSet;
  final Function(int setIdx, double weight) onWeightChanged;
  final Function(int setIdx, int reps) onRepsChanged;

  const _ExerciseEditorCard({
    super.key,
    required this.workoutExercise,
    required this.index,
    required this.onRemove,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ex = workoutExercise.exercise;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: ex.primaryMuscle.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(ex.primaryMuscle.emoji, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(ex.primaryMuscle.label,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                // Set count controls
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.textMuted, size: 20),
                  onPressed: onRemoveSet,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                Text('${workoutExercise.sets.length} séries',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.accent, size: 20),
                  onPressed: onAddSet,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: onRemove,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                const Icon(Icons.drag_handle_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
          // Sets header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: const [
                SizedBox(width: 28),
                Expanded(child: Center(child: Text('Poids (kg)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)))),
                SizedBox(width: 8),
                Expanded(child: Center(child: Text('Reps', style: TextStyle(color: AppColors.textMuted, fontSize: 11)))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Sets rows
          ...workoutExercise.sets.asMap().entries.map((e) => _SetEditorRow(
                setNumber: e.key + 1,
                set: e.value,
                onWeightChanged: (w) => onWeightChanged(e.key, w),
                onRepsChanged: (r) => onRepsChanged(e.key, r),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SetEditorRow extends StatelessWidget {
  final int setNumber;
  final WorkoutSet set;
  final Function(double) onWeightChanged;
  final Function(int) onRepsChanged;

  const _SetEditorRow({
    required this.setNumber,
    required this.set,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: AppColors.accentGlow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text('$setNumber',
                    style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumberInput(
                initial: set.weight == 0 ? '' : set.weight.toStringAsFixed(set.weight % 1 == 0 ? 0 : 1),
                hint: '0',
                onChanged: (v) => onWeightChanged(double.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumberInput(
                initial: set.reps == 0 ? '' : '${set.reps}',
                hint: '10',
                onChanged: (v) => onRepsChanged(int.tryParse(v) ?? 0),
              ),
            ),
          ],
        ),
      );
}

class _NumberInput extends StatelessWidget {
  final String initial;
  final String hint;
  final Function(String) onChanged;

  const _NumberInput({required this.initial, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: initial,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.bgCardElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
      );
}

// ── Exercise picker ────────────────────────────────────────────────────────

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final Set<String> alreadyAdded;
  const _ExercisePickerSheet({required this.alreadyAdded});

  @override
  ConsumerState<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  String _search = '';
  MuscleGroup? _muscleFilter;

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exercisesProvider);
    final filtered = allExercises.where((e) {
      final matchSearch = _search.isEmpty ||
          e.name.toLowerCase().contains(_search.toLowerCase());
      final matchMuscle = _muscleFilter == null || e.primaryMuscle == _muscleFilter;
      return matchSearch && matchMuscle;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Ajouter un exercice',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                filled: true,
                fillColor: AppColors.bgCardElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),
          // Muscle filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'Tous',
                  selected: _muscleFilter == null,
                  onTap: () => setState(() => _muscleFilter = null),
                ),
                const SizedBox(width: 6),
                ...MuscleGroup.values.map((m) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _FilterChip(
                        label: m.label,
                        selected: _muscleFilter == m,
                        onTap: () => setState(() => _muscleFilter = _muscleFilter == m ? null : m),
                        color: m.color,
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Exercise list
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final ex = filtered[i];
                final alreadyIn = widget.alreadyAdded.contains(ex.id);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: ex.primaryMuscle.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(ex.primaryMuscle.emoji, style: const TextStyle(fontSize: 18))),
                  ),
                  title: Text(ex.name,
                      style: TextStyle(
                          color: alreadyIn ? AppColors.textMuted : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(ex.primaryMuscle.label,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  trailing: alreadyIn
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20)
                      : const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent, size: 22),
                  onTap: alreadyIn ? null : () => Navigator.of(context).pop(ex),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? (color ?? AppColors.accent).withOpacity(0.2) : AppColors.bgCardElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? (color ?? AppColors.accent) : AppColors.border,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? (color ?? AppColors.accent) : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ),
      );
}

class _EmptyExercises extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyExercises({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💪', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            const Text('Aucun exercice',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Ajoute des exercices pour construire ta séance',
                style: TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter un exercice'),
            ),
          ],
        ),
      );
}
