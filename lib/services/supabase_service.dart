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

  /// Get or create user profile
  static Future<Map<String, dynamic>?> getOrCreateUserProfile() async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      // Try to get existing profile
      final profile = await client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();
      return profile;
    } catch (e) {
      // Profile doesn't exist, create it
      try {
        final newProfile = await client
            .from('profiles')
            .insert({
              'id': user.id,
              'full_name': user.email?.split('@')[0] ?? 'User',
              'age': 25,
              'handicap': 15.0,
              'location': 'Not specified',
            })
            .select()
            .single();
        return newProfile;
      } catch (createError) {
        print('Error creating profile: $createError');
        return null;
      }
    }
  }

  /// Check if user has a profile
  static Future<bool> hasUserProfile() async {
    final user = getCurrentUser();
    if (user == null) return false;

    try {
      await client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .single();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Partnership Management Functions

  /// Create or update a partnership between two users
  static Future<Map<String, dynamic>?> createOrUpdatePartnership({
    required String user1Id,
    required String user2Id,
    bool incrementMatches = false,
    bool incrementWins = false,
  }) async {
    try {
      // Ensure consistent ordering (user1 is always the "smaller" ID)
      String actualUser1Id = user1Id.compareTo(user2Id) < 0 ? user1Id : user2Id;
      String actualUser2Id = user1Id.compareTo(user2Id) < 0 ? user2Id : user1Id;

      // Check if partnership already exists
      final existingPartnership = await client
          .from('partnerships')
          .select('*')
          .eq('user1_id', actualUser1Id)
          .eq('user2_id', actualUser2Id)
          .maybeSingle();

      if (existingPartnership != null) {
        // Update existing partnership
        final updates = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (incrementMatches) {
          updates['matches_played'] = (existingPartnership['matches_played'] ?? 0) + 1;
        }

        if (incrementWins) {
          updates['matches_won'] = (existingPartnership['matches_won'] ?? 0) + 1;
        }

        final updatedPartnership = await client
            .from('partnerships')
            .update(updates)
            .eq('id', existingPartnership['id'])
            .select()
            .single();

        print('✅ Updated partnership: ${updatedPartnership['matches_played']} matches played, ${updatedPartnership['matches_won']} won');
        return updatedPartnership;
      } else {
        // Create new partnership
        final newPartnership = {
          'user1_id': actualUser1Id,
          'user2_id': actualUser2Id,
          'matches_played': incrementMatches ? 1 : 0,
          'matches_won': incrementWins ? 1 : 0,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final createdPartnership = await client
            .from('partnerships')
            .insert(newPartnership)
            .select()
            .single();

        print('✅ Created new partnership between users');
        return createdPartnership;
      }
    } catch (error) {
      print('❌ Error creating/updating partnership: $error');
      return null;
    }
  }

  /// Record a match result and update partnership statistics
  static Future<bool> recordMatchResult({
    required String matchId,
    required String winnerId,
    String? loserId,
  }) async {
    try {
      // Get the match details to find participants
      final match = await client
          .from('matches')
          .select('creator_id, teammate_id')
          .eq('id', matchId)
          .single();

      final creatorId = match['creator_id'] as String;
      final teammateId = match['teammate_id'] as String?;

      // If it's a duos match and we have both players
      if (teammateId != null) {
        // Determine who won and who lost in the partnership
        bool partnershipWon = (winnerId == creatorId || winnerId == teammateId);

        await createOrUpdatePartnership(
          user1Id: creatorId,
          user2Id: teammateId,
          incrementMatches: true,
          incrementWins: partnershipWon,
        );

        print('✅ Recorded match result for partnership');
        return true;
      }

      return false;
    } catch (error) {
      print('❌ Error recording match result: $error');
      return false;
    }
  }

  /// Get partnerships for a user
  static Future<List<Map<String, dynamic>>> getUserPartnerships(String userId) async {
    try {
      final partnerships = await client
          .from('partnerships')
          .select('''
            *,
            user1_profile:profiles!partnerships_user1_id_fkey(full_name, age),
            user2_profile:profiles!partnerships_user2_id_fkey(full_name, age)
          ''')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .eq('status', 'active')
          .order('matches_played', ascending: false);

      return List<Map<String, dynamic>>.from(partnerships);
    } catch (error) {
      print('❌ Error loading partnerships: $error');
      return [];
    }
  }
}