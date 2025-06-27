import 'package:flutter/material.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  String _matchType = 'Match Play';
  String _course = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isPrivate = false;
  String _handicap = '';
  String _matchMode = 'Single';
  String _selectedTeammate = '';
  final _notesController = TextEditingController();

  final List<String> _matchTypes = ['Match Play', 'Stroke Play'];
  final List<String> _courses = ['Pebble Beach', 'Augusta', 'TPC Scottsdale'];
  final List<String> _starredDuos = ['Teammate A', 'Teammate B', 'Teammate C'];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submitMatch() {
    // TODO: Validate and submit match details to Supabase or backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Match posted successfully!')),
    );
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
            DropdownButtonFormField<String>(
              value: _course.isEmpty ? null : _course,
              items: _courses
                  .map((course) => DropdownMenuItem(value: course, child: Text(course)))
                  .toList(),
              onChanged: (value) => setState(() => _course = value ?? ''),
              decoration: const InputDecoration(labelText: 'Course'),
            ),
            ListTile(
              title: Text(_selectedDate == null
                  ? 'Pick Date'
                  : 'Date: ${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            ListTile(
              title: Text(_selectedTime == null
                  ? 'Pick Time'
                  : 'Time: ${_selectedTime!.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            SwitchListTile(
              title: const Text('Private Match'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Handicap Required (Optional)'),
              onChanged: (value) => _handicap = value,
            ),
            DropdownButtonFormField<String>(
              value: _matchMode,
              items: ['Single', 'Duo']
                  .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                  .toList(),
              onChanged: (value) => setState(() => _matchMode = value!),
              decoration: const InputDecoration(labelText: 'Match Mode'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedTeammate.isEmpty ? null : _selectedTeammate,
              items: _starredDuos
                  .map((teammate) =>
                      DropdownMenuItem(value: teammate, child: Text(teammate)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedTeammate = value ?? ''),
              decoration: const InputDecoration(labelText: 'Invite Teammate (Optional)'),
            ),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitMatch,
              child: const Text('Post Match'),
            ),
          ],
        ),
      ),
    );
  }
}