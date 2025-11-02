import 'package:flutter/material.dart';
import 'package:societree_app/screens/orgs/elecom/search_screen.dart';
import 'screens/societree/splash_screen.dart';

// Global theme mode notifier for easy access across the app
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }
}

// Global instance
final themeNotifier = ThemeNotifier();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Societree',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          // Always use light mode for the main app - dark mode only applies to student dashboard
          themeMode: ThemeMode.light,
          routes: {
            '/search': (context) {
              // Prefer passing data via arguments; provide empty defaults for safety
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              final parties =
                  (args?['parties'] as List?)?.cast<Map<String, dynamic>>() ??
                  const <Map<String, dynamic>>[];
              final candidates =
                  (args?['candidates'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  const <Map<String, dynamic>>[];
              final isElecom = args?['isElecom'] as bool? ?? false;
              return SearchScreen(
                parties: parties,
                candidates: candidates,
                isElecom: isElecom,
              );
            },
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}

// Removed template counter screen in favor of LoginScreen
