import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/usga_theme.dart';

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
  bool _isPrivate = false;
  String _matchMode = 'Single';
  String? _selectedTeammateId;
  Map<String, dynamic>? _selectedTeammateProfile;
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

  Map<String, int> _courseMap = {};
  Map<String, int> _countyMap = {};
  List<Map<String, dynamic>> _coursesData = []; // Store full course data with state info

  Map<String, List<String>> _stateToCounties = {};
  List<String> _states = [];
  String? _selectedState;
  List<String> _filteredCounties = [];
  Set<String> _selectedCounties = {};

  String _selectedCourse = '';
  final _courseController = TextEditingController();
  final _cityController = TextEditingController();

  bool _loadingCourses = true;
  bool _loadingCounties = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadCounties();
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
      final matchesSearch = name.toLowerCase().contains(searchText.toLowerCase());
      
      // If state is selected, filter by state
      if (_selectedState != null && _selectedState!.isNotEmpty) {
        final courseState = course['state'] as String?;
        return matchesSearch && courseState == _selectedState;
      }
      
      return matchesSearch;
    }).map((course) => course['name'] as String).toList();
    
    return filteredCourses;
  }

  Future<List<Map<String, dynamic>>> _searchTeammates(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final trimmedQuery = query.trim();
      
      // Search by email, phone, or full name for better user experience
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email, phone, profile_image_url')
          .or('email.ilike.%$trimmedQuery%,phone.ilike.%$trimmedQuery%,full_name.ilike.%$trimmedQuery%')
          .neq('id', Supabase.instance.client.auth.currentUser?.id) // Exclude current user
          .limit(10);
      
      return response.cast<Map<String, dynamic>>();
    } catch (error) {
      print('Error searching teammates: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching for teammates: $error')),
      );
      return [];
    }
  }

  void _resetLocationFields() {
    setState(() {
      _selectedState = null;
      _filteredCounties = [];
      _selectedCounties.clear();
      _selectedCourse = '';
      _courseController.clear();
      _cityController.clear();
    });
  }

  Future<void> _submitMatch() async {
    // Validate required fields
    if (_locationMode == LocationMode.counties && _selectedCounties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one county.')),
      );
      return;
    }

    if (_locationMode == LocationMode.course && _selectedCourse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a course name.')),
      );
      return;
    }

    if (_locationMode == LocationMode.course && _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a state for the course.')),
      );
      return;
    }

    if (_locationMode == LocationMode.course && _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a city for the course.')),
      );
      return;
    }

    if (_locationMode == LocationMode.course && _selectedCounties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a county for the course.')),
      );
      return;
    }

    if (_scheduleMode == ScheduleMode.specific && (_selectedDate == null || _selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both date and time for specific scheduling.')),
      );
      return;
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
              ? [_courseMap[_courseController.text] ?? -1] // -1 for custom courses
              : [-1]; // Custom course

      final matchData = {
        'match_type': _matchType,
        'match_mode': _matchMode,
        'location_mode': _locationMode.name,
        'location_ids': locationIds,
        'schedule_mode': _scheduleMode.name,
        'handicap_required': _handicapRequired,
        'is_private': _isPrivate,
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        'teammate_id': _matchMode == 'Duo' && _selectedTeammateId != null ? _selectedTeammateId : null,
        'participants': [], // Initialize empty participants array
        'status': 'active',
      };

      // Add schedule-specific fields
      if (_scheduleMode == ScheduleMode.specific) {
        matchData['date'] = _selectedDate?.toIso8601String().split('T')[0];
        matchData['time'] = _selectedTime?.format(context);
        matchData['days_of_week'] = null;
      } else {
        matchData['date'] = null;
        matchData['time'] = null;
        matchData['days_of_week'] = _selectedDaysOfWeek.toList();
      }

      // Add custom course info if needed
      if (_locationMode == LocationMode.course && !_courseMap.containsKey(_courseController.text)) {
        matchData['custom_course_name'] = _courseController.text;
        matchData['custom_course_city'] = _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null;
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
      setState(() {
        _matchType = 'Match Play';
        _matchMode = 'Single';
        _selectedDate = null;
        _selectedTime = null;
        _isPrivate = false;
        _handicapRequired = false;
        _selectedTeammateId = null;
        _selectedTeammateProfile = null;
        _scheduleMode = ScheduleMode.specific;
        _selectedDaysOfWeek.clear();
        _selectedCounties.clear();
        _selectedCourse = '';
        _selectedState = null;
        _filteredCounties.clear();
        _notesController.clear();
        _teammateController.clear();
        _courseController.clear();
        _cityController.clear();
      });

    } catch (error) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating match: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: USGATheme.backgroundWhite,
      appBar: AppBar(title: const Text('Create Match')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Match Details Section
          USGATheme.buildSectionHeader('Match Details'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: USGATheme.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: USGATheme.borderLight),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _matchType,
                  items: _matchTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _matchType = value!),
                  decoration: const InputDecoration(
                    labelText: 'Match Type',
                    prefixIcon: Icon(Icons.sports_golf),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _matchMode,
                  items: _matchModes
                      .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                      .toList(),
                  onChanged: (value) => setState(() => _matchMode = value!),
                  decoration: const InputDecoration(
                    labelText: 'Match Mode',
                    prefixIcon: Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Handicap Required'),
                  subtitle: const Text('Players must have established handicaps'),
                  value: _handicapRequired,
                  onChanged: (value) => setState(() => _handicapRequired = value),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Teammate Selection (only show if Duo mode)
          if (_matchMode == 'Duo') ...[
            USGATheme.buildSectionHeader('Teammate Selection'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: USGATheme.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: USGATheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Teammate',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Search by email, phone number, or name to find and link teammate accounts',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedTeammateProfile != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: USGATheme.primaryNavy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: USGATheme.primaryNavy.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          _selectedTeammateProfile!['profile_image_url'] != null
                              ? CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(_selectedTeammateProfile!['profile_image_url']),
                                  backgroundColor: USGATheme.primaryNavy,
                                  onBackgroundImageError: (exception, stackTrace) {},
                                )
                              : CircleAvatar(
                                  radius: 20,
                                  backgroundColor: USGATheme.primaryNavy,
                                  child: Text(
                                    (_selectedTeammateProfile!['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _selectedTeammateProfile!['full_name'] ?? 'Unknown User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: USGATheme.primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'LINKED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_selectedTeammateProfile!['email'] != null)
                                  Text(
                                    _selectedTeammateProfile!['email'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                if (_selectedTeammateProfile!['phone'] != null)
                                  Text(
                                    _selectedTeammateProfile!['phone'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _selectedTeammateId = null;
                                _selectedTeammateProfile = null;
                                _teammateController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.length < 3) return const Iterable<Map<String, dynamic>>.empty();
                        return await _searchTeammates(textEditingValue.text);
                      },
                      displayStringForOption: (Map<String, dynamic> option) {
                        return option['full_name'] ?? 'Unknown User';
                      },
                      onSelected: (Map<String, dynamic> selection) {
                        setState(() {
                          _selectedTeammateId = selection['id'];
                          _selectedTeammateProfile = selection;
                        });
                        
                        // Show success feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Teammate linked: ${selection['full_name'] ?? 'Unknown User'}'),
                            backgroundColor: USGATheme.primaryNavy,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        _teammateController.text = controller.text;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Search Teammate',
                            hintText: 'Enter email, phone, or name',
                            prefixIcon: Icon(Icons.search),
                            helperText: 'Type at least 3 characters to search registered users',
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: SizedBox(
                              height: 200.0,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8.0),
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final Map<String, dynamic> option = options.elementAt(index);
                                  return GestureDetector(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: ListTile(
                                      leading: option['profile_image_url'] != null
                                          ? CircleAvatar(
                                              backgroundImage: NetworkImage(option['profile_image_url']),
                                              backgroundColor: USGATheme.primaryNavy,
                                              onBackgroundImageError: (exception, stackTrace) {},
                                              child: option['profile_image_url'] == null 
                                                  ? Text(
                                                      (option['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                                                      style: const TextStyle(color: Colors.white),
                                                    )
                                                  : null,
                                            )
                                          : CircleAvatar(
                                              backgroundColor: USGATheme.primaryNavy,
                                              child: Text(
                                                (option['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                      title: Text(
                                        option['full_name'] ?? 'Unknown User',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (option['email'] != null)
                                            Text(
                                              'Email: ${option['email']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          if (option['phone'] != null)
                                            Text(
                                              'Phone: ${option['phone']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.add_circle_outline,
                                        color: USGATheme.primaryNavy,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Schedule Section
          USGATheme.buildSectionHeader('Schedule'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: USGATheme.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: USGATheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<ScheduleMode>(
                        title: const Text('Specific Date'),
                        value: ScheduleMode.specific,
                        groupValue: _scheduleMode,
                        onChanged: (value) => setState(() => _scheduleMode = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<ScheduleMode>(
                        title: const Text('Flexible'),
                        value: ScheduleMode.flexible,
                        groupValue: _scheduleMode,
                        onChanged: (value) => setState(() => _scheduleMode = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_scheduleMode == ScheduleMode.specific) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date',
                            hintText: _selectedDate?.toString().split(' ')[0] ?? 'Select date',
                            prefixIcon: const Icon(Icons.calendar_today),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Time',
                            hintText: _selectedTime?.format(context) ?? 'Select time',
                            prefixIcon: const Icon(Icons.access_time),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() => _selectedTime = time);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Available Days',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _daysOfWeek.map((day) {
                      final isSelected = _selectedDaysOfWeek.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDaysOfWeek.add(day);
                            } else {
                              _selectedDaysOfWeek.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Location Section
          USGATheme.buildSectionHeader('Location'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: USGATheme.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: USGATheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<LocationMode>(
                        title: const Text('Counties'),
                        value: LocationMode.counties,
                        groupValue: _locationMode,
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
                        title: const Text('Specific Course'),
                        value: LocationMode.course,
                        groupValue: _locationMode,
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
                const SizedBox(height: 16),
                if (_locationMode == LocationMode.counties) ...[
                  if (_loadingCounties)
                    const Center(child: CircularProgressIndicator())
                  else ...[
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
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Search for State',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          onChanged: (val) {
                            setState(() => _selectedState = val);
                          },
                          onFieldSubmitted: (val) {
                            setState(() {
                              _selectedState = val;
                              _updateFilteredCounties();
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (_selectedState == null) return const Iterable<String>.empty();
                        return _filteredCounties
                            .where((county) => county.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                            .toList();
                      },
                      onSelected: (county) {
                        setState(() {
                          _selectedCounties.add(county);
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Search Counties',
                            hintText: 'Type to search counties...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_selectedCounties.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: _selectedCounties.map((county) {
                          return Chip(
                            label: Text(county),
                            onDeleted: () => setState(() => _selectedCounties.remove(county)),
                          );
                        }).toList(),
                      ),
                  ],
                ] else ...[
                  if (_loadingCourses)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: USGATheme.primaryNavy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: USGATheme.primaryNavy.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: USGATheme.primaryNavy, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Course name, state, county, and city are required fields.',
                              style: TextStyle(
                                color: USGATheme.primaryNavy,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // State filter for courses
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
                          // Clear course selection when state changes
                          _selectedCourse = '';
                          _courseController.clear();
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'State *',
                            hintText: 'Select state for the course',
                            prefixIcon: Icon(Icons.map),
                          ),
                          onChanged: (val) {
                            setState(() => _selectedState = val);
                          },
                          onFieldSubmitted: (val) {
                            setState(() {
                              _selectedState = val;
                              _updateFilteredCounties();
                              _selectedCourse = '';
                              _courseController.clear();
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // County selection for courses (required when state is selected)
                    if (_selectedState != null) ...[
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
                            // Clear course selection when county changes
                            _selectedCourse = '';
                            _courseController.clear();
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'County *',
                              hintText: 'Select county for the course',
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            onFieldSubmitted: (val) {
                              if (val.isNotEmpty && _filteredCounties.contains(val)) {
                                setState(() {
                                  _selectedCounties.clear();
                                  _selectedCounties.add(val);
                                  _selectedCourse = '';
                                  _courseController.clear();
                                });
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_selectedCounties.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: _selectedCounties.map((county) {
                            return Chip(
                              label: Text(county),
                              onDeleted: () => setState(() => _selectedCounties.remove(county)),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please select a state first to choose a county.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Course selection with filtered options
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
                        // Sync the controller with our course controller
                        if (controller.text != _courseController.text) {
                          controller.text = _courseController.text;
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Course Name *',
                            hintText: 'Search for a golf course or enter custom name',
                            prefixIcon: Icon(Icons.golf_course),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _selectedCourse = val;
                              _courseController.text = val;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        hintText: 'Enter the city where the course is located',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Additional Details Section
          USGATheme.buildSectionHeader('Additional Details'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: USGATheme.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: USGATheme.borderLight),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add any additional details about the match...',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Private Match'),
                  subtitle: const Text('Only you can invite players'),
                  value: _isPrivate,
                  onChanged: (value) => setState(() => _isPrivate = value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: USGATheme.accentRed,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: USGATheme.accentRed.withOpacity(0.3),
              ),
              child: const Text(
                'Create Match',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
