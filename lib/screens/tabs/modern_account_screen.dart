import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/usga_theme.dart';
import '../database_test_screen.dart';
import '../auth/login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  Future<void> _loadUserData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Load profile data from the correct 'profiles' table
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // If profile doesn't exist in profiles table, try to get basic info from auth
      Map<String, dynamic> profileData = profileResponse;
      
      // Check if profile_image_url is missing and try to get it from users table as fallback
      if (profileData['profile_image_url'] == null) {
        try {
          final usersResponse = await Supabase.instance.client
              .from('users')
              .select('profile_image_url')
              .eq('id', userId)
              .single();
          
          if (usersResponse['profile_image_url'] != null) {
            profileData['profile_image_url'] = usersResponse['profile_image_url'];
          }
        } catch (usersError) {
          // No users table or no profile image found
        }
      }

      // Load user statistics
      final matchStats = await _loadUserStats(userId);
      final partnershipStats = await _loadPartnershipStats(userId);

      setState(() {
        _userData = {
          ...profileData,
          'stats': matchStats,
          'partnership_stats': partnershipStats,
        };
        _loading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _loadUserStats(String userId) async {
    try {
      // Get total matches created
      final createdMatches = await Supabase.instance.client
          .from('matches')
          .select('id')
          .eq('creator_id', userId);

      // Get total matches participated in (as creator or teammate)
      final participatedMatches = await Supabase.instance.client
          .from('matches')
          .select('id')
          .or('creator_id.eq.$userId,teammate_id.eq.$userId');

      // Get partnerships count
      final partnerships = await Supabase.instance.client
          .from('partnerships')
          .select('id')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .eq('status', 'active');

      return {
        'matches_created': createdMatches.length,
        'matches_participated': participatedMatches.length,
        'active_partnerships': partnerships.length,
      };
    } catch (e) {
      print('Error loading user stats: $e');
      return {
        'matches_created': 0,
        'matches_participated': 0,
        'active_partnerships': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _loadPartnershipStats(String userId) async {
    try {
      final partnerships = await Supabase.instance.client
          .from('partnerships')
          .select('matches_played, matches_won')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .eq('status', 'active');

      int totalMatches = 0;
      int totalWins = 0;
      
      for (var partnership in partnerships) {
        totalMatches += (partnership['matches_played'] as int? ?? 0);
        totalWins += (partnership['matches_won'] as int? ?? 0);
      }

      return {
        'total_partnership_matches': totalMatches,
        'total_partnership_wins': totalWins,
        'win_percentage': totalMatches > 0 ? (totalWins / totalMatches * 100).round() : 0,
      };
    } catch (e) {
      print('Error loading partnership stats: $e');
      return {
        'total_partnership_matches': 0,
        'total_partnership_wins': 0,
        'win_percentage': 0,
      };
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData!),
      ),
    );
    
    if (result == true) {
      await _loadUserData();
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            USGATheme.modernButton(
              text: 'Logout',
              onPressed: () => Navigator.of(context).pop(true),
              isPrimary: false,
              isDestructive: true,
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging out: $error')),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: USGATheme.backgroundWhite,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: USGATheme.backgroundWhite,
        body: USGATheme.emptyState(
          icon: Icons.error_outline,
          title: 'No Profile Found',
          message: 'Unable to load your profile data.',
          action: USGATheme.modernButton(
            text: 'Retry',
            onPressed: _loadUserData,
          ),
        ),
      );
    }

    final user = Supabase.instance.client.auth.currentUser;
    final stats = _userData!['stats'] as Map<String, dynamic>? ?? {};
    final partnershipStats = _userData!['partnership_stats'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: USGATheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _navigateToEditProfile,
            tooltip: 'Edit Profile',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, 
                          color: USGATheme.accentRed, size: 20),
                      const SizedBox(width: USGATheme.spacingSm),
                      const Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: USGATheme.primaryNavy,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: USGATheme.spacingLg),
              
              // Profile Header Card
              _buildProfileHeader(user),
              
              const SizedBox(height: USGATheme.spacingLg),
              
              // Statistics Section
              USGATheme.sectionHeader('Statistics'),
              _buildStatsGrid(stats, partnershipStats),
              
              const SizedBox(height: USGATheme.spacingLg),
              
              // Quick Actions Section
              USGATheme.sectionHeader('Quick Actions'),
              _buildQuickActions(),
              
              const SizedBox(height: USGATheme.spacing2xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    final profileImageUrl = _userData!['profile_image_url'];
    final fullName = _userData!['full_name'] ?? 'Unknown User';
    final email = user?.email ?? 'No email';
    final location = _userData!['location'] ?? 'Location not set';
    final age = _userData!['age']?.toString() ?? 'Age not set';
    final handicap = _userData!['handicap']?.toString() ?? 'Handicap not set';

    return USGATheme.modernCard(
      child: Column(
        children: [
          // Profile Image and Basic Info
          Row(
            children: [
              // Profile Picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: USGATheme.accentGold,
                    width: 3,
                  ),
                ),
                child: profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          profileImageUrl,
                          width: 74,
                          height: 74,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackAvatar(fullName);
                          },
                        ),
                      )
                    : _buildFallbackAvatar(fullName),
              ),
              
              const SizedBox(width: USGATheme.spacingLg),
              
              // Name and Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: USGATheme.spacingXs),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: USGATheme.spacingLg),
          
          // Profile Details
          _buildDetailRow(Icons.location_on_rounded, 'Location', location),
          const SizedBox(height: USGATheme.spacingSm),
          _buildDetailRow(Icons.cake_rounded, 'Age', age),
          const SizedBox(height: USGATheme.spacingSm),
          _buildDetailRow(Icons.sports_golf_rounded, 'Handicap', handicap),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: USGATheme.primaryNavy,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: USGATheme.textSecondary,
        ),
        const SizedBox(width: USGATheme.spacingSm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, Map<String, dynamic> partnershipStats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: USGATheme.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Matches Created',
              stats['matches_created']?.toString() ?? '0',
              Icons.add_circle_outline_rounded,
              USGATheme.primaryNavy,
            ),
          ),
          const SizedBox(width: USGATheme.spacingSm),
          Expanded(
            child: _buildStatCard(
              'Matches Played',
              stats['matches_participated']?.toString() ?? '0',
              Icons.sports_golf_rounded,
              USGATheme.accentGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(USGATheme.spacingLg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(USGATheme.radiusLg),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: USGATheme.spacingSm),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: USGATheme.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: USGATheme.spacingMd),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.person_rounded,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: _navigateToEditProfile,
          ),
          const SizedBox(height: USGATheme.spacingSm),
          _buildActionTile(
            icon: Icons.bug_report_rounded,
            title: 'Debug Tools',
            subtitle: 'Development and testing features',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DatabaseTestScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return USGATheme.modernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(USGATheme.spacingLg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: USGATheme.primaryNavy.withOpacity(0.1),
              borderRadius: BorderRadius.circular(USGATheme.radiusMd),
            ),
            child: Icon(
              icon,
              color: USGATheme.primaryNavy,
              size: 24,
            ),
          ),
          const SizedBox(width: USGATheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: USGATheme.spacingXs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: USGATheme.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// Placeholder for EditProfileScreen - you'll need to create this
class EditProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  
  const EditProfileScreen({super.key, required this.userData});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: const Center(
        child: Text('Edit Profile Screen - To be implemented'),
      ),
    );
  }
}
