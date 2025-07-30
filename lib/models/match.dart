class Match {
  final String id;
  final String creatorId;
  final String matchType;
  final String matchMode;
  final String locationMode;
  final List<int> locationIds;
  final String? customCourseName; // For user-entered course names
  final String? customCourseCity; // For user-entered course cities  
  final String scheduleMode;
  final DateTime? date;
  final String? time;
  final List<String>? daysOfWeek;
  final bool handicapRequired;
  final bool isPrivate;
  final String? notes;
  final String? teammate;
  final String? teammateId;
  final List<String>? participants;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Match({
    required this.id,
    required this.creatorId,
    required this.matchType,
    required this.matchMode,
    required this.locationMode,
    required this.locationIds,
    this.customCourseName,
    this.customCourseCity,
    required this.scheduleMode,
    this.date,
    this.time,
    this.daysOfWeek,
    required this.handicapRequired,
    required this.isPrivate,
    this.notes,
    this.teammate,
    this.teammateId,
    this.participants,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      matchType: json['match_type'] as String,
      matchMode: json['match_mode'] as String,
      locationMode: json['location_mode'] as String,
      locationIds: List<int>.from(json['location_ids'] ?? []),
      customCourseName: json['custom_course_name'] as String?,
      customCourseCity: json['custom_course_city'] as String?,
      scheduleMode: json['schedule_mode'] as String,
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      time: json['time'] as String?,
      daysOfWeek: json['days_of_week'] != null ? List<String>.from(json['days_of_week']) : null,
      handicapRequired: json['handicap_required'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      notes: json['notes'] as String?,
      teammate: json['teammate'] as String?,
      teammateId: json['teammate_id'] as String?,
      participants: json['participants'] != null ? List<String>.from(json['participants']) : null,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'match_type': matchType,
      'match_mode': matchMode,
      'location_mode': locationMode,
      'location_ids': locationIds,
      'custom_course_name': customCourseName,
      'custom_course_city': customCourseCity,
      'schedule_mode': scheduleMode,
      'date': date?.toIso8601String(),
      'time': time,
      'days_of_week': daysOfWeek,
      'handicap_required': handicapRequired,
      'is_private': isPrivate,
      'notes': notes,
      'teammate': teammate,
      'teammate_id': teammateId,
      'participants': participants,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
