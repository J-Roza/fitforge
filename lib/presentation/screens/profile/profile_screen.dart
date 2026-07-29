import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_profile.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/log_provider.dart';
import '../../../services/backup_service.dart';
import '../../../services/cloud_sync_service.dart';
import '../../widgets/rest_duration_picker.dart';

/// État de connexion Firebase (null = déconnecté).
final authStateProvider =
    StreamProvider<User?>((ref) => CloudSyncService.authState());

void _invalidateDataProviders(WidgetRef ref) {
  ref.invalidate(logHistoryProvider);
  ref.invalidate(planningProvider);
  ref.invalidate(customSessionsProvider);
  ref.invalidate(sessionsConfigProvider);
  ref.invalidate(lastWeightsProvider);
  ref.invalidate(lastRepsProvider);
  ref.invalidate(timerDurationProvider);
  ref.invalidate(timerSoundProvider);
  ref.invalidate(userProfileProvider);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
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
                        const _TrainingStats()
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
                        const SizedBox(height: 16),

                        // ── Synchro cloud ─────────────────────────────────
                        const _CloudSyncSection()
                            .animate()
                            .fadeIn(delay: 430.ms),
                        const SizedBox(height: 16),

                        // ── Sauvegarde fichier ────────────────────────────
                        const _BackupSection()
                            .animate()
                            .fadeIn(delay: 460.ms),
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
              color: AppColors.accent.withValues(alpha: 0.4),
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

class _TrainingStats extends ConsumerWidget {
  const _TrainingStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(logHistoryProvider).value ?? [];
    final now = DateTime.now();
    final totalSessions = history.length;
    final totalVolume = history.fold<double>(0, (sum, s) => sum + s.totalVolume);
    final weekSessions = history.where((s) => now.difference(s.date).inDays < 7).length;
    final volStr = totalVolume >= 1000
        ? '${(totalVolume / 1000).toStringAsFixed(1)}t'
        : '${totalVolume.toStringAsFixed(0)}kg';

    return Row(
      children: [
        _TrainingStat(value: '$totalSessions', label: 'Séances', icon: Icons.fitness_center_rounded, color: AppColors.accent),
        const SizedBox(width: 12),
        _TrainingStat(value: '$weekSessions', label: 'Cette semaine', icon: Icons.calendar_today_rounded, color: AppColors.secondary),
        const SizedBox(width: 12),
        _TrainingStat(value: volStr, label: 'Volume total', icon: Icons.show_chart_rounded, color: AppColors.chest),
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
            colors: [AppColors.accentDark.withValues(alpha: 0.5), AppColors.bg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
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
  Widget build(BuildContext context) {
    final soundId = ref.watch(timerSoundProvider).value ?? 'beep';
    // Libellé court pour la tile (avant le « — » éventuel)
    final soundLabel =
        (kTimerSounds[soundId]?.$1 ?? 'Bip').split(' —').first;
    final restDuration = ref.watch(timerDurationProvider).value ?? 90;

    return Container(
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
              icon: Icons.timer_outlined,
              label: 'Temps de repos',
              value: formatRestDuration(restDuration),
              onTap: () => showRestDurationPicker(context, ref),
            ),
            _Separator(),
            _SettingsTile(
              icon: Icons.notifications_active_outlined,
              label: 'Son du minuteur',
              value: soundLabel,
              onTap: () async {
                await ref.read(timerSoundProvider.notifier).cycle();
                // Aperçu du son fraîchement sélectionné
                final newId = ref.read(timerSoundProvider).value ?? 'beep';
                final asset = kTimerSounds[newId]?.$2;
                if (asset != null) {
                  final p = AudioPlayer();
                  p.onPlayerComplete.listen((_) => p.dispose());
                  try {
                    await p.setAudioContext(AudioContext(
                      android: const AudioContextAndroid(
                        isSpeakerphoneOn: false,
                        stayAwake: false,
                        contentType: AndroidContentType.sonification,
                        usageType: AndroidUsageType.assistanceSonification,
                        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
                      ),
                      iOS: AudioContextIOS(
                        category: AVAudioSessionCategory.playback,
                        options: const {
                          AVAudioSessionOptions.duckOthers,
                          AVAudioSessionOptions.mixWithOthers,
                        },
                      ),
                    ));
                    await p.setVolume(1.0);
                    await p.play(AssetSource(asset));
                  } catch (_) {
                    p.dispose();
                  }
                }
              },
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
}

// ── Synchronisation cloud (Firebase) ──────────────────────────
class _CloudSyncSection extends ConsumerWidget {
  const _CloudSyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final signedIn = user != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('SYNCHRONISATION CLOUD',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: .5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: signedIn
                    ? const Color(0xFF30D158).withValues(alpha: .4)
                    : AppColors.border),
          ),
          child: signedIn
              ? Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_done_rounded,
                          color: Color(0xFF30D158), size: 22),
                      title: const Text('Synchro activée',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Compte : ${user.email ?? "—"}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ),
                    _Separator(),
                    _SettingsTile(
                      icon: Icons.cloud_upload_rounded,
                      label: 'Synchroniser maintenant',
                      value: '',
                      onTap: () => _syncNow(context),
                    ),
                    _Separator(),
                    _SettingsTile(
                      icon: Icons.cloud_download_rounded,
                      label: 'Récupérer depuis le cloud',
                      value: '',
                      onTap: () => _pull(context, ref),
                    ),
                    _Separator(),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      label: 'Se déconnecter',
                      value: '',
                      iconColor: AppColors.error,
                      labelColor: AppColors.error,
                      onTap: () => CloudSyncService.signOut(),
                    ),
                  ],
                )
              : _SettingsTile(
                  icon: Icons.cloud_outlined,
                  label: 'Activer la synchro cloud',
                  value: '',
                  onTap: () => _openLogin(context, ref),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 8),
          child: Text(
            signedIn
                ? 'Tes séances sont sauvegardées automatiquement dans le cloud à chaque entraînement.'
                : 'Crée un compte pour sauvegarder tes séances en ligne et les retrouver sur n\'importe quel téléphone.',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11, height: 1.4),
          ),
        ),
      ],
    );
  }

  Future<void> _syncNow(BuildContext context) async {
    try {
      await CloudSyncService.pushAll();
      final target = CloudSyncService.email ?? 'le cloud';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF30D158),
          content: Text('Synchronisé avec $target ✓',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w700)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Échec : $e')));
      }
    }
  }

  Future<void> _pull(BuildContext context, WidgetRef ref) async {
    final cloudCount = await CloudSyncService.cloudSessionCount();
    if (!context.mounted) return;
    if (cloudCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aucune donnée dans le cloud pour l\'instant.')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Récupérer depuis le cloud'),
        content: Text(
            'Cela remplacera tes données locales par celles du cloud '
            '($cloudCount séance${cloudCount > 1 ? "s" : ""}). Continuer ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white),
            child: const Text('Récupérer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final n = await CloudSyncService.pullAll();
    _invalidateDataProviders(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF30D158),
        content: Text('${n ?? 0} séance(s) récupérée(s) ✓',
            style:
                const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ));
    }
  }

  void _openLogin(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _CloudLoginSheet(),
    );
  }
}

class _CloudLoginSheet extends ConsumerStatefulWidget {
  const _CloudLoginSheet();
  @override
  ConsumerState<_CloudLoginSheet> createState() => _CloudLoginSheetState();
}

class _CloudLoginSheetState extends ConsumerState<_CloudLoginSheet> {
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool signUp}) async {
    final email = _email.text.trim();
    final pwd = _pwd.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Adresse e-mail invalide');
      return;
    }
    if (pwd.length < 6) {
      setState(() => _error = 'Mot de passe : 6 caractères minimum');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (signUp) {
        await CloudSyncService.signUp(email, pwd);
      } else {
        await CloudSyncService.signIn(email, pwd);
      }
      await _reconcile();
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = _msg(e.code);
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Erreur : $e';
      });
    }
  }

  /// Après connexion : si le cloud est vide, on y envoie le local ;
  /// sinon on propose de récupérer le cloud.
  Future<void> _reconcile() async {
    final cloudCount = await CloudSyncService.cloudSessionCount();
    if (cloudCount == null) {
      await CloudSyncService.pushAll();
      return;
    }
    if (!mounted) return;
    final localCount = await BackupService.currentSessionCount();
    if (!mounted) return;
    final pull = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Données existantes'),
        content: Text(
            'Le cloud contient $cloudCount séance(s) et ce téléphone $localCount. '
            'Que veux-tu garder ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Mon téléphone'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white),
            child: const Text('Le cloud'),
          ),
        ],
      ),
    );
    if (pull == true) {
      await CloudSyncService.pullAll();
      _invalidateDataProviders(ref);
    } else {
      await CloudSyncService.pushAll();
    }
  }

  String _msg(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cet e-mail a déjà un compte. Utilise « Se connecter ».';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-mail ou mot de passe incorrect.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères min).';
      case 'network-request-failed':
        return 'Pas de connexion internet.';
      default:
        return 'Erreur ($code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 18),
          const Text('Synchronisation cloud',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Connecte-toi pour sauvegarder tes séances en ligne. '
            'Première fois ? Choisis « Créer un compte ».',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enabled: !_loading,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec('E-mail', Icons.mail_outline_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pwd,
            obscureText: true,
            enabled: !_loading,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec('Mot de passe', Icons.lock_outline_rounded),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(color: AppColors.accent),
            ))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _submit(signUp: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(
                          color: AppColors.accent.withValues(alpha: .4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Créer un compte'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submit(signUp: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Se connecter',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.bgCardElevated,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

// ── Sauvegarde / restauration ─────────────────────────────────
class _BackupSection extends ConsumerWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('SAUVEGARDE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: .5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.ios_share_rounded,
                label: 'Sauvegarder mes données',
                value: '',
                onTap: () => _export(context),
              ),
              _Separator(),
              _SettingsTile(
                icon: Icons.download_rounded,
                label: 'Restaurer une sauvegarde',
                value: '',
                onTap: () => _import(context, ref),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 4, top: 8),
          child: Text(
            'Exporte un fichier .json (à garder sur Drive ou ton téléphone). '
            'La restauration remplace les données actuelles.',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 11, height: 1.4),
          ),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      await BackupService.exportBackup();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'export : $e')),
        );
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final count = await BackupService.currentSessionCount();
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Restaurer une sauvegarde'),
        content: Text(
            'Tes données actuelles ($count séance${count > 1 ? "s" : ""}) seront '
            'remplacées par le contenu du fichier. Continuer ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final restored = await BackupService.importBackup();
      if (restored == null) return; // annulé par l'utilisateur
      // Recharge tous les providers depuis les données restaurées
      ref.invalidate(logHistoryProvider);
      ref.invalidate(planningProvider);
      ref.invalidate(customSessionsProvider);
      ref.invalidate(sessionsConfigProvider);
      ref.invalidate(lastWeightsProvider);
      ref.invalidate(lastRepsProvider);
      ref.invalidate(timerDurationProvider);
      ref.invalidate(userProfileProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF30D158),
            content: Text('$restored séance${restored > 1 ? "s" : ""} restaurée'
                '${restored > 1 ? "s" : ""} ✓',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fichier invalide : $e')),
        );
      }
    }
  }
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
