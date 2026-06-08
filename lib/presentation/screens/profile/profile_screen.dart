import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/workout_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final history = ref.watch(sessionHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfile(context, ref, user),
          ),
        ],
      ),
      body: user == null
          ? _NoProfile(onCreate: () => _showEditProfile(context, ref, null))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // ── Avatar ────────────────────────────────────────
                        _Avatar(name: user.name).animate().scale(delay: 100.ms),
                        const SizedBox(height: 12),
                        Text(user.name, style: theme.textTheme.headlineLarge)
                            .animate()
                            .fadeIn(delay: 150.ms),
                        const SizedBox(height: 4),
                        Text(
                          '${user.level.label} · ${user.goal.label}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 24),

                        // ── Body stats ────────────────────────────────────
                        _BodyStatsRow(user: user)
                            .animate()
                            .fadeIn(delay: 250.ms),
                        const SizedBox(height: 24),

                        // ── Training stats ────────────────────────────────
                        _TrainingStats(history: history)
                            .animate()
                            .fadeIn(delay: 300.ms),
                        const SizedBox(height: 28),

                        // ── Somatotype card ───────────────────────────────
                        if (user.somatotype != null)
                          _SomatotypeCard(somatotype: user.somatotype!)
                              .animate()
                              .fadeIn(delay: 350.ms),
                        const SizedBox(height: 28),

                        // ── Settings ──────────────────────────────────────
                        _SettingsSection(user: user, ref: ref)
                            .animate()
                            .fadeIn(delay: 400.ms),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, UserProfile? current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(current: current),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) => Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.accentDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
          ),
        ),
      );
}

class _BodyStatsRow extends StatelessWidget {
  final UserProfile user;
  const _BodyStatsRow({required this.user});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BodyStat(
              value: user.weightKg != null ? '${user.weightKg!.toInt()}' : '—',
              unit: 'kg',
              label: 'Poids',
            ),
            _Divider(),
            _BodyStat(
              value: user.heightCm != null ? '${user.heightCm!.toInt()}' : '—',
              unit: 'cm',
              label: 'Taille',
            ),
            _Divider(),
            _BodyStat(
              value: user.bmi != null ? user.bmi!.toStringAsFixed(1) : '—',
              unit: '',
              label: 'IMC',
            ),
            _Divider(),
            _BodyStat(
              value: user.age != null ? '${user.age}' : '—',
              unit: 'ans',
              label: 'Âge',
            ),
          ],
        ),
      );
}

class _BodyStat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  const _BodyStat({required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
              children: [
                TextSpan(
                  text: unit,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: AppColors.border,
      );
}

class _TrainingStats extends StatelessWidget {
  final List history;
  const _TrainingStats({required this.history});

  @override
  Widget build(BuildContext context) {
    final totalSessions = history.length;
    final totalMinutes = history.fold(0, (sum, s) => sum + (s.duration as Duration).inMinutes);
    final totalVolume = history.fold(0, (sum, s) => sum + (s.totalVolume as int));

    return Row(
      children: [
        _TrainingStat(value: '$totalSessions', label: 'Séances', icon: Icons.fitness_center_rounded, color: AppColors.accent),
        const SizedBox(width: 12),
        _TrainingStat(value: '${totalMinutes}h', label: 'Temps total', icon: Icons.timer_outlined, color: AppColors.secondary),
        const SizedBox(width: 12),
        _TrainingStat(value: '${(totalVolume / 1000).toStringAsFixed(0)}t', label: 'Volume total', icon: Icons.show_chart_rounded, color: AppColors.chest),
      ],
    );
  }
}

class _TrainingStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _TrainingStat({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _SomatotypeCard extends StatelessWidget {
  final Somatotype somatotype;
  const _SomatotypeCard({required this.somatotype});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentDark.withOpacity(0.5), AppColors.bg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Text('Morphotype: ${somatotype.label}',
                    style: const TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              somatotype.description,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      );
}

class _SettingsSection extends StatelessWidget {
  final UserProfile user;
  final WidgetRef ref;
  const _SettingsSection({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            _SettingsTile(
              icon: Icons.flag_outlined,
              label: 'Objectif',
              value: user.goal.label,
              onTap: () {},
            ),
            _Separator(),
            _SettingsTile(
              icon: Icons.calendar_month_outlined,
              label: 'Séances par semaine',
              value: '${user.workoutsPerWeek}x',
              onTap: () {},
            ),
            _Separator(),
            _SettingsTile(
              icon: Icons.straighten_outlined,
              label: 'Unité de mesure',
              value: user.useMetric ? 'Métrique (kg/cm)' : 'Impérial (lbs/in)',
              onTap: () {},
            ),
            _Separator(),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              label: 'Réinitialiser le profil',
              value: '',
              iconColor: AppColors.error,
              labelColor: AppColors.error,
              onTap: () {
                ref.read(userProfileProvider.notifier).update(user);
              },
            ),
          ],
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
        title: Text(label,
            style: TextStyle(
                color: labelColor ?? AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        trailing: value.isNotEmpty
            ? Text(value, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))
            : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
        onTap: onTap,
      );
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 56);
}

class _NoProfile extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoProfile({required this.onCreate});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👤', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Crée ton profil', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Pour obtenir un programme\npersonnalisé à ta morphologie',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onCreate,
              child: const Text('Commencer'),
            ),
          ],
        ),
      );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile? current;
  const _EditProfileSheet({this.current});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  FitnessGoal _goal = FitnessGoal.bulking;
  FitnessLevel _level = FitnessLevel.beginner;
  AvailableEquipment _equipment = AvailableEquipment.gym;
  Somatotype? _somatotype;
  int _workoutsPerWeek = 4;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    if (c != null) {
      _nameCtrl.text = c.name;
      if (c.age != null) _ageCtrl.text = c.age.toString();
      if (c.weightKg != null) _weightCtrl.text = c.weightKg.toString();
      if (c.heightCm != null) _heightCtrl.text = c.heightCm.toString();
      _goal = c.goal;
      _level = c.level;
      _equipment = c.equipment;
      _somatotype = c.somatotype;
      _workoutsPerWeek = c.workoutsPerWeek;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    widget.current == null ? 'Créer ton profil' : 'Modifier le profil',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ton prénom',
                      labelText: 'Prénom',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Ex: 25', labelText: 'Âge'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(hintText: 'Ex: 75', labelText: 'Poids (kg)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _heightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Ex: 178', labelText: 'Taille (cm)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Objectif'),
                  const SizedBox(height: 10),
                  _ChipSelector<FitnessGoal>(
                    values: FitnessGoal.values,
                    selected: _goal,
                    labelOf: (v) => v.label,
                    onSelected: (v) => setState(() => _goal = v),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Niveau'),
                  const SizedBox(height: 10),
                  _ChipSelector<FitnessLevel>(
                    values: FitnessLevel.values,
                    selected: _level,
                    labelOf: (v) => v.label,
                    onSelected: (v) => setState(() => _level = v),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Équipement disponible'),
                  const SizedBox(height: 10),
                  _ChipSelector<AvailableEquipment>(
                    values: AvailableEquipment.values,
                    selected: _equipment,
                    labelOf: (v) => v == AvailableEquipment.gym
                        ? 'Salle complète'
                        : v == AvailableEquipment.home
                            ? 'Maison'
                            : 'Poids du corps',
                    onSelected: (v) => setState(() => _equipment = v),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Morphotype (optionnel)'),
                  const SizedBox(height: 10),
                  _ChipSelector<Somatotype?>(
                    values: [null, ...Somatotype.values],
                    selected: _somatotype,
                    labelOf: (v) => v?.label ?? 'Inconnu',
                    onSelected: (v) => setState(() => _somatotype = v),
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Séances par semaine: $_workoutsPerWeek'),
                  Slider(
                    value: _workoutsPerWeek.toDouble(),
                    min: 2,
                    max: 6,
                    divisions: 4,
                    activeColor: AppColors.accent,
                    onChanged: (v) => setState(() => _workoutsPerWeek = v.toInt()),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Sauvegarder'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    ref.read(userProfileProvider.notifier).createProfile(
          name: _nameCtrl.text.trim(),
          age: int.tryParse(_ageCtrl.text),
          weightKg: double.tryParse(_weightCtrl.text),
          heightCm: double.tryParse(_heightCtrl.text),
          somatotype: _somatotype,
          goal: _goal,
          level: _level,
          equipment: _equipment,
          workoutsPerWeek: _workoutsPerWeek,
        );
    Navigator.pop(context);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _ChipSelector<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final Function(T) onSelected;

  const _ChipSelector({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: values.map((v) {
          final isSelected = v == selected;
          return GestureDetector(
            onTap: () => onSelected(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentGlow : AppColors.bgCardElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                labelOf(v),
                style: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      );
}
