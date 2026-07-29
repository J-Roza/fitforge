import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'services/log_service.dart';
import 'services/cloud_sync_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (sync cloud). Sur Android, lit android/app/google-services.json.
  // Sur le web, il faut fournir la config explicitement (pas de fichier natif).
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Si Firebase n'est pas configuré, l'app continue en mode local seul.
  }

  // Initialise les données de locale pour intl (fr_FR)
  await initializeDateFormatting('fr_FR', null);

  // Retire les anciennes séances de démo héritées, s'il y en a
  final purged = await LogService().purgeSeedSessionsOnce();
  if (purged) CloudSyncService.pushIfSignedIn();


  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: FitForgeApp()));
}
