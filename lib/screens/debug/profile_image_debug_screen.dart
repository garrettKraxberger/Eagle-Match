import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileImageDebugScreen extends StatefulWidget {
  const ProfileImageDebugScreen({super.key});

  @override
  State<ProfileImageDebugScreen> createState() => _ProfileImageDebugScreenState();
}

class _ProfileImageDebugScreenState extends State<ProfileImageDebugScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  String? _debugInfo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _debugInfo = 'No authenticated user found';
        _loading = false;
      });
      return;
    }

    try {
      // Load profile data from the profiles table
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      String debugInfo = 'Profile data loaded:\n';
      debugInfo += 'ID: ${profileResponse['id']}\n';
      debugInfo += 'Full Name: ${profileResponse['full_name']}\n';
      debugInfo += 'Profile Image URL: ${profileResponse['profile_image_url']}\n';

      // If profile_image_url is missing, try to get it from users table as fallback
      if (profileResponse['profile_image_url'] == null) {
        debugInfo += '\nProfile image is null, checking users table...\n';
        try {
          final usersResponse = await Supabase.instance.client
              .from('users')
              .select('profile_image_url')
              .eq('id', userId)
              .single();
          
          debugInfo += 'Users table profile_image_url: ${usersResponse['profile_image_url']}\n';
          
          if (usersResponse['profile_image_url'] != null) {
            profileResponse['profile_image_url'] = usersResponse['profile_image_url'];
            debugInfo += 'Using profile image from users table\n';
          }
        } catch (usersError) {
          debugInfo += 'Error checking users table: $usersError\n';
        }
      }

      setState(() {
        _userData = profileResponse;
        _debugInfo = debugInfo;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error loading user data: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Image Debug'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Debug Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _debugInfo ?? 'No debug info',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile Image Display Test
                  const Text(
                    'Profile Image Display Test:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_userData != null) ...[
                    // Test 1: Direct NetworkImage
                    if (_userData!['profile_image_url'] != null) ...[
                      const Text('Test 1: Direct NetworkImage'),
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(_userData!['profile_image_url']),
                        backgroundColor: Colors.grey[300],
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint('NetworkImage error: $exception');
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Test 2: Image.network with error handling
                      const Text('Test 2: Image.network with error handling'),
                      const SizedBox(height: 8),
                      ClipOval(
                        child: Image.network(
                          _userData!['profile_image_url'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Image.network error: $error');
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.red[100],
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Test 3: Raw URL display
                      const Text('Test 3: URL Details'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _userData!['profile_image_url'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ] else ...[
                      const Text('No profile image URL found'),
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: Text(
                          (_userData!['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ]
                  ] else ...[
                    const Text('No user data available'),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Test Supabase Storage
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final buckets = await Supabase.instance.client.storage.listBuckets();
                        final files = await Supabase.instance.client.storage
                            .from('avatars')
                            .list();
                        
                        setState(() {
                          _debugInfo = (_debugInfo ?? '') + 
                              '\n\nStorage Test:\n' +
                              'Buckets: ${buckets.map((b) => b.name).join(', ')}\n' +
                              'Files in avatars: ${files.map((f) => f.name).join(', ')}';
                        });
                      } catch (e) {
                        setState(() {
                          _debugInfo = (_debugInfo ?? '') + 
                              '\n\nStorage Test Error: $e';
                        });
                      }
                    },
                    child: const Text('Test Storage Access'),
                  ),
                ],
              ),
            ),
    );
  }
}
