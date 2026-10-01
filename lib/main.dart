import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_main_screen.dart';
import 'screens/worker/worker_main_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/mysql_service.dart';
import 'theme/app_theme.dart';

import 'screens/splash_screen.dart';
import 'screens/landing_page_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Firebase] initializeApp note: $e');
  }

  // Initialize Services
  final firestore = FirestoreService();
  await firestore.initialize();

  final mysql = MySqlService();
  await mysql.initialize();

  final auth = AuthService();
  auth.initialize();

  // ---------------------------------------------------------------------------
  // DATABASE SEEDER (COMMENTED OUT FOR CLEAN SLATE TESTING)
  // To seed initial sample accounts, people, jobs, and messages, uncomment:
  // ---------------------------------------------------------------------------
  // await DatabaseSeeder.seedAll();

  runApp(const ServikoApp());
}

class ServikoApp extends StatelessWidget {
  const ServikoApp({super.key});

  @override
  Widget build(BuildContext context) {  
    return MaterialApp(
      title: 'Serviko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final auth = AuthService();

        if (!auth.isLoggedIn) {
          return const LandingPageScreen();
        }

        // Route by role
        if (auth.isWorker) {
          return const WorkerMainScreen();
        }

        return const CustomerMainScreen();
      },
    );
  }
}
