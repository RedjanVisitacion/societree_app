import 'package:flutter/material.dart';
import 'package:societree_app/screens/orgs/elecom/search_screen.dart';
import 'screens/login_screen.dart';
import 'screens/societree/main_dashboard.dart';
import 'screens/orgs/elecom/dashboard.dart';
import 'screens/orgs/usg/dashboard.dart';
import 'screens/orgs/arcu/dashboard.dart';
import 'screens/orgs/site/dashboard.dart';
import 'screens/orgs/pafe/dashboard.dart';
import 'screens/orgs/afprotechs/dashboard.dart';
import 'screens/orgs/access/dashboard.dart';
import 'screens/orgs/redcross/dashboard.dart';

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
        '/home': (_) => const SocietreeMainDashboard(),
        '/org/elecom': (_) => const ElecomDashboard(),
        '/org/usg': (_) => const UsgDashboard(),
        '/org/arcu': (_) => const ArcuDashboard(),
        '/org/site': (_) => const SiteDashboard(),
        '/org/pafe': (_) => const PafeDashboard(),
        '/org/afprotechs': (_) => const AfprotechsDashboard(),
        '/org/access': (_) => const AccessDashboard(),
        '/org/redcross': (_) => const RedcrossDashboard(),
      },
      // Keep LoginScreen as the app home
      home: const LoginScreen(),
    );
  }
}

// Removed template counter screen in favor of LoginScreen
