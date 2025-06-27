import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _userData = response;
        _loading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _loading = false);
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userData == null) {
      return const Scaffold(
        body: Center(child: Text('No user data found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _userData!["profile_image_url"] != null
                        ? NetworkImage(_userData!["profile_image_url"])
                        : null,
                    child: _userData!["profile_image_url"] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_userData!["first_name"] ?? ''} ${_userData!["last_name"] ?? ''}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              title: Text('Birthday'),
              subtitle: Text(_userData!["birthday"]?.split('T')[0] ?? 'Not set'),
            ),
            ListTile(
              title: Text('City'),
              subtitle: Text(_userData!["city"] ?? 'Not set'),
            ),
            ListTile(
              title: Text('State'),
              subtitle: Text(_userData!["state"] ?? 'Not set'),
            ),
            ListTile(
              title: Text('Handicap'),
              subtitle: Text(_userData!["handicap"]?.toString() ?? 'Not set'),
            ),
            ListTile(
              title: Text('Home Course'),
              subtitle: Text(_userData!["home_course"] ?? 'Not set'),
            ),
          ],
        ),
      ),
    );
  }
}