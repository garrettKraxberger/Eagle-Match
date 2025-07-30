import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/usga_theme.dart';
import '../database_test_screen.dart';
import '../auth/login_screen.dart';
import '../debug/profile_image_debug_screen.dart';

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
            print('Found profile image in users table: ${usersResponse['profile_image_url']}');
          }
        } catch (usersError) {
          print('No users table or no profile image found: $usersError');
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

  /// Load user match statistics
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

  /// Load partnership statistics
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
    
    // Reload user data when returning from edit screen
    if (result == true) {
      await _loadUserData();
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: USGATheme.accentRed),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          // Navigate directly to LoginScreen widget
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userData == null) {
      return const Scaffold(body: Center(child: Text('No user data found.')));
    }

    final user = Supabase.instance.client.auth.currentUser;
    final stats = _userData!['stats'] as Map<String, dynamic>? ?? {};
    final partnershipStats = _userData!['partnership_stats'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: USGATheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: USGATheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEditProfile,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'debug_profile_image') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileImageDebugScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'debug_profile_image',
                  child: ListTile(
                    leading: Icon(Icons.bug_report, color: Colors.blue),
                    title: Text('Debug Profile Image'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: USGATheme.accentRed),
                    title: const Text('Logout'),
                    contentPadding: EdgeInsets.zero,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header - USGA Style
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: USGATheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: USGATheme.primaryNavy.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar with USGA styling
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: USGATheme.primaryNavy,
                        shape: BoxShape.circle,
                        border: Border.all(color: USGATheme.accentGold, width: 3),
                      ),
                      child: _userData!['profile_image_url'] != null
                          ? ClipOval(
                              child: Image.network(
                                _userData!['profile_image_url'],
                                width: 94,
                                height: 94,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('Profile image load error: $error');
                                  print('Profile image URL: ${_userData!['profile_image_url']}');
                                  return Center(
                                    child: Text(
                                      (_userData!['full_name'] ?? user?.email ?? 'U').substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                (_userData!['full_name'] ?? user?.email ?? 'U').substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Name and title
                    Text(
                      _userData!['full_name'] ?? user?.email ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: USGATheme.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: USGATheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 8),
                    if (_userData!['location'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: USGATheme.primaryNavy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: USGATheme.primaryNavy,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _userData!['location'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: USGATheme.primaryNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Golf Profile Section
              USGATheme.buildSectionHeader('Golf Profile'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: USGATheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: USGATheme.primaryNavy.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildUSGAInfoRow(
                      Icons.sports_golf,
                      'Handicap Index',
                      _userData!['handicap']?.toString() ?? 'Not established',
                      USGATheme.successGreen,
                    ),
                    const SizedBox(height: 16),
                    _buildUSGAInfoRow(
                      Icons.cake_outlined,
                      'Age',
                      _userData!['age']?.toString() ?? 'Not specified',
                      USGATheme.primaryNavy,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Match Statistics Section
              USGATheme.buildSectionHeader('Match Statistics'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: USGATheme.buildStatCard(
                      title: 'Matches Created',
                      value: '${stats['matches_created'] ?? 0}',
                      icon: Icons.add_circle_outline,
                      color: USGATheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: USGATheme.buildStatCard(
                      title: 'Matches Played',
                      value: '${stats['matches_participated'] ?? 0}',
                      icon: Icons.sports_golf,
                      color: USGATheme.successGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: USGATheme.buildStatCard(
                      title: 'Active Partners',
                      value: '${stats['active_partnerships'] ?? 0}',
                      icon: Icons.group_outlined,
                      color: USGATheme.accentGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: USGATheme.buildStatCard(
                      title: 'Win Rate',
                      value: '${partnershipStats['win_percentage'] ?? 0}%',
                      icon: Icons.emoji_events_outlined,
                      color: const Color(0xFF8E24AA), // Purple accent
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Partnership Performance (if applicable)
              if (partnershipStats['total_partnership_matches'] > 0) ...[
                USGATheme.buildSectionHeader('Partnership Performance'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: USGATheme.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: USGATheme.primaryNavy.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildUSGAInfoRow(
                        Icons.sports_golf,
                        'Partnership Matches',
                        '${partnershipStats['total_partnership_matches']}',
                        USGATheme.primaryNavy,
                      ),
                      const SizedBox(height: 16),
                      _buildUSGAInfoRow(
                        Icons.emoji_events_outlined,
                        'Matches Won',
                        '${partnershipStats['total_partnership_wins']}',
                        USGATheme.successGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Account Actions
              USGATheme.buildSectionHeader('Account Actions'),
              const SizedBox(height: 8),
              Column(
                children: [
                  USGATheme.buildActionCard(
                    title: 'Edit Profile',
                    subtitle: 'Update your golf profile information',
                    icon: Icons.edit_outlined,
                    onTap: _navigateToEditProfile,
                    color: USGATheme.primaryNavy,
                  ),
                  const SizedBox(height: 8),
                  USGATheme.buildActionCard(
                    title: 'Database Test',
                    subtitle: 'Test database connectivity and data',
                    icon: Icons.bug_report_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DatabaseTestScreen(),
                        ),
                      );
                    },
                    color: const Color(0xFFFF8F00), // Orange
                  ),
                  const SizedBox(height: 8),
                  USGATheme.buildActionCard(
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    icon: Icons.logout,
                    onTap: _logout,
                    color: const Color(0xFFD32F2F), // Red
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUSGAInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: USGATheme.textLight,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: USGATheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _locationController;
  late TextEditingController _handicapController;
  late TextEditingController _ageController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.userData['full_name'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.userData['location'] ?? '',
    );
    _handicapController = TextEditingController(
      text: widget.userData['handicap']?.toString() ?? '',
    );
    _ageController = TextEditingController(
      text: widget.userData['age']?.toString() ?? '',
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final updates = {
        'id': userId,
        'full_name': _fullNameController.text.trim(),
        'location': _locationController.text.trim(),
        'handicap': _handicapController.text.isNotEmpty ? double.tryParse(_handicapController.text) : null,
        'age': _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('profiles')
          .upsert(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }

    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _locationController.dispose();
    _handicapController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    (widget.userData['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (City, State)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final age = int.tryParse(value);
                          if (age == null || age < 16 || age > 100) {
                            return 'Please enter a valid age (16-100)';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _handicapController,
                      decoration: const InputDecoration(
                        labelText: 'Handicap',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sports_golf),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final handicap = double.tryParse(value);
                          if (handicap == null || handicap < -5 || handicap > 54) {
                            return 'Please enter a valid handicap (-5 to 54)';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveChanges,
                icon: _saving 
                  ? const SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}