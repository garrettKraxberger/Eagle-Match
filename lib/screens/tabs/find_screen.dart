import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/usga_theme.dart';
import '../../theme/theme_manager.dart';
import '../../utils/privacy_utils.dart';
import '../../widgets/advanced_filters_dialog.dart';

class FindScreen extends StatefulWidget {
  const FindScreen({super.key});

  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _loading = true;
  String? _error;
  MatchFilters _filters = MatchFilters();
  final ThemeManager _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Build query with filters
      var query = Supabase.instance.client
          .from('matches')
          .select('''
            *,
            creator_profile:profiles!creator_id(full_name, age)
          ''')
          .neq('creator_id', Supabase.instance.client.auth.currentUser?.id ?? '')
          .eq('status', 'active');

      // Apply filters
      final filterConditions = _filters.toQueryConditions();
      for (final entry in filterConditions.entries) {
        query = query.eq(entry.key, entry.value);
      }

      // Apply date range filter if set
      if (_filters.dateRange != null) {
        final startDate = _filters.dateRange!.start.toIso8601String().split('T')[0];
        final endDate = _filters.dateRange!.end.toIso8601String().split('T')[0];
        query = query.gte('date', startDate).lte('date', endDate);
      }

      final response = await query.order('created_at', ascending: false);

      // Now fetch location data separately for each match
      final List<Map<String, dynamic>> matchesWithLocation = [];
      
      for (var match in response) {
        final Map<String, dynamic> matchWithLocation = Map.from(match);
        
        // Fetch teammate profile if teammate_id exists
        if (match['teammate_id'] != null) {
          try {
            final teammateResponse = await Supabase.instance.client
                .from('profiles')
                .select('id, full_name, email, phone, profile_image_url')
                .eq('id', match['teammate_id'])
                .single();
            matchWithLocation['teammate_profile'] = teammateResponse;
          } catch (e) {
            print('Error fetching teammate profile: $e');
            matchWithLocation['teammate_profile'] = null;
          }
        } else {
          matchWithLocation['teammate_profile'] = null;
        }
        
        if (match['location_mode'] == 'counties') {
          // Fetch county data for county-based matches
          final locationIds = List<int>.from(match['location_ids'] ?? []);
          if (locationIds.isNotEmpty) {
            try {
              final counties = await Supabase.instance.client
                  .from('counties')
                  .select('county, state')
                  .in_('id', locationIds);
              matchWithLocation['counties'] = counties;
            } catch (e) {
              print('Error fetching counties for match ${match['id']}: $e');
              matchWithLocation['counties'] = [];
            }
          } else {
            matchWithLocation['counties'] = [];
          }
        } else if (match['location_mode'] == 'course') {
          // For custom courses, we already have the data in the match
          if (match['custom_course_name'] != null) {
            // Custom course - no need to fetch from database
            matchWithLocation['courses'] = [];
          } else {
            // Database course - fetch course data
            final locationIds = List<int>.from(match['location_ids'] ?? []);
            if (locationIds.isNotEmpty && !locationIds.contains(-1)) {
              try {
                final courses = await Supabase.instance.client
                    .from('courses')
                    .select('name')
                    .in_('id', locationIds);
                matchWithLocation['courses'] = courses;
              } catch (e) {
                print('Error fetching courses for match ${match['id']}: $e');
                matchWithLocation['courses'] = [];
              }
            } else {
              matchWithLocation['courses'] = [];
            }
          }
        }
        
        matchesWithLocation.add(matchWithLocation);
      }
      
      if (mounted) {
        setState(() {
          _matches = matchesWithLocation;
          _loading = false;
        });
      }
      
      // Debug output
      print('Find screen: Loaded ${matchesWithLocation.length} matches');
      for (var match in matchesWithLocation) {
        print('Match: ${match['id']}, Creator: ${match['creator_id']}, Location: ${match['location_mode']}');
        if (match['custom_course_name'] != null) {
          print('  Custom course: ${match['custom_course_name']}');
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  String _formatMatchLocation(Map<String, dynamic> match) {
    if (match['location_mode'] == 'counties') {
      final counties = match['counties'] as List?;
      if (counties != null && counties.isNotEmpty) {
        final county = counties.first;
        return '${county['county']}, ${county['state']}';
      }
      return 'Location TBD';
    } else {
      // Check for custom course name first
      final customCourseName = match['custom_course_name'] as String?;
      if (customCourseName != null && customCourseName.isNotEmpty) {
        final customCourseCity = match['custom_course_city'] as String?;
        return customCourseCity != null && customCourseCity.isNotEmpty 
            ? '$customCourseName, $customCourseCity'
            : customCourseName;
      }
      
      // Fall back to database courses
      final courses = match['courses'] as List?;
      if (courses != null && courses.isNotEmpty) {
        return courses.first['name'] ?? 'Course TBD';
      }
      return 'Course TBD';
    }
  }

  String _formatSchedule(Map<String, dynamic> match) {
    if (match['schedule_mode'] == 'specific') {
      final date = match['date'] != null ? DateTime.parse(match['date']) : null;
      final time = match['time'] as String?;
      if (date != null) {
        final formattedDate = '${_getWeekday(date.weekday)}, ${_getMonth(date.month)} ${date.day}${_getOrdinalSuffix(date.day)}';
        return time != null ? '$formattedDate at $time' : formattedDate;
      }
      return 'Date TBD';
    } else {
      final daysOfWeek = match['days_of_week'] as List?;
      if (daysOfWeek != null && daysOfWeek.isNotEmpty) {
        return 'Available: ${daysOfWeek.join(', ')}';
      }
      return 'Schedule TBD';
    }
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Future<void> _showFiltersDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AdvancedFiltersDialog(
        initialFilters: _filters,
        onFiltersChanged: (newFilters) {
          setState(() {
            _filters = newFilters;
          });
          _loadMatches(); // Reload with new filters
        },
      ),
    );
  }

  Future<void> _joinMatch(String matchId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('match_requests').insert({
        'match_id': matchId,
        'requester_id': userId,
        'request_type': 'join',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeManager,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: USGATheme.adaptiveBackground(_themeManager.isDarkMode),
          appBar: AppBar(
            title: const Text('Find Matches'),
            backgroundColor: USGATheme.adaptiveBackground(_themeManager.isDarkMode),
            foregroundColor: USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _filters.hasFilters ? USGATheme.accentRed : USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode),
                ),
                onPressed: _showFiltersDialog,
                tooltip: 'Advanced Filters',
              ),
              IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: USGATheme.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading matches',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: USGATheme.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMatches,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _matches.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        margin: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: USGATheme.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: USGATheme.borderLight),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: USGATheme.textLight,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No matches found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Be the first to create a match in your area!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: USGATheme.textLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMatches,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: USGATheme.sectionHeader('Available Matches'),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _matches.length,
                              itemBuilder: (context, index) {
                                final match = _matches[index];
                                final profile = match['creator_profile']; // ✅ Fixed: was 'profiles', should be 'creator_profile'
                                final fullName = profile?['full_name'] ?? 'Unknown Player';
                                final playerName = PrivacyUtils.formatDisplayName(
                                  fullName,
                                  isCurrentUser: false, // ✅ Always use privacy formatting for creators in public listings
                                );
                                final age = profile?['age'];
                                
                                return _buildMatchCard(match, playerName, age);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, String playerName, int? age) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: USGATheme.cardWhite,
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: USGATheme.primaryNavy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 24,
                    color: USGATheme.primaryNavy,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: USGATheme.textDark,
                        ),
                      ),
                      if (age != null)
                        Text(
                          'Age: $age',
                          style: const TextStyle(
                            fontSize: 14,
                            color: USGATheme.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMatchDetail(Icons.location_on, _formatMatchLocation(match)),
            _buildMatchDetail(Icons.schedule, _formatSchedule(match)),
            _buildMatchDetail(Icons.sports_golf, '${match['match_type']} | ${match['match_mode']}'),
            if (match['teammate_profile'] != null) ...[
              () {
                final teammateFullName = match['teammate_profile']['full_name'];
                final teammateDisplayName = PrivacyUtils.formatDisplayName(
                  teammateFullName,
                  isCurrentUser: false, // ✅ Always use privacy formatting for teammates in public listings
                );
                return _buildMatchDetail(Icons.group, 'Current teammate: $teammateDisplayName');
              }(),
            ],
            if (match['notes'] != null && match['notes'].toString().isNotEmpty)
              _buildMatchDetail(Icons.note, match['notes']),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _joinMatch(match['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: USGATheme.accentRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Request to Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: USGATheme.textLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: USGATheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}