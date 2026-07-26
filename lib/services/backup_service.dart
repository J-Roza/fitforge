import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sauvegarde / restauration de toutes les données locales (historique,
/// planning, séances personnalisées, profil…) dans un fichier JSON.
class BackupService {
  // Clés SharedPreferences regroupées par type
  static const _stringKeys = [
    'ff_log_hist',             // historique des séances
    'ff_log_plan',             // planning hebdo
    'ff_log_lw',               // derniers poids
    'ff_log_lr',               // derniers nombres de répétitions
    'ff_log_custom',           // exercices perso par séance
    'ff_log_sessions_config',  // séances créées/éditées par l'utilisateur
    'ff_timer_sound',          // son de fin de minuteur choisi
    'user_profile_v1',         // profil utilisateur
  ];
  static const _intKeys  = ['ff_log_timer'];
  static const _boolKeys = ['ff_log_seeded_v1'];

  /// Exporte toutes les données dans un fichier JSON et ouvre le partage Android.
  static Future<void> exportBackup() async {
    final p = await SharedPreferences.getInstance();
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
    final raw = p.getString('ff_log_hist');
    if (raw == null) return 0;
    try {
      return (jsonDecode(raw) as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Laisse l'utilisateur choisir un fichier de sauvegarde et restaure les données.
  /// Retourne le nombre de séances restaurées, ou `null` si annulé.
  /// Lève une exception si le fichier est invalide.
  static Future<int?> importBackup() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.any, withData: true);
    if (res == null || res.files.isEmpty) return null;
    final bytes = res.files.single.bytes;
    if (bytes == null) return null;

    final content = utf8.decode(bytes);
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw const FormatException('Fichier de sauvegarde invalide');
    }
    // Accepte soit { "data": {...} }, soit directement {...}
    final data = (decoded['data'] is Map ? decoded['data'] : decoded)
        as Map<String, dynamic>;

    final p = await SharedPreferences.getInstance();
    for (final k in _stringKeys) {
      if (data[k] is String) await p.setString(k, data[k] as String);
    }
    for (final k in _intKeys) {
      if (data[k] is int) await p.setInt(k, data[k] as int);
    }
    for (final k in _boolKeys) {
      if (data[k] is bool) await p.setBool(k, data[k] as bool);
    }

    final raw = data['ff_log_hist'];
    if (raw is String) {
      try {
        return (jsonDecode(raw) as List).length;
      } catch (_) {}
    }
    return 0;
  }
}
