import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/usga_theme.dart';
import '../../theme/theme_manager.dart';
import '../../services/supabase_service.dart';
import '../../utils/privacy_utils.dart';

enum LocationMode { counties, course }
enum ScheduleMode { specific, flexible }

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  String _matchType = 'Match Play';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final ThemeManager _themeManager = ThemeManager();
  bool _isPrivate = false;
  String _matchMode = 'Single';
  String? _selectedTeammateId;
  final _teammateController = TextEditingController();
  final _notesController = TextEditingController();
  ScheduleMode _scheduleMode = ScheduleMode.specific;
  final Set<String> _selectedDaysOfWeek = {};
  bool _handicapRequired = false;

  final List<String> _matchTypes = ['Match Play', 'Stroke Play'];
  final List<String> _matchModes = ['Single', 'Duo'];
  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  LocationMode _locationMode = LocationMode.counties;

  // Location data structures
  Map<String, int> _courseMap = {};
  Map<String, int> _countyMap = {};
  List<Map<String, dynamic>> _coursesData = [];
  Map<String, List<String>> _stateToCounties = {};
  List<String> _states = [];
  String? _selectedState;
  List<String> _filteredCounties = [];
  Set<String> _selectedCounties = {};

  // Course mode fields
  String _selectedCourse = '';
  String _selectedCity = '';
  final _courseController = TextEditingController();
  final _cityController = TextEditingController();

  // Teammate search fields
  List<Map<String, dynamic>> _searchedTeammates = [];
  bool _searchingTeammates = false;
  Map<String, dynamic>? _selectedTeammate;

  bool _loadingCourses = true;
  bool _loadingCounties = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadCounties();
  }

  @override
  void dispose() {
    _teammateController.dispose();
    _notesController.dispose();
    _courseController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final data = await Supabase.instance.client
          .from('courses')
          .select('id, name, city, state')
          .order('name');
      setState(() {
        _coursesData = data.cast<Map<String, dynamic>>();
        _courseMap = {for (var e in data) e['name']: int.tryParse(e['id'].toString()) ?? 0};
        _loadingCourses = false;
      });
    } catch (error) {
      print('Error loading courses: $error');
      setState(() => _loadingCourses = false);
    }
  }

  Future<void> _loadCounties() async {
    try {
      final data = await Supabase.instance.client
          .from('counties')
          .select('id, county, state')
          .order('state')
          .order('county');

      final Set<String> states = {};
      final Map<String, List<String>> stateToCounties = {};
      final Map<String, int> countyMap = {};

      for (var row in data) {
        final state = row['state'];
        final county = row['county'];
        final full = '$county, $state';
        
        states.add(state);
        stateToCounties[state] = [...?stateToCounties[state], county];
        countyMap[full] = int.tryParse(row['id'].toString()) ?? 0;
      }

      setState(() {
        _states = states.toList()..sort();
        _stateToCounties = stateToCounties;
        _countyMap = countyMap;
        _loadingCounties = false;
      });
    } catch (error) {
      print('Error loading counties: $error');
      setState(() => _loadingCounties = false);
    }
  }

  void _updateFilteredCounties() {
    if (_selectedState != null && _stateToCounties.containsKey(_selectedState)) {
      setState(() {
        _filteredCounties = _stateToCounties[_selectedState]!;
      });
    } else {
      setState(() => _filteredCounties = []);
    }
  }

  List<String> _getFilteredCourses(String searchText) {
    var filteredCourses = _coursesData.where((course) {
      final name = course['name'] as String;
      final matchesName = name.toLowerCase().contains(searchText.toLowerCase());
      
      // If state and county are selected in course mode, filter by them
      if (_locationMode == LocationMode.course && 
          _selectedState != null && 
          _selectedCounties.isNotEmpty) {
        final courseState = course['state'] as String?;
        
        // For now, just filter by state. In a real app, you'd need a proper city-county mapping
        return matchesName && courseState == _selectedState;
      }
      
      return matchesName;
    });

    return filteredCourses.map((e) => e['name'] as String).toList();
  }

  List<String> _getFilteredCities() {
    if (_selectedState == null) return [];
    
    final citiesInState = _coursesData
        .where((course) => course['state'] == _selectedState)
        .map((course) => course['city'] as String?)
        .where((city) => city != null && city.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    
    citiesInState.sort();
    return citiesInState;
  }

  void _resetLocationFields() {
    setState(() {
      _selectedState = null;
      _filteredCounties = [];
      _selectedCounties.clear();
      _selectedCourse = '';
      _selectedCity = '';
      _courseController.clear();
      _cityController.clear();
    });
  }

  // Teammate search methods
  Future<void> _searchTeammates(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchedTeammates = [];
        _searchingTeammates = false;
      });
      return;
    }

    setState(() => _searchingTeammates = true);

    try {
      final results = await SupabaseService.searchProfiles(query);
      setState(() {
        _searchedTeammates = results;
        _searchingTeammates = false;
      });
    } catch (error) {
      print('Error searching teammates: $error');
      setState(() {
        _searchedTeammates = [];
        _searchingTeammates = false;
      });
    }
  }

  void _selectTeammate(Map<String, dynamic> teammate) {
    setState(() {
      _selectedTeammate = teammate;
      _selectedTeammateId = teammate['id'];
      _teammateController.text = teammate['full_name'] ?? 'Unknown';
      _searchedTeammates = [];
    });
  }

  void _clearTeammateSelection() {
    setState(() {
      _selectedTeammate = null;
      _selectedTeammateId = null;
      _teammateController.clear();
      _searchedTeammates = [];
    });
  }

  Future<void> _submitMatch() async {
    // Validate based on location mode
    if (_locationMode == LocationMode.counties) {
      if (_selectedState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a state.')),
        );
        return;
      }
      if (_selectedCounties.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one county.')),
        );
        return;
      }
    } else if (_locationMode == LocationMode.course) {
      if (_selectedState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a state.')),
        );
        return;
      }
      if (_selectedCounties.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a county.')),
        );
        return;
      }
      if (_selectedCity.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or enter a city.')),
        );
        return;
      }
      if (_selectedCourse.isEmpty && _courseController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or enter a course name.')),
        );
        return;
      }
    }

    if (_scheduleMode == ScheduleMode.specific) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date.')),
        );
        return;
      }
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time.')),
        );
        return;
      }
    }

    if (_scheduleMode == ScheduleMode.flexible && _selectedDaysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day for flexible scheduling.')),
      );
      return;
    }

    if (_matchMode == 'Duo' && _selectedTeammateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a registered teammate for duo matches.')),
      );
      return;
    }

    try {
      final locationIds = _locationMode == LocationMode.counties
          ? _selectedCounties
              .map((c) => _countyMap['$c, $_selectedState'])
              .whereType<int>()
              .toList()
          : _locationMode == LocationMode.course && _courseController.text.isNotEmpty
              ? [_courseMap[_courseController.text] ?? -1]
              : [-1];

      // Get the current user ID
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final matchData = {
        'creator_id': currentUserId, // ✅ CRITICAL: This was missing!
        'match_type': _matchType,
        'match_mode': _matchMode,
        'location_mode': _locationMode == LocationMode.counties ? 'counties' : 'course',
        'location_ids': locationIds,
        'handicap_required': _handicapRequired,
        'is_private': _isPrivate,
        'schedule_mode': _scheduleMode == ScheduleMode.specific ? 'specific' : 'flexible',
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'teammate_id': _selectedTeammateId,
      };

      if (_scheduleMode == ScheduleMode.specific) {
        matchData['date'] = _selectedDate!.toIso8601String().split('T')[0];
        matchData['time'] = _formatTimeOfDay(_selectedTime!);
      } else {
        matchData['days_of_week'] = _selectedDaysOfWeek.toList();
      }

      // Add custom course info for course mode
      if (_locationMode == LocationMode.course) {
        if (_courseController.text.trim().isNotEmpty && 
            !_courseMap.containsKey(_courseController.text.trim())) {
          // Custom course
          matchData['custom_course_name'] = _courseController.text.trim();
          matchData['custom_course_city'] = _selectedCity.isNotEmpty ? _selectedCity : _cityController.text.trim();
        } else if (_selectedCourse.isNotEmpty) {
          // Selected existing course
          final selectedCourseData = _coursesData.firstWhere(
            (course) => course['name'] == _selectedCourse,
            orElse: () => {},
          );
          if (selectedCourseData.isNotEmpty) {
            matchData['custom_course_name'] = null;
            matchData['custom_course_city'] = selectedCourseData['city'];
          }
        }
      }

      await Supabase.instance.client.from('matches').insert(matchData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _resetForm();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating match: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _matchType = 'Match Play';
      _matchMode = 'Single';
      _selectedDate = null;
      _selectedTime = null;
      _isPrivate = false;
      _handicapRequired = false;
      _selectedTeammateId = null;
      _selectedTeammate = null;
      _searchedTeammates = [];
      _scheduleMode = ScheduleMode.specific;
      _selectedDaysOfWeek.clear();
      _resetLocationFields();
    });
    _teammateController.clear();
    _notesController.clear();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeManager,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: USGATheme.adaptiveBackground(_themeManager.isDarkMode),
          appBar: AppBar(
            title: const Text('Create Match'),
            centerTitle: true,
            backgroundColor: USGATheme.adaptiveBackground(_themeManager.isDarkMode),
            foregroundColor: USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(USGATheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match Details Section
                USGATheme.sectionHeader('Match Details', isDark: _themeManager.isDarkMode),
                const SizedBox(height: USGATheme.spacingSm),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: USGATheme.spacingSm),
                  decoration: BoxDecoration(
                    color: USGATheme.adaptiveSurface(_themeManager.isDarkMode),
                    borderRadius: BorderRadius.circular(USGATheme.radiusLg),
                    border: Border.all(color: USGATheme.adaptiveBorder(_themeManager.isDarkMode), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: USGATheme.primaryNavy.withValues(alpha: _themeManager.isDarkMode ? 0.1 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(USGATheme.spacingLg),
                    child: Column(
                      children: [
                        _buildMatchTypeSelector(),
                        const SizedBox(height: USGATheme.spacingMd),
                        _buildMatchModeSelector(),
                        if (_matchMode == 'Duo') ...[
                          const SizedBox(height: USGATheme.spacingMd),
                          _buildTeammateSelector(),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: USGATheme.spacingLg),

                // Location Section  
                USGATheme.sectionHeader('Location', isDark: _themeManager.isDarkMode),
                const SizedBox(height: USGATheme.spacingSm),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: USGATheme.spacingSm),
                  decoration: BoxDecoration(
                    color: USGATheme.adaptiveSurface(_themeManager.isDarkMode),
                    borderRadius: BorderRadius.circular(USGATheme.radiusLg),
                    border: Border.all(color: USGATheme.adaptiveBorder(_themeManager.isDarkMode), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: USGATheme.primaryNavy.withValues(alpha: _themeManager.isDarkMode ? 0.1 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(USGATheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationModeSelector(),
                        const SizedBox(height: USGATheme.spacingMd),
                        _buildLocationFields(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: USGATheme.spacingLg),

                // Schedule Section
                USGATheme.sectionHeader('Schedule', isDark: _themeManager.isDarkMode),
                const SizedBox(height: USGATheme.spacingSm),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: USGATheme.spacingSm),
                  decoration: BoxDecoration(
                    color: USGATheme.adaptiveSurface(_themeManager.isDarkMode),
                    borderRadius: BorderRadius.circular(USGATheme.radiusLg),
                    border: Border.all(color: USGATheme.adaptiveBorder(_themeManager.isDarkMode), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: USGATheme.primaryNavy.withValues(alpha: _themeManager.isDarkMode ? 0.1 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(USGATheme.spacingLg),
                    child: Column(
                      children: [
                        _buildScheduleModeSelector(),
                        const SizedBox(height: USGATheme.spacingMd),
                        _buildScheduleFields(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: USGATheme.spacingLg),

                // Additional Options
                USGATheme.sectionHeader('Additional Options', isDark: _themeManager.isDarkMode),
                const SizedBox(height: USGATheme.spacingSm),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: USGATheme.spacingSm),
                  decoration: BoxDecoration(
                    color: USGATheme.adaptiveSurface(_themeManager.isDarkMode),
                    borderRadius: BorderRadius.circular(USGATheme.radiusLg),
                    border: Border.all(color: USGATheme.adaptiveBorder(_themeManager.isDarkMode), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: USGATheme.primaryNavy.withValues(alpha: _themeManager.isDarkMode ? 0.1 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(USGATheme.spacingLg),
                    child: Column(
                      children: [
                        _buildNotesField(),
                        const SizedBox(height: USGATheme.spacingMd),
                        _buildOptionsToggles(),
                      ],
                    ),
                  ),
                ),

            const SizedBox(height: USGATheme.spacing2xl),

            // Create Button
            USGATheme.modernButton(
              text: 'Create Match',
              onPressed: _submitMatch,
              isFullWidth: true,
            ),

            const SizedBox(height: USGATheme.spacingLg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode),
          ),
        ),
        const SizedBox(height: USGATheme.spacingSm),
        Row(
          children: _matchTypes.map((type) {
            final isSelected = _matchType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type == _matchTypes.first ? USGATheme.spacingSm : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _matchType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: USGATheme.spacingMd,
                      vertical: USGATheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? USGATheme.primaryNavy : USGATheme.adaptiveSurface(_themeManager.isDarkMode),
                      borderRadius: BorderRadius.circular(USGATheme.radiusMd),
                      border: Border.all(
                        color: isSelected ? USGATheme.primaryNavy : USGATheme.adaptiveBorder(_themeManager.isDarkMode),
                      ),
                    ),
                    child: Text(
                      type,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMatchModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode),
          ),
        ),
        const SizedBox(height: USGATheme.spacingSm),
        Row(
          children: _matchModes.map((mode) {
            final isSelected = _matchMode == mode;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: mode == _matchModes.first ? USGATheme.spacingSm : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      // Clear teammate selection if switching from Duo to Single
                      if (_matchMode == 'Duo' && mode == 'Single') {
                        _clearTeammateSelection();
                      }
                      _matchMode = mode;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: USGATheme.spacingMd,
                      vertical: USGATheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? USGATheme.accentRed : USGATheme.adaptiveSurface(_themeManager.isDarkMode),
                      borderRadius: BorderRadius.circular(USGATheme.radiusMd),
                      border: Border.all(
                        color: isSelected ? USGATheme.accentRed : USGATheme.adaptiveBorder(_themeManager.isDarkMode),
                      ),
                    ),
                    child: Text(
                      mode,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode),
          ),
        ),
        const SizedBox(height: USGATheme.spacingSm),
        Row(
          children: [
            Expanded(
              child: RadioListTile<LocationMode>(
                title: Text('County Area', style: TextStyle(color: USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode))),
                subtitle: Text('General area/county', style: TextStyle(color: USGATheme.adaptiveTextSecondary(_themeManager.isDarkMode))),
                value: LocationMode.counties,
                groupValue: _locationMode,
                activeColor: USGATheme.primaryNavy,
                onChanged: (value) {
                  if (value != null) {
                    _resetLocationFields();
                    setState(() => _locationMode = value);
                  }
                },
              ),
            ),
            Expanded(
              child: RadioListTile<LocationMode>(
                title: Text('Specific Course', style: TextStyle(color: USGATheme.adaptiveTextPrimary(_themeManager.isDarkMode))),
                subtitle: Text('Golf course location', style: TextStyle(color: USGATheme.adaptiveTextSecondary(_themeManager.isDarkMode))),
                value: LocationMode.course,
                groupValue: _locationMode,
                activeColor: USGATheme.primaryNavy,
                onChanged: (value) {
                  if (value != null) {
                    _resetLocationFields();
                    setState(() => _locationMode = value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationFields() {
    if (_loadingCounties || _loadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State selection (required for both modes)
        const Text(
          'State *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: USGATheme.textPrimary,
          ),
        ),
        const SizedBox(height: USGATheme.spacingXs),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            return _states
                .where((state) => state.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                .toList();
          },
          onSelected: (state) {
            setState(() {
              _selectedState = state;
              _updateFilteredCounties();
              _selectedCounties.clear();
              _selectedCourse = '';
              _selectedCity = '';
              _courseController.clear();
              _cityController.clear();
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Select state',
                prefixIcon: Icon(Icons.map),
              ),
            );
          },
        ),

        if (_selectedState != null) ...[
          const SizedBox(height: USGATheme.spacingMd),

          // County selection (required for both modes)
          const Text(
            'County *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: USGATheme.textPrimary,
            ),
          ),
          const SizedBox(height: USGATheme.spacingXs),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              return _filteredCounties
                  .where((county) => county.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                  .toList();
            },
            onSelected: (county) {
              setState(() {
                _selectedCounties.clear();
                _selectedCounties.add(county);
                if (_locationMode == LocationMode.course) {
                  _selectedCourse = '';
                  _courseController.clear();
                }
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'Select county',
                  prefixIcon: Icon(Icons.location_on),
                ),
              );
            },
          ),

          if (_selectedCounties.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: USGATheme.spacingXs),
              child: Wrap(
                spacing: 8,
                children: _selectedCounties.map((county) {
                  return Chip(
                    label: Text(county),
                    onDeleted: () => setState(() => _selectedCounties.remove(county)),
                  );
                }).toList(),
              ),
            ),

          // Course mode specific fields
          if (_locationMode == LocationMode.course && _selectedCounties.isNotEmpty) ...[
            const SizedBox(height: USGATheme.spacingMd),

            // City selection
            const Text(
              'City *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: USGATheme.textPrimary,
              ),
            ),
            const SizedBox(height: USGATheme.spacingXs),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final cities = _getFilteredCities();
                return cities
                    .where((city) => city.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                    .toList();
              },
              onSelected: (city) {
                setState(() {
                  _selectedCity = city;
                  _cityController.text = city;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: _cityController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Select or enter city',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  onChanged: (value) {
                    setState(() => _selectedCity = value);
                  },
                );
              },
            ),

            const SizedBox(height: USGATheme.spacingMd),

            // Course selection
            const Text(
              'Golf Course *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: USGATheme.textPrimary,
              ),
            ),
            const SizedBox(height: USGATheme.spacingXs),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return _getFilteredCourses(textEditingValue.text);
              },
              onSelected: (course) {
                setState(() {
                  _selectedCourse = course;
                  _courseController.text = course;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: _courseController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Search courses or enter custom name',
                    prefixIcon: Icon(Icons.golf_course),
                  ),
                  onChanged: (value) {
                    setState(() => _selectedCourse = value);
                  },
                );
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildScheduleModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: USGATheme.textPrimary,
          ),
        ),
        const SizedBox(height: USGATheme.spacingSm),
        Row(
          children: [
            Expanded(
              child: RadioListTile<ScheduleMode>(
                title: const Text('Specific Date'),
                value: ScheduleMode.specific,
                groupValue: _scheduleMode,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _scheduleMode = value);
                  }
                },
              ),
            ),
            Expanded(
              child: RadioListTile<ScheduleMode>(
                title: const Text('Flexible Days'),
                value: ScheduleMode.flexible,
                groupValue: _scheduleMode,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _scheduleMode = value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleFields() {
    if (_scheduleMode == ScheduleMode.specific) {
      return Column(
        children: [
          _buildDatePicker(),
          const SizedBox(height: USGATheme.spacingMd),
          _buildTimePicker(),
        ],
      );
    } else {
      return _buildDaySelector();
    }
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(USGATheme.spacingMd),
        decoration: BoxDecoration(
          color: USGATheme.surfaceGray,
          borderRadius: BorderRadius.circular(USGATheme.radiusMd),
          border: Border.all(color: USGATheme.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: USGATheme.textSecondary),
            const SizedBox(width: USGATheme.spacingSm),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                    : 'Select Date',
                style: TextStyle(
                  color: _selectedDate != null ? USGATheme.textPrimary : USGATheme.textTertiary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
        );
        if (picked != null && picked != _selectedTime) {
          setState(() => _selectedTime = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(USGATheme.spacingMd),
        decoration: BoxDecoration(
          color: USGATheme.surfaceGray,
          borderRadius: BorderRadius.circular(USGATheme.radiusMd),
          border: Border.all(color: USGATheme.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: USGATheme.textSecondary),
            const SizedBox(width: USGATheme.spacingSm),
            Expanded(
              child: Text(
                _selectedTime != null
                    ? _formatTimeOfDay(_selectedTime!)
                    : 'Select Time',
                style: TextStyle(
                  color: _selectedTime != null ? USGATheme.textPrimary : USGATheme.textTertiary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Days',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: USGATheme.textPrimary,
          ),
        ),
        const SizedBox(height: USGATheme.spacingSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _daysOfWeek.map((day) {
            final isSelected = _selectedDaysOfWeek.contains(day);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDaysOfWeek.remove(day);
                  } else {
                    _selectedDaysOfWeek.add(day);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: USGATheme.spacingSm,
                  vertical: USGATheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? USGATheme.accentGold : USGATheme.surfaceGray,
                  borderRadius: BorderRadius.circular(USGATheme.radiusSm),
                  border: Border.all(
                    color: isSelected ? USGATheme.accentGold : USGATheme.borderLight,
                  ),
                ),
                child: Text(
                  day.substring(0, 3),
                  style: TextStyle(
                    color: isSelected ? Colors.white : USGATheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: USGATheme.textPrimary,
          ),
        ),
        const SizedBox(height: USGATheme.spacingSm),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add any additional details about the match...',
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsToggles() {
    return Column(
      children: [
        _buildToggleTile(
          title: 'Private Match',
          subtitle: 'Only invited players can join',
          value: _isPrivate,
          onChanged: (value) => setState(() => _isPrivate = value),
          icon: Icons.lock,
        ),
        const SizedBox(height: USGATheme.spacingSm),
        _buildToggleTile(
          title: 'Handicap Required',
          subtitle: 'Players must have official handicap',
          value: _handicapRequired,
          onChanged: (value) => setState(() => _handicapRequired = value),
          icon: Icons.sports_golf,
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(USGATheme.spacingMd),
      decoration: BoxDecoration(
        color: USGATheme.surfaceGray,
        borderRadius: BorderRadius.circular(USGATheme.radiusMd),
        border: Border.all(color: USGATheme.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: USGATheme.textSecondary, size: 24),
          const SizedBox(width: USGATheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: USGATheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: USGATheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: USGATheme.primaryNavy,
          ),
        ],
      ),
    );
  }

  Widget _buildTeammateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Teammate',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: USGATheme.textPrimary,
          ),
        ),
        const SizedBox(height: USGATheme.spacingXs),
        const Text(
          'Search by name, email, or phone number to find your teammate',
          style: TextStyle(
            fontSize: 12,
            color: USGATheme.textSecondary,
          ),
        ),
        const SizedBox(height: USGATheme.spacingSm),
        
        // Search field
        TextFormField(
          controller: _teammateController,
          decoration: InputDecoration(
            hintText: 'Search for teammate...',
            prefixIcon: const Icon(Icons.search, color: USGATheme.textSecondary),
            suffixIcon: _selectedTeammate != null
                ? IconButton(
                    icon: const Icon(Icons.clear, color: USGATheme.textSecondary),
                    onPressed: _clearTeammateSelection,
                  )
                : null,
          ),
          onChanged: _searchTeammates,
        ),
        
        // Search results
        if (_searchingTeammates)
          const Padding(
            padding: EdgeInsets.all(USGATheme.spacingSm),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        
        if (_searchedTeammates.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: USGATheme.spacingXs),
            decoration: BoxDecoration(
              color: USGATheme.surfaceGray,
              borderRadius: BorderRadius.circular(USGATheme.radiusMd),
              border: Border.all(color: USGATheme.borderLight),
            ),
            child: Column(
              children: _searchedTeammates.take(5).map((teammate) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: USGATheme.primaryNavy,
                    child: Text(
                      PrivacyUtils.getInitials(teammate['full_name']),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    teammate['full_name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: USGATheme.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (teammate['email'] != null)
                        Text(
                          teammate['email'],
                          style: const TextStyle(fontSize: 12, color: USGATheme.textSecondary),
                        ),
                      if (teammate['phone'] != null)
                        Text(
                          teammate['phone'],
                          style: const TextStyle(fontSize: 12, color: USGATheme.textSecondary),
                        ),
                      if (teammate['handicap'] != null)
                        Text(
                          'Handicap: ${teammate['handicap']}',
                          style: const TextStyle(fontSize: 12, color: USGATheme.textTertiary),
                        ),
                    ],
                  ),
                  onTap: () => _selectTeammate(teammate),
                );
              }).toList(),
            ),
          ),
        
        // Selected teammate display
        if (_selectedTeammate != null)
          Container(
            margin: const EdgeInsets.only(top: USGATheme.spacingSm),
            padding: const EdgeInsets.all(USGATheme.spacingMd),
            decoration: BoxDecoration(
              color: USGATheme.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(USGATheme.radiusMd),
              border: Border.all(color: USGATheme.accentGold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: USGATheme.accentGold, size: 20),
                const SizedBox(width: USGATheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected: ${_selectedTeammate!['full_name'] ?? 'Unknown'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: USGATheme.textPrimary,
                        ),
                      ),
                      if (_selectedTeammate!['email'] != null)
                        Text(
                          _selectedTeammate!['email'],
                          style: const TextStyle(fontSize: 12, color: USGATheme.textSecondary),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: USGATheme.textSecondary, size: 20),
                  onPressed: _clearTeammateSelection,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
