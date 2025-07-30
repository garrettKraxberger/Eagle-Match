class UserProfile {
  final String id;
  final String? fullName;
  final int? age;
  final double? handicap;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.fullName,
    this.age,
    this.handicap,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      age: json['age'] as int?,
      handicap: json['handicap'] != null ? double.parse(json['handicap'].toString()) : null,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'age': age,
      'handicap': handicap,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
