import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  /// Sign up a new user
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(email: email, password: password);
  }

  /// Sign in an existing user
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Get the currently logged-in user
  static User? getCurrentUser() {
    return client.auth.currentUser;
  }

  /// Check if a user is signed in
  static bool isSignedIn() {
    return client.auth.currentUser != null;
  }
}