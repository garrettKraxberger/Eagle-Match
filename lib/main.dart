import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Theme
import 'theme/usga_theme.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'screens/navigation/main_tab_screen.dart'; // ✅ New main tab screen with nav bar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://xtqkcervtprivpxdsuam.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0cWtjZXJ2dHByaXZweGRzdWFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4MTI5NzQsImV4cCI6MjA2NjM4ODk3NH0.qYZVpqgRAGVGVmUzEcPQdOZW7kthjFJ_g_5DRpBMK10',
      debug: true, // Enable debug mode
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
  }

  runApp(const EagleMatchApp());
}

class EagleMatchApp extends StatefulWidget {
  const EagleMatchApp({super.key});

  @override
  State<EagleMatchApp> createState() => _EagleMatchAppState();
}

class _EagleMatchAppState extends State<EagleMatchApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      
      print('**** Auth state change: $event'); // Debug log
      
      if (event == AuthChangeEvent.signedOut) {
        // Navigate to login screen when user signs out
        print('**** Navigating to login screen'); // Debug log
        Future.microtask(() {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        });
      } else if (event == AuthChangeEvent.signedIn) {
        // Navigate to dashboard when user signs in
        print('**** User signed in, navigating to dashboard'); // Debug log
        Future.microtask(() {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil('/dash', (route) => false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Eagle Match',
      theme: USGATheme.theme, // Apply USGA theme
      initialRoute: session != null ? '/dash' : '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/dash': (_) => const MainTabScreen(), // ✅ Updated to go straight to tabbed layout
        '/profile-setup': (_) => const ProfileSetupScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}