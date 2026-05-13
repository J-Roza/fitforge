import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/user_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // State
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
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 3) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(userProfileProvider.notifier).createProfile(
          name: _nameCtrl.text.trim().isEmpty ? 'Athlète' : _nameCtrl.text.trim(),
          age: int.tryParse(_ageCtrl.text),
          weightKg: double.tryParse(_weightCtrl.text),
          heightCm: double.tryParse(_heightCtrl.text),
          somatotype: _somatotype,
          goal: _goal,
          level: _level,
          equipment: _equipment,
          workoutsPerWeek: _workoutsPerWeek,
        );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (p) => setState(() => _currentPage = p),
            children: [
              _WelcomePage(onNext: _next),
              _GoalPage(
                selected: _goal,
                level: _level,
                onGoalChanged: (g) => setState(() => _goal = g),
                onLevelChanged: (l) => setState(() => _level = l),
                onNext: _next,
              ),
              _ProfilePage(
                nameCtrl: _nameCtrl,
                ageCtrl: _ageCtrl,
                weightCtrl: _weightCtrl,
                heightCtrl: _heightCtrl,
                somatotype: _somatotype,
                onSomatotypeChanged: (s) => setState(() => _somatotype = s),
                onNext: _next,
              ),
              _EquipmentPage(
                equipment: _equipment,
                workoutsPerWeek: _workoutsPerWeek,
                onEquipmentChanged: (e) => setState(() => _equipment = e),
                onWorkoutsChanged: (w) => setState(() => _workoutsPerWeek = w),
                onFinish: _finish,
              ),
            ],
          ),
          // Page indicator
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppColors.accent : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 40),
              ).animate().scale(delay: 200.ms),
              const SizedBox(height: 32),
              Text(
                'FitForge',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [AppColors.accent, AppColors.secondary],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                    ),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
              const SizedBox(height: 12),
              Text(
                'Transforme ton corps.\nSuis tes progrès.\nDépasse tes limites.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ).animate().fadeIn(delay: 500.ms),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Commencer'),
                ),
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
}

class _GoalPage extends StatelessWidget {
  final FitnessGoal selected;
  final FitnessLevel level;
  final Function(FitnessGoal) onGoalChanged;
  final Function(FitnessLevel) onLevelChanged;
  final VoidCallback onNext;

  const _GoalPage({
    required this.selected,
    required this.level,
    required this.onGoalChanged,
    required this.onLevelChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quel est ton objectif ?', style: theme.textTheme.displayMedium)
                .animate()
                .fadeIn()
                .slideY(begin: -0.1),
            const SizedBox(height: 8),
            Text('On va adapter ton programme en conséquence.', style: theme.textTheme.bodyLarge)
                .animate()
                .fadeIn(delay: 100.ms),
            const SizedBox(height: 28),
            ...FitnessGoal.values.map(
              (g) => _GoalCard(
                goal: g,
                selected: selected == g,
                onTap: () => onGoalChanged(g),
              ).animate(delay: Duration(milliseconds: 50 * FitnessGoal.values.indexOf(g))).fadeIn(),
            ),
            const SizedBox(height: 24),
            Text('Ton niveau', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Row(
              children: FitnessLevel.values.map((l) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onLevelChanged(l),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: level == l ? l.color.withOpacity(0.15) : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: level == l ? l.color : AppColors.border),
                      ),
                      child: Center(
                        child: Text(l.label,
                            style: TextStyle(
                                color: level == l ? l.color : AppColors.textMuted,
                                fontWeight: level == l ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onNext, child: const Text('Continuer')),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final FitnessGoal goal;
  final bool selected;
  final VoidCallback onTap;
  const _GoalCard({required this.goal, required this.selected, required this.onTap});

  static const _icons = {
    FitnessGoal.bulking: '🏋️',
    FitnessGoal.cutting: '🔥',
    FitnessGoal.maintenance: '⚖️',
    FitnessGoal.strength: '💪',
    FitnessGoal.endurance: '🏃',
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentGlow : AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Text(_icons[goal] ?? '🏋️', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Text(goal.label,
                  style: TextStyle(
                      color: selected ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15)),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
            ],
          ),
        ),
      );
}

class _ProfilePage extends StatelessWidget {
  final TextEditingController nameCtrl, ageCtrl, weightCtrl, heightCtrl;
  final Somatotype? somatotype;
  final Function(Somatotype?) onSomatotypeChanged;
  final VoidCallback onNext;

  const _ProfilePage({
    required this.nameCtrl,
    required this.ageCtrl,
    required this.weightCtrl,
    required this.heightCtrl,
    required this.somatotype,
    required this.onSomatotypeChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ton profil', style: theme.textTheme.displayMedium).animate().fadeIn(),
            Text('Pour adapter les charges et le programme.', style: theme.textTheme.bodyLarge)
                .animate()
                .fadeIn(delay: 100.ms),
            const SizedBox(height: 28),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Prénom *')),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: ageCtrl, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Âge')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Poids (kg)')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(controller: heightCtrl, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Taille (cm)')),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Morphotype (optionnel)', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Ton type corporel naturel — aide à personnaliser le volume d\'entraînement.',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ...[null, ...Somatotype.values].map(
              (s) => GestureDetector(
                onTap: () => onSomatotypeChanged(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: somatotype == s ? AppColors.accentGlow : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: somatotype == s ? AppColors.accent : AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s?.label ?? 'Je ne sais pas',
                          style: TextStyle(
                              color: somatotype == s ? AppColors.accent : AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      if (s != null) ...[
                        const SizedBox(height: 4),
                        Text(s.description,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onNext, child: const Text('Continuer')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentPage extends StatelessWidget {
  final AvailableEquipment equipment;
  final int workoutsPerWeek;
  final Function(AvailableEquipment) onEquipmentChanged;
  final Function(int) onWorkoutsChanged;
  final VoidCallback onFinish;

  const _EquipmentPage({
    required this.equipment,
    required this.workoutsPerWeek,
    required this.onEquipmentChanged,
    required this.onWorkoutsChanged,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      (AvailableEquipment.gym, '🏋️', 'Salle complète', 'Accès à tous les équipements, machines, câbles...'),
      (AvailableEquipment.home, '🏠', 'À la maison', 'Haltères, barre, banc — équipement basique'),
      (AvailableEquipment.bodyweightOnly, '💪', 'Poids du corps', 'Aucun équipement nécessaire'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ton équipement', style: theme.textTheme.displayMedium).animate().fadeIn(),
            Text('On adaptera les exercices à ce que tu as.', style: theme.textTheme.bodyLarge)
                .animate()
                .fadeIn(delay: 100.ms),
            const SizedBox(height: 28),
            ...options.map(
              (opt) => GestureDetector(
                onTap: () => onEquipmentChanged(opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: equipment == opt.$1 ? AppColors.accentGlow : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: equipment == opt.$1 ? AppColors.accent : AppColors.border,
                        width: equipment == opt.$1 ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Text(opt.$2, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt.$3,
                                style: TextStyle(
                                    color: equipment == opt.$1 ? AppColors.accent : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600, fontSize: 15)),
                            Text(opt.$4,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (equipment == opt.$1)
                        const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Séances par semaine: $workoutsPerWeek', style: theme.textTheme.titleMedium),
            Slider(
              value: workoutsPerWeek.toDouble(),
              min: 2,
              max: 6,
              divisions: 4,
              activeColor: AppColors.accent,
              label: '$workoutsPerWeek',
              onChanged: (v) => onWorkoutsChanged(v.toInt()),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onFinish,
                child: const Text("C'est parti !"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
