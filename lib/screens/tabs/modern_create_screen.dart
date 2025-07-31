import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/usga_theme.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  String _matchType = 'Match Play';
  String _matchMode = 'Single';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _location = '';
  String? _selectedTeammateId;
  String _notes = '';
  bool _isPrivate = false;
  bool _handicapRequired = false;
  
  final _locationController = TextEditingController();
  final _teammateController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;

  final List<String> _matchTypes = ['Match Play', 'Stroke Play'];
  final List<String> _matchModes = ['Single', 'Duo'];

  @override
  void dispose() {
    _locationController.dispose();
    _teammateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDateTime() {
    if (_selectedDate == null) return 'Select date and time';
    
    final dateStr = '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    final timeStr = _selectedTime != null 
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : 'Select time';
    
    return '$dateStr at $timeStr';
  }

  Future<void> _submitMatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showErrorSnackBar('Please select a date for the match');
      return;
    }

    if (_selectedTime == null) {
      _showErrorSnackBar('Please select a time for the match');
      return;
    }

    if (_location.trim().isEmpty) {
      _showErrorSnackBar('Please enter a location');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Combine date and time
      final matchDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final matchData = {
        'creator_id': userId,
        'match_type': _matchType,
        'match_mode': _matchMode,
        'match_date': matchDateTime.toIso8601String(),
        'location': _location.trim(),
        'teammate_id': _selectedTeammateId,
        'notes': _notes.trim().isEmpty ? null : _notes.trim(),
        'is_private': _isPrivate,
        'handicap_required': _handicapRequired,
        'status': 'open',
      };

      await Supabase.instance.client
          .from('matches')
          .insert(matchData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match created successfully!'),
            backgroundColor: USGATheme.success,
          ),
        );
        
        // Reset form
        _resetForm();
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Error creating match: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _matchType = 'Match Play';
      _matchMode = 'Single';
      _selectedDate = null;
      _selectedTime = null;
      _location = '';
      _selectedTeammateId = null;
      _notes = '';
      _isPrivate = false;
      _handicapRequired = false;
    });
    
    _locationController.clear();
    _teammateController.clear();
    _notesController.clear();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: USGATheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: USGATheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Create Match'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(USGATheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match Type Section
              USGATheme.sectionHeader('Match Details'),
              USGATheme.modernCard(
                child: Column(
                  children: [
                    _buildMatchTypeSelector(),
                    const SizedBox(height: USGATheme.spacingMd),
                    _buildMatchModeSelector(),
                  ],
                ),
              ),
              
              const SizedBox(height: USGATheme.spacingLg),
              
              // Date & Time Section
              USGATheme.sectionHeader('Schedule'),
              USGATheme.modernCard(
                child: Column(
                  children: [
                    _buildDateTimeSelector(),
                  ],
                ),
              ),
              
              const SizedBox(height: USGATheme.spacingLg),
              
              // Location Section
              USGATheme.sectionHeader('Location'),
              USGATheme.modernCard(
                child: _buildLocationInput(),
              ),
              
              const SizedBox(height: USGATheme.spacingLg),
              
              // Additional Options
              USGATheme.sectionHeader('Options'),
              USGATheme.modernCard(
                child: Column(
                  children: [
                    _buildNotesInput(),
                    const SizedBox(height: USGATheme.spacingMd),
                    _buildOptionsToggles(),
                  ],
                ),
              ),
              
              const SizedBox(height: USGATheme.spacing2xl),
              
              // Create Button
              USGATheme.modernButton(
                text: _isLoading ? 'Creating Match...' : 'Create Match',
                onPressed: _isLoading ? () {} : _submitMatch,
                isFullWidth: true,
                isPrimary: true,
              ),
              
              const SizedBox(height: USGATheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Type',
          style: Theme.of(context).textTheme.titleMedium,
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
                      color: isSelected 
                          ? USGATheme.primaryNavy 
                          : USGATheme.surfaceGray,
                      borderRadius: BorderRadius.circular(USGATheme.radiusMd),
                      border: Border.all(
                        color: isSelected 
                            ? USGATheme.primaryNavy 
                            : USGATheme.borderLight,
                      ),
                    ),
                    child: Text(
                      type,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white 
                            : USGATheme.textPrimary,
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
          style: Theme.of(context).textTheme.titleMedium,
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
                  onTap: () => setState(() => _matchMode = mode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: USGATheme.spacingMd,
                      vertical: USGATheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? USGATheme.accentRed 
                          : USGATheme.surfaceGray,
                      borderRadius: BorderRadius.circular(USGATheme.radiusMd),
                      border: Border.all(
                        color: isSelected 
                            ? USGATheme.accentRed 
                            : USGATheme.borderLight,
                      ),
                    ),
                    child: Text(
                      mode,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white 
                            : USGATheme.textPrimary,
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

  Widget _buildDateTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: USGATheme.spacingSm),
        GestureDetector(
          onTap: () async {
            await _selectDate();
            if (_selectedDate != null && _selectedTime == null) {
              await _selectTime();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(USGATheme.spacingMd),
            decoration: BoxDecoration(
              color: USGATheme.surfaceGray,
              borderRadius: BorderRadius.circular(USGATheme.radiusMd),
              border: Border.all(color: USGATheme.borderLight),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: USGATheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: USGATheme.spacingSm),
                Expanded(
                  child: Text(
                    _formatDateTime(),
                    style: TextStyle(
                      color: _selectedDate != null 
                          ? USGATheme.textPrimary 
                          : USGATheme.textTertiary,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: USGATheme.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: USGATheme.spacingSm),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            hintText: 'Enter golf course or location',
            prefixIcon: Icon(Icons.location_on_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a location';
            }
            return null;
          },
          onChanged: (value) => _location = value,
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: USGATheme.spacingSm),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add any additional details about the match...',
          ),
          onChanged: (value) => _notes = value,
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
          icon: Icons.lock_rounded,
        ),
        const SizedBox(height: USGATheme.spacingSm),
        _buildToggleTile(
          title: 'Handicap Required',
          subtitle: 'Players must have official handicap',
          value: _handicapRequired,
          onChanged: (value) => setState(() => _handicapRequired = value),
          icon: Icons.sports_golf_rounded,
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
          Icon(
            icon,
            color: USGATheme.textSecondary,
            size: 24,
          ),
          const SizedBox(width: USGATheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
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
}
