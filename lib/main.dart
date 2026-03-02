import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/preferences_service.dart';
import 'services/theme_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase — used for DATABASE ONLY (no auth)
  await Supabase.initialize(
    url: 'https://tjzutbitodyhrvfktxhm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqenV0Yml0b2R5aHJ2Zmt0eGhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5OTUwMDcsImV4cCI6MjA4NzU3MTAwN30.XhK6wZm62f-ml0_h5KeuY8ejPH-TZiegM2gV_FkFR14',
  );

  // Initialize SharedPreferences
  await PreferencesService.init();

  await Hive.initFlutter();

  runApp(const MyApp());
}

// Global Supabase client — used for DATABASE QUERIES ONLY (no auth)
final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void refresh(BuildContext context) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.refresh();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();

  void refresh() {
    setState(() {
      _themeService.reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double scaleFactor = _themeService.scaleFactor;

    return MaterialApp(
      title: 'PharmC',
      debugShowCheckedModeBanner: false,
      theme: _themeService.lightTheme,
      darkTheme: _themeService.darkTheme,
      themeMode: _themeService.themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scaleFactor)),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
