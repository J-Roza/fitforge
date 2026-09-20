import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_colors.dart';
import 'providers/theme_provider.dart';
import 'services/log_service.dart';
import 'services/cloud_sync_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (sync cloud). Sur Android, lit android/app/google-services.json.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Si Firebase n'est pas configuré, l'app continue en mode local seul.
  }

  // Initialise les données de locale pour intl (fr_FR)
  await initializeDateFormatting('fr_FR', null);

  // Retire les anciennes séances de démo héritées, s'il y en a
  final purged = await LogService().purgeSeedSessionsOnce();
  if (purged) CloudSyncService.pushIfSignedIn();

  // Thème (clair / sombre) — appliqué avant le premier rendu.
  final light = await LogService().loadThemeLight();
  AppColors.setMode(light);

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Barre système selon le thème
  applySystemChrome();

  runApp(const ProviderScope(child: FitForgeApp()));
}
