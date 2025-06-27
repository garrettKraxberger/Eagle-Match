import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/navigation/main_tab_screen.dart'; // ✅ New main tab screen with nav bar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xtqkcervtprivpxdsuam.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0cWtjZXJ2dHByaXZweGRzdWFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4MTI5NzQsImV4cCI6MjA2NjM4ODk3NH0.qYZVpqgRAGVGVmUzEcPQdOZW7kthjFJ_g_5DRpBMK10',
  );

  runApp(const EagleMatchApp());
}

class EagleMatchApp extends StatelessWidget {
  const EagleMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Eagle Match',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: session != null ? '/home' : '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const MainTabScreen(), // ✅ Updated to go straight to tabbed layout
        '/profile-setup': (_) => const ProfileSetupScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}