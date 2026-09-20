import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'providers/theme_provider.dart';

class FitForgeApp extends ConsumerWidget {
  const FitForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final light = ref.watch(themeLightProvider);
    final router = ref.watch(routerProvider);

    // La clé change avec le thème : force un remontage complet de l'arbre
    // (les widgets `const` mis en cache par Flutter re-exécutent alors leur
    // build et relisent la nouvelle palette). Le routeur étant le même
    // instance, la navigation en cours est conservée.
    return MaterialApp.router(
      key: ValueKey(light ? 'light' : 'dark'),
      title: 'FitForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}
