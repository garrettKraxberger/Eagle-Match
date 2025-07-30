class Partnership {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? nickname;
  final bool isStarred;
  final int matchesPlayed;
  final int matchesWon;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Partnership({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.nickname,
    this.isStarred = false,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Partnership.fromJson(Map<String, dynamic> json) {
    return Partnership(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      nickname: json['nickname'] as String?,
      isStarred: json['is_starred'] as bool? ?? false,
      matchesPlayed: json['matches_played'] as int? ?? 0,
      matchesWon: json['matches_won'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'nickname': nickname,
      'is_starred': isStarred,
      'matches_played': matchesPlayed,
      'matches_won': matchesWon,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get the partner's ID (not current user)
  String getPartnerId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  // Helper method to calculate win percentage
  double get winPercentage {
    if (matchesPlayed == 0) return 0.0;
    return (matchesWon / matchesPlayed) * 100;
  }
}
