import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/usga_theme.dart';
import '../../theme/theme_manager.dart';
import '../../utils/privacy_utils.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Map<String, dynamic>> _matchRequests = [];
  List<Map<String, dynamic>> _confirmedMatches = [];
  List<Map<String, dynamic>> _upcomingMatches = [];
  List<Map<String, dynamic>> _pastMatches = [];
  List<Map<String, dynamic>> _pendingMatches = []; // ✅ Added pending matches
  bool _loading = true;
  String? _error;
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

      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Load match requests sent to me (for matches I created)
      final requestsResponse = await Supabase.instance.client
          .from('match_requests')
          .select('''
            *,
            matches!inner(
              *,
              creator_profile:profiles!creator_id(full_name, age)
            ),
            requester_profile:profiles!requester_id(full_name, age)
          ''')
          .eq('matches.creator_id', currentUserId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      // Load my confirmed matches (where I'm either creator or have been accepted)
      final allMyMatchesResponse = await Supabase.instance.client
          .from('matches')
          .select('''
            *,
            creator_profile:profiles!creator_id(full_name, age)
          ''')
          .or('creator_id.eq.$currentUserId,teammate_id.eq.$currentUserId')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      // ✅ Load my pending matches (matches I created but no one has joined yet)
      final pendingMatchesResponse = await Supabase.instance.client
          .from('matches')
          .select('''
            *,
            creator_profile:profiles!creator_id(full_name, age)
          ''')
          .eq('creator_id', currentUserId)
          .eq('status', 'active')
          .is_('teammate_id', null) // No one has joined yet
          .order('created_at', ascending: false);

      // Add teammate profile data for each match
      final List<Map<String, dynamic>> matchesWithTeammates = [];
      for (var match in allMyMatchesResponse) {
        final Map<String, dynamic> matchWithTeammate = Map.from(match);
        
        // Fetch teammate profile if teammate_id exists
        if (match['teammate_id'] != null) {
          try {
            final teammateResponse = await Supabase.instance.client
                .from('profiles')
                .select('id, full_name, email, phone, profile_image_url')
                .eq('id', match['teammate_id'])
                .single();
            matchWithTeammate['teammate_profile'] = teammateResponse;
          } catch (e) {
            print('Error fetching teammate profile: $e');
            matchWithTeammate['teammate_profile'] = null;
          }
        } else {
          matchWithTeammate['teammate_profile'] = null;
        }
        
        matchesWithTeammates.add(matchWithTeammate);
      }

      setState(() {
        _matchRequests = List<Map<String, dynamic>>.from(requestsResponse);
        _pendingMatches = List<Map<String, dynamic>>.from(pendingMatchesResponse); // ✅ Set pending matches
        
        // All matches are now in one list - no need for separate confirmed/my matches
        _confirmedMatches = matchesWithTeammates;
        _loading = false;
      });

      // Separate matches into upcoming and past
      _separateMatches();

      print('Matches screen: Loaded ${_matchRequests.length} requests, ${_pendingMatches.length} pending, ${_confirmedMatches.length} total matches');
      print('Upcoming: ${_upcomingMatches.length} matches');
      print('Past: ${_pastMatches.length} matches');
    } catch (error) {
      setState(() {
        _loading = false;
        _error = error.toString();
      });
      print('Error loading matches: $error');
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    try {
      await Supabase.instance.client
          .from('match_requests')
          .update({'status': 'accepted'})
          .eq('id', request['id']);

      // Optionally update the match with the requester as teammate
      if (request['request_type'] == 'join') {
        await Supabase.instance.client
            .from('matches')
            .update({'teammate_id': request['requester_id']})
            .eq('id', request['match_id']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted!')),
      );

      _loadMatches(); // Refresh data
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting request: $error')),
      );
    }
  }

  Future<void> _declineRequest(Map<String, dynamic> request) async {
    try {
      await Supabase.instance.client
          .from('match_requests')
          .update({'status': 'declined'})
          .eq('id', request['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined')),
      );

      _loadMatches(); // Refresh data
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining request: $error')),
      );
    }
  }

  String _formatMatchLocation(Map<String, dynamic> match) {
    if (match['location_mode'] == 'counties') {
      // For county-based matches, we'd need to fetch county data
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

  // ✅ Edit match functionality
  Future<void> _editMatch(Map<String, dynamic> match) async {
    // For now, show a simple dialog. In the future, you could navigate to an edit screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Match'),
        content: const Text('Edit match functionality coming soon! For now, you can cancel and create a new match.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ✅ Cancel match functionality
  Future<void> _cancelMatch(Map<String, dynamic> match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Match'),
        content: const Text('Are you sure you want to cancel this match? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Match'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: USGATheme.error),
            child: const Text('Cancel Match'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('matches')
            .update({'status': 'cancelled'})
            .eq('id', match['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match cancelled successfully')),
        );

        _loadMatches(); // Refresh the list
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling match: $error')),
        );
      }
    }
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

  bool _isMatchInPast(Map<String, dynamic> match) {
    if (match['schedule_mode'] == 'specific') {
      // For specific dates, check if the match date has passed
      final date = match['date'] != null ? DateTime.parse(match['date']) : null;
      if (date != null) {
        final now = DateTime.now();
        final matchDateTime = date;
        
        // If there's a time, factor it in
        if (match['time'] != null) {
          final time = match['time'] as String;
          final timeParts = time.split(':');
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            final matchDateTimeWithTime = DateTime(
              date.year, 
              date.month, 
              date.day, 
              hour, 
              minute
            );
            return matchDateTimeWithTime.isBefore(now);
          }
        }
        
        // If no time specified, consider it past if the date has passed
        return matchDateTime.isBefore(DateTime(now.year, now.month, now.day));
      }
      return false; // No date specified, consider it upcoming
    } else {
      // For flexible matches (days of week), they're ongoing and not considered "past"
      return false;
    }
  }

  void _separateMatches() {
    // Separate all matches into upcoming and past
    _upcomingMatches = _confirmedMatches.where((match) => !_isMatchInPast(match)).toList();
    _pastMatches = _confirmedMatches.where((match) => _isMatchInPast(match)).toList();
  }

  Widget _buildMatchRequestCard(Map<String, dynamic> request) {
    final match = request['matches'];
    final requesterProfile = request['requester_profile']; // ✅ Fixed: was 'profiles', should be 'requester_profile'
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final fullName = requesterProfile?['full_name'] ?? 'Unknown Player';
    final requesterName = PrivacyUtils.formatDisplayName(
      fullName,
      isCurrentUser: requesterProfile?['id'] == currentUserId,
    );
    final requestType = request['request_type'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: USGATheme.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_add,
                    size: 20,
                    color: USGATheme.accentGold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$requesterName wants to $requestType your match',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: USGATheme.textDark,
                    ),
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
                final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                final teammateFullName = match['teammate_profile']['full_name'];
                final teammateDisplayName = PrivacyUtils.formatDisplayName(
                  teammateFullName,
                  isCurrentUser: match['teammate_profile']['id'] == currentUserId,
                );
                return _buildMatchDetail(Icons.group, 'Current teammate: $teammateDisplayName');
              }(),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _declineRequest(request),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: USGATheme.accentRed,
                    side: BorderSide(color: USGATheme.accentRed),
                  ),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _acceptRequest(request),
                  child: const Text('Accept'),
                ),
              ],
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

  Widget _buildConfirmedMatchCard(Map<String, dynamic> match) {
    final profile = match['creator_profile']; // ✅ Fixed: was 'profiles', should be 'creator_profile'
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final fullName = profile?['full_name'] ?? 'Unknown Player';
    final playerName = PrivacyUtils.formatDisplayName(
      fullName,
      isCurrentUser: profile?['id'] == currentUserId,
    );
    final isMyMatch = match['creator_id'] == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match details coming soon!')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: USGATheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.golf_course,
                  size: 24,
                  color: USGATheme.successGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMyMatch ? 'Your match' : 'Match with $playerName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: USGATheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMatchDetail(Icons.location_on, _formatMatchLocation(match)),
                    _buildMatchDetail(Icons.schedule, _formatSchedule(match)),
                    if (match['teammate_profile'] != null) ...[
                      () {
                        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                        final teammateFullName = match['teammate_profile']['full_name'];
                        final teammateDisplayName = PrivacyUtils.formatDisplayName(
                          teammateFullName,
                          isCurrentUser: match['teammate_profile']['id'] == currentUserId,
                        );
                        return _buildMatchDetail(Icons.group, 'Teammate: $teammateDisplayName');
                      }(),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: USGATheme.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastMatchCard(Map<String, dynamic> match) {
    final profile = match['creator_profile']; // ✅ Fixed: was 'profiles', should be 'creator_profile'
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final fullName = profile?['full_name'] ?? 'Unknown Player';
    final playerName = PrivacyUtils.formatDisplayName(
      fullName,
      isCurrentUser: profile?['id'] == currentUserId,
    );
    final isMyMatch = match['creator_id'] == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match history coming soon!')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: USGATheme.textLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.history,
                  size: 24,
                  color: USGATheme.textLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMyMatch ? 'Your match' : 'Match with $playerName',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: USGATheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: USGATheme.textLight.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatMatchLocation(match),
                            style: TextStyle(
                              fontSize: 13,
                              color: USGATheme.textLight.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: USGATheme.textLight.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatSchedule(match),
                            style: TextStyle(
                              fontSize: 13,
                              color: USGATheme.textLight.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (match['teammate_profile'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.group,
                              size: 14,
                              color: USGATheme.textLight.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                () {
                                  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                                  final teammateFullName = match['teammate_profile']['full_name'];
                                  final teammateDisplayName = PrivacyUtils.formatDisplayName(
                                    teammateFullName,
                                    isCurrentUser: match['teammate_profile']['id'] == currentUserId,
                                  );
                                  return 'Teammate: $teammateDisplayName';
                                }(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: USGATheme.textLight.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: USGATheme.textLight.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeManager,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: USGATheme.adaptiveBackground(_themeManager.isDarkMode),
          appBar: AppBar(
            title: const Text('My Matches'),
            backgroundColor: USGATheme.adaptiveBackground(_themeManager.isDarkMode),
            foregroundColor: USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode),
            actions: [
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
              : RefreshIndicator(
                  onRefresh: _loadMatches,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Match Requests Section
                      USGATheme.sectionHeader('Match Requests'),
                      const SizedBox(height: 12),
                      if (_matchRequests.isEmpty)
                        _buildEmptyStateCard(
                          'No pending requests',
                          Icons.inbox_outlined,
                        )
                      else
                        ..._matchRequests.map((request) => _buildMatchRequestCard(request)),

                      const SizedBox(height: 32),

                      // ✅ Pending Matches Section (matches you posted but no one joined)
                      USGATheme.sectionHeader('My Posted Matches'),
                      const SizedBox(height: 12),
                      if (_pendingMatches.isEmpty)
                        _buildEmptyStateCard(
                          'No posted matches waiting for players',
                          Icons.post_add_outlined,
                        )
                      else
                        ..._pendingMatches.map((match) => _buildPendingMatchCard(match)),

                      const SizedBox(height: 32),

                      // Upcoming Matches Section
                      USGATheme.sectionHeader('Upcoming Matches'),
                      const SizedBox(height: 12),
                      if (_upcomingMatches.isEmpty)
                        _buildEmptyStateCard(
                          'No upcoming matches',
                          Icons.calendar_today_outlined,
                        )
                      else
                        ..._upcomingMatches.map((match) => _buildConfirmedMatchCard(match)),

                      const SizedBox(height: 32),

                      // Past Matches Section
                      USGATheme.sectionHeader('Match History'),
                      const SizedBox(height: 12),
                      if (_pastMatches.isEmpty)
                        _buildEmptyStateCard(
                          'No past matches',
                          Icons.history_outlined,
                        )
                      else
                        ..._pastMatches.map((match) => _buildPastMatchCard(match)),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPendingMatchCard(Map<String, dynamic> match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: USGATheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: USGATheme.accentGold.withOpacity(0.3)), // ✅ Gold border for pending
        boxShadow: [
          BoxShadow(
            color: USGATheme.primaryNavy.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with pending status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: USGATheme.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: USGATheme.accentGold.withOpacity(0.3)),
                  ),
                  child: Text(
                    'WAITING FOR PLAYERS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: USGATheme.accentGold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.visibility,
                  size: 16,
                  color: USGATheme.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Visible to others',
                  style: TextStyle(
                    fontSize: 12,
                    color: USGATheme.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Match details
            _buildMatchDetail(Icons.location_on, _formatMatchLocation(match)),
            _buildMatchDetail(Icons.schedule, _formatSchedule(match)),
            _buildMatchDetail(Icons.sports_golf, '${match['match_type']} | ${match['match_mode']}'),
            
            // Match notes if any
            if (match['notes'] != null && (match['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildMatchDetail(Icons.notes, match['notes']),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: USGATheme.modernButton(
                    text: 'Edit Match',
                    onPressed: () => _editMatch(match),
                    isPrimary: false,
                    icon: Icons.edit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: USGATheme.modernButton(
                    text: 'Cancel Match',
                    onPressed: () => _cancelMatch(match),
                    isDestructive: true,
                    icon: Icons.cancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: USGATheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: USGATheme.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: USGATheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: USGATheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
