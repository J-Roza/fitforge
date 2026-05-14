import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'providers/strava_provider.dart';

class FitForgeApp extends ConsumerStatefulWidget {
  const FitForgeApp({super.key});

  @override
  ConsumerState<FitForgeApp> createState() => _FitForgeAppState();
}

class _FitForgeAppState extends ConsumerState<FitForgeApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _appLinks.uriLinkStream.listen(_handleLink);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    if (uri.scheme == 'fitforge' && uri.host == 'strava-callback') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        ref.read(stravaProvider.notifier).handleCallback(code).then((ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok ? 'Strava connecté !' : 'Erreur de connexion Strava'),
              backgroundColor: ok ? const Color(0xFFFC4C02) : Colors.red,
            ));
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FitForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
