import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show errors on screen in debug mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0A0A0F),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            const Text('❌ Erreur', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(details.exception.toString(), style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 12),
            Text(details.stack?.toString() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  };

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
