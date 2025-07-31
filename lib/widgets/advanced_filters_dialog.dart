import 'package:flutter/material.dart';
import '../theme/usga_theme.dart';

/// Advanced filter options for match search
class MatchFilters {
  String? skillLevel;
  String? playingStyle;
  String? courseType;
  String? groupSize;
  String? timePreference;
  DateTimeRange? dateRange;
  double? maxDistance;
  bool handicapRequired;
  bool privateMatches;

  MatchFilters({
    this.skillLevel,
    this.playingStyle,
    this.courseType,
    this.groupSize,
    this.timePreference,
    this.dateRange,
    this.maxDistance,
    this.handicapRequired = false,
    this.privateMatches = false,
  });

  /// Convert filters to Supabase query conditions
  Map<String, dynamic> toQueryConditions() {
    final conditions = <String, dynamic>{};
    
    if (skillLevel != null) conditions['skill_level'] = skillLevel;
    if (playingStyle != null) conditions['playing_style'] = playingStyle;
    if (courseType != null) conditions['course_type'] = courseType;
    if (groupSize != null) conditions['match_mode'] = groupSize;
    if (handicapRequired) conditions['handicap_required'] = true;
    if (!privateMatches) conditions['is_private'] = false;
    
    return conditions;
  }

  /// Check if any filters are applied
  bool get hasFilters {
    return skillLevel != null ||
           playingStyle != null ||
           courseType != null ||
           groupSize != null ||
           timePreference != null ||
           dateRange != null ||
           maxDistance != null ||
           handicapRequired ||
           privateMatches;
  }

  /// Clear all filters
  void clear() {
    skillLevel = null;
    playingStyle = null;
    courseType = null;
    groupSize = null;
    timePreference = null;
    dateRange = null;
    maxDistance = null;
    handicapRequired = false;
    privateMatches = false;
  }
}

/// Advanced filters dialog widget
class AdvancedFiltersDialog extends StatefulWidget {
  final MatchFilters initialFilters;
  final Function(MatchFilters) onFiltersChanged;

  const AdvancedFiltersDialog({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<AdvancedFiltersDialog> createState() => _AdvancedFiltersDialogState();
}

class _AdvancedFiltersDialogState extends State<AdvancedFiltersDialog> {
  late MatchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = MatchFilters(
      skillLevel: widget.initialFilters.skillLevel,
      playingStyle: widget.initialFilters.playingStyle,
      courseType: widget.initialFilters.courseType,
      groupSize: widget.initialFilters.groupSize,
      timePreference: widget.initialFilters.timePreference,
      dateRange: widget.initialFilters.dateRange,
      maxDistance: widget.initialFilters.maxDistance,
      handicapRequired: widget.initialFilters.handicapRequired,
      privateMatches: widget.initialFilters.privateMatches,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Advanced Filters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: USGATheme.primaryNavy,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkillLevelFilter(),
                    const SizedBox(height: 24),
                    _buildPlayingStyleFilter(),
                    const SizedBox(height: 24),
                    _buildCourseTypeFilter(),
                    const SizedBox(height: 24),
                    _buildGroupSizeFilter(),
                    const SizedBox(height: 24),
                    _buildTimePreferenceFilter(),
                    const SizedBox(height: 24),
                    _buildDateRangeFilter(),
                    const SizedBox(height: 24),
                    _buildToggleFilters(),
                  ],
                ),
              ),
            ),

            // Action buttons
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: USGATheme.modernButton(
                    text: 'Clear All',
                    onPressed: () {
                      setState(() {
                        _filters.clear();
                      });
                    },
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: USGATheme.modernButton(
                    text: 'Apply Filters',
                    onPressed: () {
                      widget.onFiltersChanged(_filters);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillLevelFilter() {
    return _buildFilterSection(
      'Skill Level',
      ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
      _filters.skillLevel,
      (value) => setState(() => _filters.skillLevel = value),
    );
  }

  Widget _buildPlayingStyleFilter() {
    return _buildFilterSection(
      'Playing Style',
      ['Competitive', 'Casual', 'Learning', 'Social'],
      _filters.playingStyle,
      (value) => setState(() => _filters.playingStyle = value),
    );
  }

  Widget _buildCourseTypeFilter() {
    return _buildFilterSection(
      'Course Type',
      ['Public', 'Private', 'Resort', 'Municipal'],
      _filters.courseType,
      (value) => setState(() => _filters.courseType = value),
    );
  }

  Widget _buildGroupSizeFilter() {
    return _buildFilterSection(
      'Group Size',
      ['Single', 'Duo', 'Threesome', 'Foursome'],
      _filters.groupSize,
      (value) => setState(() => _filters.groupSize = value),
    );
  }

  Widget _buildTimePreferenceFilter() {
    return _buildFilterSection(
      'Time Preference',
      ['Early Morning', 'Morning', 'Afternoon', 'Evening', 'Weekend Only'],
      _filters.timePreference,
      (value) => setState(() => _filters.timePreference = value),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: USGATheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return GestureDetector(
              onTap: () => onChanged(isSelected ? null : option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? USGATheme.primaryNavy : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? USGATheme.primaryNavy : USGATheme.borderMedium,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : USGATheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: USGATheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final dateRange = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: _filters.dateRange,
            );
            if (dateRange != null) {
              setState(() {
                _filters.dateRange = dateRange;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: USGATheme.borderMedium),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, color: USGATheme.textSecondary),
                const SizedBox(width: 12),
                Text(
                  _filters.dateRange != null
                      ? '${_formatDate(_filters.dateRange!.start)} - ${_formatDate(_filters.dateRange!.end)}'
                      : 'Select date range',
                  style: TextStyle(
                    color: _filters.dateRange != null
                        ? USGATheme.textPrimary
                        : USGATheme.textSecondary,
                  ),
                ),
                const Spacer(),
                if (_filters.dateRange != null)
                  GestureDetector(
                    onTap: () => setState(() => _filters.dateRange = null),
                    child: Icon(Icons.clear, color: USGATheme.textSecondary, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleFilters() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Handicap Required'),
          subtitle: const Text('Only show matches that require a handicap'),
          value: _filters.handicapRequired,
          onChanged: (value) => setState(() => _filters.handicapRequired = value ?? false),
          activeColor: USGATheme.primaryNavy,
        ),
        CheckboxListTile(
          title: const Text('Include Private Matches'),
          subtitle: const Text('Show private/invite-only matches'),
          value: _filters.privateMatches,
          onChanged: (value) => setState(() => _filters.privateMatches = value ?? false),
          activeColor: USGATheme.primaryNavy,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
