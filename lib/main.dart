import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/preferences_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://bohcsmhjpmfztgarbyst.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvaGNzbWhqcG1menRnYXJieXN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MDUxNTcsImV4cCI6MjA4NzM4MTE1N30.s17zOqI93Tqrc5jNlKxNE-ISxWzuF7bDXd5omsRbR7Y',
  );

  // Initialize SharedPreferences
  await PreferencesService.init();

  runApp(const MyApp());
}

// Global Supabase client - use this anywhere in the app
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
