import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/log_models.dart';
import '../data/models/user_profile.dart';
import 'log_service.dart';
import 'storage_keys.dart';

/// Sauvegarde / restauration de toutes les données locales (historique,
/// planning, séances personnalisées, profil…) dans un fichier JSON.
class BackupService {
  // Clés SharedPreferences regroupées par type (liste unique dans StorageKeys).
  static const _stringKeys = StorageKeys.stringKeys;
  static const _intKeys = StorageKeys.intKeys;
  static const _boolKeys = StorageKeys.boolKeys;

  /// Exporte toutes les données dans un fichier JSON et ouvre le partage Android.
  static Future<void> exportBackup() async {
    final p = await SharedPreferences.getInstance();
    final data = readData(p);

    final backup = {
      'app': 'FitForge',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    };

    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
    final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(backup));

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: 'FitForge_sauvegarde_$stamp.json',
          mimeType: 'application/json',
        ),
      ],
      subject: 'Sauvegarde FitForge',
      text:
          'Sauvegarde de tes données FitForge. Conserve ce fichier pour pouvoir tout restaurer.',
    );
  }

  /// Nombre de séances dans l'historique actuel.
  static Future<int> currentSessionCount() async {
    final p = await SharedPreferences.getInstance();
    return LogService.decodeHistory(p.getString(StorageKeys.logHistory))
            ?.length ??
        0;
  }

  /// Laisse l'utilisateur choisir un fichier de sauvegarde et restaure les données.
  /// Retourne le nombre de séances restaurées, ou `null` si annulé.
  /// Lève une [FormatException] si le fichier est invalide : dans ce cas
  /// rien n'est écrit, les données actuelles restent intactes.
  static Future<int?> importBackup() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.any, withData: true);
    if (res == null || res.files.isEmpty) return null;
    final bytes = res.files.single.bytes;
    if (bytes == null) return null;

    // 1. Tout décoder et valider AVANT d'écraser quoi que ce soit.
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const FormatException('Fichier de sauvegarde illisible (JSON)');
    }
    if (decoded is! Map) {
      throw const FormatException('Fichier de sauvegarde invalide');
    }
    // Accepte soit { "data": {...} }, soit directement {...}
    final raw = decoded['data'] is Map ? decoded['data'] as Map : decoded;
    final data = validateData(raw);

    // 2. Instantané de l'état courant, puis écriture.
    final p = await SharedPreferences.getInstance();
    await snapshotBeforeRestore(p, origin: 'fichier');
    await writeData(p, data);
    return sessionCountIn(data);
  }

  // ── Lecture / écriture brutes des clés sauvegardées ────────────────

  /// Toutes les valeurs locales connues, prêtes à être sérialisées.
  static Map<String, dynamic> readData(SharedPreferences p) {
    final data = <String, dynamic>{};
    for (final k in _stringKeys) {
      final v = p.getString(k);
      if (v != null) data[k] = v;
    }
    for (final k in _intKeys) {
      final v = p.getInt(k);
      if (v != null) data[k] = v;
    }
    for (final k in _boolKeys) {
      final v = p.getBool(k);
      if (v != null) data[k] = v;
    }
    return data;
  }

  /// Écrit des données déjà validées par [validateData]. Les clés absentes
  /// de `data` sont laissées telles quelles en local.
  static Future<void> writeData(
      SharedPreferences p, Map<String, dynamic> data) async {
    if (data.containsKey(StorageKeys.logHistory)) {
      // L'historique est la donnée la plus précieuse : on garde une copie de
      // la version actuelle avant de la remplacer.
      await LogService.backupHistory(p);
    }
    for (final k in _stringKeys) {
      final v = data[k];
      if (v is String) await p.setString(k, v);
    }
    for (final k in _intKeys) {
      final v = data[k];
      if (v is int) await p.setInt(k, v);
    }
    for (final k in _boolKeys) {
      final v = data[k];
      if (v is bool) await p.setBool(k, v);
    }
  }

  /// Copie l'état local courant dans `ff_restore_undo` (une seule entrée,
  /// écrasée à chaque restauration) pour pouvoir revenir en arrière.
  static Future<void> snapshotBeforeRestore(SharedPreferences p,
      {required String origin}) async {
    final snapshot = {
      'origin': origin,
      'savedAt': DateTime.now().toIso8601String(),
      'data': readData(p),
    };
    await p.setString(StorageKeys.restoreUndo, jsonEncode(snapshot));
  }

  /// Nombre de séances dans un jeu de données validé.
  static int sessionCountIn(Map<String, dynamic> data) =>
      LogService.decodeHistory(data[StorageKeys.logHistory] as String?)
          ?.length ??
      0;

  // ── Validation ─────────────────────────────────────────────────────

  /// Vérifie qu'un jeu de données (fichier ou cloud) est entièrement
  /// exploitable par l'app : bon type pour chaque clé connue, JSON interne
  /// décodable et conforme aux modèles. Retourne uniquement les clés
  /// connues. Lève une [FormatException] à la première anomalie.
  static Map<String, dynamic> validateData(Map raw) {
    final data = <String, dynamic>{};

    for (final k in _stringKeys) {
      if (!raw.containsKey(k)) continue;
      final v = raw[k];
      if (v is! String) throw FormatException('« $k » : chaîne attendue');
      _checkJsonContent(k, v);
      data[k] = v;
    }
    for (final k in _intKeys) {
      if (!raw.containsKey(k)) continue;
      final v = raw[k];
      if (v is! int) throw FormatException('« $k » : entier attendu');
      data[k] = v;
    }
    for (final k in _boolKeys) {
      if (!raw.containsKey(k)) continue;
      final v = raw[k];
      if (v is! bool) throw FormatException('« $k » : booléen attendu');
      data[k] = v;
    }

    if (data.isEmpty) {
      throw const FormatException(
          'Aucune donnée FitForge reconnue dans cette sauvegarde');
    }
    return data;
  }

  /// Décode le JSON interne d'une clé et le passe dans le modèle
  /// correspondant, exactement comme le ferait l'app au chargement.
  static void _checkJsonContent(String key, String value) {
    try {
      switch (key) {
        case StorageKeys.logHistory:
          for (final e in jsonDecode(value) as List) {
            LogSession.fromJson(e as Map<String, dynamic>);
          }
        case StorageKeys.logSessionsConfig:
          for (final e in jsonDecode(value) as List) {
            SessionConfig.fromJson(e as Map<String, dynamic>);
          }
        case StorageKeys.logPlanning:
          (jsonDecode(value) as Map<String, dynamic>)
              .forEach((k, v) { int.parse(k); v as int; });
        case StorageKeys.logLastWeights:
          (jsonDecode(value) as Map<String, dynamic>)
              .forEach((_, v) => v == null ? null : (v as num).toDouble());
        case StorageKeys.logLastReps:
          (jsonDecode(value) as Map<String, dynamic>)
              .forEach((_, v) => (v as num).toInt());
        case StorageKeys.logCustomSessions:
          (jsonDecode(value) as Map<String, dynamic>)
              .forEach((k, v) { int.parse(k); List<String>.from(v as List); });
        case StorageKeys.userProfile:
          UserProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);
        case StorageKeys.timerSound:
          break; // simple identifiant, le provider retombe sur le défaut
      }
    } catch (_) {
      throw FormatException('« $key » : contenu illisible');
    }
  }
}
