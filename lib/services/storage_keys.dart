/// Clés SharedPreferences sauvegardées / synchronisées.
///
/// Liste unique partagée par `BackupService` (fichier JSON) et
/// `CloudSyncService` (Firestore) : toute nouvelle donnée persistante à
/// inclure dans les sauvegardes s'ajoute ici, et nulle part ailleurs.
class StorageKeys {
  StorageKeys._();

  static const logHistory = 'ff_log_hist';
  /// Copie de secours de l'historique, réécrite avant chaque sauvegarde.
  static const logHistoryBackup = 'ff_log_hist_bak';
  static const logPlanning = 'ff_log_plan';
  static const logLastWeights = 'ff_log_lw';
  static const logLastReps = 'ff_log_lr';
  static const logCustomSessions = 'ff_log_custom';
  static const logSessionsConfig = 'ff_log_sessions_config';
  static const logTimerDuration = 'ff_log_timer';
  static const timerSound = 'ff_timer_sound';
  static const themeLight = 'ff_theme_light';
  static const userProfile = 'user_profile_v1';

  /// Instantané de l'état local pris juste avant une restauration
  /// (fichier ou cloud), pour pouvoir revenir en arrière à la main.
  static const restoreUndo = 'ff_restore_undo';

  /// Clés dont la valeur est une chaîne (JSON encodé pour la plupart).
  static const stringKeys = [
    logHistory,          // historique des séances
    logPlanning,         // planning hebdo
    logLastWeights,      // derniers poids
    logLastReps,         // derniers nombres de répétitions
    logCustomSessions,   // exercices perso par séance
    logSessionsConfig,   // séances créées/éditées par l'utilisateur
    timerSound,          // son de fin de minuteur choisi
    userProfile,         // profil utilisateur
  ];

  /// Clés dont la valeur est un entier.
  static const intKeys = [logTimerDuration];

  /// Clés dont la valeur est un booléen.
  static const boolKeys = [themeLight];
}
