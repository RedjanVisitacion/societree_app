import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Societree',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/search': (context) {
          // Prefer passing data via arguments; provide empty defaults for safety
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final parties = (args?['parties'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
          final candidates = (args?['candidates'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
          final isElecom = (args?['isElecom'] == true);
          return SearchScreen(parties: parties, candidates: candidates, isElecom: isElecom);
        },
      },
      home: const LoginScreen(),
    );
  }
}

// Removed template counter screen in favor of LoginScreen
