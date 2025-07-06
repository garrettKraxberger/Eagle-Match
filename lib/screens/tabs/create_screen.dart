import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum LocationMode { counties, course }

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
  String _handicap = '';
  String _matchMode = 'Single';
  String _selectedTeammate = '';
  final _notesController = TextEditingController();

  final List<String> _matchTypes = ['Match Play', 'Stroke Play'];
  LocationMode _locationMode = LocationMode.counties;

  Map<String, int> _courseMap = {};
  Map<String, int> _countyMap = {};
  List<String> _courses = [];

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
          .select('id, name')
          .order('name');
      setState(() {
        _courses = data.map<String>((e) => e['name'] as String).toList();
        _courseMap = {for (var e in data) e['name']: e['id']};
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
        countyMap[full] = row['id'];
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

    final locationIds = _locationMode == LocationMode.counties
        ? _selectedCounties
            .map((c) => _countyMap['$c, $_selectedState'])
            .whereType<int>()
            .toList()
        : [_courseMap[_selectedCourse]].whereType<int>().toList();

    final response = await Supabase.instance.client.from('matches').insert({
      'match_type': _matchType,
      'location_mode': _locationMode.name,
      'location_ids': locationIds,
      'match_mode': _matchMode,
      'handicap': _handicap,
      'is_private': _isPrivate,
      'notes': _notesController.text,
      'date': _selectedDate?.toIso8601String(),
      'time': _selectedTime?.format(context),
      'teammate': _selectedTeammate.isNotEmpty ? _selectedTeammate : null,
    });

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.error!.message}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match posted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Match')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _matchType,
              items: _matchTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => _matchType = value!),
              decoration: const InputDecoration(labelText: 'Match Type'),
            ),
            const SizedBox(height: 16),
            const Text('Select Location Mode:'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<LocationMode>(
                    title: const Text('Choose Counties'),
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
                    title: const Text('Choose Course'),
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
            const SizedBox(height: 8),
            if (_loadingCounties || _loadingCourses)
              const CircularProgressIndicator()
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
                      border: OutlineInputBorder(),
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
                    if (_locationMode == LocationMode.counties) {
                      _selectedCounties.add(county);
                    } else {
                      _selectedCounties = {county};
                    }
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Search/Add County',
                      border: OutlineInputBorder(),
                      hintText: 'Type to search counties...'
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              if (_locationMode == LocationMode.counties)
                Wrap(
                  spacing: 8,
                  children: _selectedCounties.map((c) {
                    return Chip(
                      label: Text(c),
                      onDeleted: () => setState(() => _selectedCounties.remove(c)),
                    );
                  }).toList(),
                ),
              if (_locationMode == LocationMode.course)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _courseController,
                      decoration: const InputDecoration(
                        labelText: 'Course Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => _selectedCourse = val),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitMatch,
              child: const Text('Post Match'),
            )
          ],
        ),
      ),
    );
  }
}
