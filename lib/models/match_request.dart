class MatchRequest {
  final String id;
  final String matchId;
  final String requesterId;
  final String requestType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MatchRequest({
    required this.id,
    required this.matchId,
    required this.requesterId,
    required this.requestType,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatchRequest.fromJson(Map<String, dynamic> json) {
    return MatchRequest(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      requesterId: json['requester_id'] as String,
      requestType: json['request_type'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'requester_id': requesterId,
      'request_type': requestType,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
