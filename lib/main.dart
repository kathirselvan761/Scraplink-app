import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load any user-configured development URL
  await AppConfig.current.loadPersistedUrl();

  final config = AppConfig.current;
  debugPrint('[ScrapLink Collector] Initialized with backend: ${config.baseUrl}');

  runApp(const ScrapLinkCollectorApp());
}

class ScrapLinkCollectorApp extends StatelessWidget {
  const ScrapLinkCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScrapLink Collector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const SplashScreen(),
    );
  }
}
