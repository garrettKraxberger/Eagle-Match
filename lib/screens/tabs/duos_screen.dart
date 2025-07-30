import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/usga_theme.dart';

class DuosScreen extends StatefulWidget {
  const DuosScreen({super.key});

  @override
  State<DuosScreen> createState() => _DuosScreenState();
}

class _DuosScreenState extends State<DuosScreen> {
  List<Map<String, dynamic>> _partnerships = [];
  List<Map<String, dynamic>> _starredPartnerships = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPartnerships();
  }

  Future<void> _loadPartnerships() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Load all partnerships for the current user
      final response = await Supabase.instance.client
          .from('partnerships')
          .select('''
            *,
            user1_profile:profiles!partnerships_user1_id_fkey(full_name, age, profile_image_url),
            user2_profile:profiles!partnerships_user2_id_fkey(full_name, age, profile_image_url)
          ''')
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .eq('status', 'active')
          .order('matches_played', ascending: false);

      final partnerships = List<Map<String, dynamic>>.from(response);
      
      setState(() {
        _partnerships = partnerships;
        _starredPartnerships = partnerships.where((p) => p['is_starred'] == true).toList();
        _loading = false;
      });

      print('Duos screen: Loaded ${partnerships.length} partnerships, ${_starredPartnerships.length} starred');

    } catch (error) {
      setState(() {
        _loading = false;
        if (error.toString().contains('partnerships') && error.toString().contains('not found')) {
          _error = 'Partnerships table not found. Please set up the partnerships table in your Supabase database first.';
        } else {
          _error = error.toString();
        }
      });
      print('Error loading partnerships: $error');
    }
  }

  String _getPartnerName(Map<String, dynamic> partnership) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (partnership['user1_id'] == currentUserId) {
      return partnership['user2_profile']?['full_name'] ?? 'Unknown Partner';
    } else {
      return partnership['user1_profile']?['full_name'] ?? 'Unknown Partner';
    }
  }

  String? _getPartnerImageUrl(Map<String, dynamic> partnership) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    
    if (partnership['user1_id'] == currentUserId) {
      return partnership['user2_profile']?['profile_image_url'];
    } else {
      return partnership['user1_profile']?['profile_image_url'];
    }
  }

  Future<void> _toggleStarred(Map<String, dynamic> partnership) async {
    try {
      final newStarredStatus = !(partnership['is_starred'] ?? false);
      
      await Supabase.instance.client
          .from('partnerships')
          .update({'is_starred': newStarredStatus})
          .eq('id', partnership['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStarredStatus ? 'Added to starred duos' : 'Removed from starred duos'),
        ),
      );

      _loadPartnerships(); // Refresh data
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating partnership: $error')),
      );
    }
  }

  Future<void> _unlinkPartnership(Map<String, dynamic> partnership) async {
    try {
      await Supabase.instance.client
          .from('partnerships')
          .update({'status': 'inactive'})
          .eq('id', partnership['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partnership unlinked')),
      );

      _loadPartnerships(); // Refresh data
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unlinking partnership: $error')),
      );
    }
  }

  Future<void> _showLinkPlayerDialog() async {
    final emailController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Link a Player'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the email address of the player you want to link with:'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _linkPlayerByEmail(emailController.text.trim());
              },
              child: const Text('Link'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _linkPlayerByEmail(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Find user by email (this would require a custom function or different approach in production)
      // For now, we'll show a message that this feature needs to be implemented
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Player linking by email will be available soon. For now, partnerships are created automatically when you play matches together.'),
          duration: Duration(seconds: 4),
        ),
      );

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error linking player: $error')),
      );
    }
  }

  Widget _buildPartnershipCard(Map<String, dynamic> partnership) {
    final partnerName = _getPartnerName(partnership);
    final partnerImageUrl = _getPartnerImageUrl(partnership);
    final matchesPlayed = partnership['matches_played'] ?? 0;
    final matchesWon = partnership['matches_won'] ?? 0;
    final isStarred = partnership['is_starred'] ?? false;
    final nickname = partnership['nickname'];
    
    final winPercentage = matchesPlayed > 0 ? ((matchesWon / matchesPlayed) * 100).round() : 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: partnerImageUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(partnerImageUrl),
                backgroundColor: isStarred ? Colors.amber : Colors.grey,
                onBackgroundImageError: (exception, stackTrace) {},
              )
            : CircleAvatar(
                backgroundColor: isStarred ? Colors.amber : Colors.grey,
                child: Text(
                  partnerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
        title: Text(nickname ?? partnerName),
        subtitle: Text(
          '$matchesPlayed Matches • $matchesWon Wins • $winPercentage% Win Rate',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'star':
                _toggleStarred(partnership);
                break;
              case 'unlink':
                _showUnlinkDialog(partnership);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'star',
              child: Row(
                children: [
                  Icon(isStarred ? Icons.star_border : Icons.star),
                  const SizedBox(width: 8),
                  Text(isStarred ? 'Unstar' : 'Star'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'unlink',
              child: Row(
                children: [
                  Icon(Icons.link_off, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Unlink', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUnlinkDialog(Map<String, dynamic> partnership) async {
    final partnerName = _getPartnerName(partnership);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unlink Partnership'),
          content: Text('Are you sure you want to unlink your partnership with $partnerName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unlinkPartnership(partnership);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Unlink'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPartnerships,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          size: 64,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Database Setup Required',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!.contains('partnerships table not found') 
                              ? 'The partnerships table needs to be created in your Supabase database.\n\nPlease run the setup_partnerships_table.sql script in your Supabase SQL Editor.'
                              : 'Error: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPartnerships,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPartnerships,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showLinkPlayerDialog,
                          icon: const Icon(Icons.link),
                          label: const Text('Link a Player'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: USGATheme.accentRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Starred Partnerships Section
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 8),
                            const Text(
                              'Starred Duos',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_starredPartnerships.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No starred partnerships yet. Star your favorite partners!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ..._starredPartnerships.map((partnership) => _buildPartnershipCard(partnership)),

                        const SizedBox(height: 24),

                        // All Partnerships Section
                        Row(
                          children: [
                            const Icon(Icons.people, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'All Partnerships',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Expanded(
                          child: _partnerships.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No partnerships yet.\nPlay matches with other players to build partnerships!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _partnerships.length,
                                  itemBuilder: (context, index) {
                                    return _buildPartnershipCard(_partnerships[index]);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}