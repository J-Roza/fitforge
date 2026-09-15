import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/log_service.dart';

/// Applique le style de la barre système (icônes claires/sombres) selon le mode.
void applySystemChrome() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness:
        AppColors.isLight ? Brightness.dark : Brightness.light,
    statusBarBrightness:
        AppColors.isLight ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness:
        AppColors.isLight ? Brightness.dark : Brightness.light,
  ));
}

class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier(super.light);

  Future<void> set(bool light) async {
    if (light == state) return;
    AppColors.setMode(light);
    applySystemChrome();
    state = light;
    await LogService().saveThemeLight(light);
  }

  void toggle() => set(!state);
}

/// `true` = thème clair. Initialisé depuis AppColors (déjà réglé dans main()).
final themeLightProvider = StateNotifierProvider<ThemeModeNotifier, bool>(
    (ref) => ThemeModeNotifier(AppColors.isLight));
