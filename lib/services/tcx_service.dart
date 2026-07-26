import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import '../data/models/log_models.dart';
import '../data/datasources/exercises_data.dart';

class TcxService {
  /// Génère un fichier TCX en mémoire et ouvre le sélecteur de partage
  /// (fonctionne sur mobile comme sur web, pas de système de fichiers requis).
  static Future<void> exportSession(LogSession session, String sessionName) async {
    final tcx = _buildTcx(session, sessionName);
    final dateStr = '${session.date.year}${session.date.month.toString().padLeft(2,'0')}${session.date.day.toString().padLeft(2,'0')}';
    final bytes = utf8.encode(tcx);
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: 'FitForge_S${session.sessionType}_$dateStr.tcx',
          mimeType: 'application/xml',
        ),
      ],
      subject: 'FitForge - $sessionName - $dateStr',
      text: 'Séance FitForge du $dateStr\nImporte ce fichier .tcx dans Strava, Garmin Connect ou Zepp.',
    );
  }

  static String _buildTcx(LogSession session, String sessionName) {
    final start = session.date.toUtc();
    final startStr = start.toIso8601String().replaceFirst('.000', '');
    final endStr = start.add(const Duration(hours: 1)).toIso8601String().replaceFirst('.000', '');

    // Build notes: exercise name + sets
    final notes = session.exercises.map((ex) {
      String exName = ex.exerciseId;
      try {
        exName = allExercises.firstWhere((e) => e.id == ex.exerciseId).name;
      } catch (_) {}
      final setsStr = ex.sets.map((s) => s.display).join(', ');
      return '$exName : $setsStr';
    }).join('&#xA;');

    final totalKcal = (session.totalVolume / 1000 * 1.5).round().clamp(100, 800);

    return '''<?xml version="1.0" encoding="UTF-8"?>
<TrainingCenterDatabase
  xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd">
  <Activities>
    <Activity Sport="OtherTraining">
      <Id>$startStr</Id>
      <Lap StartTime="$startStr">
        <TotalTimeSeconds>3600</TotalTimeSeconds>
        <MaximumSpeed>0</MaximumSpeed>
        <Calories>$totalKcal</Calories>
        <Intensity>Active</Intensity>
        <TriggerMethod>Manual</TriggerMethod>
        <Track>
          <Trackpoint>
            <Time>$startStr</Time>
          </Trackpoint>
          <Trackpoint>
            <Time>$endStr</Time>
          </Trackpoint>
        </Track>
      </Lap>
      <Notes>$sessionName&#xA;$notes</Notes>
      <Creator xsi:type="Device_t">
        <Name>FitForge</Name>
      </Creator>
    </Activity>
  </Activities>
</TrainingCenterDatabase>''';
  }
}
