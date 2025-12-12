class MatchRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final List<String> commonTopics;
  final double similarity;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MatchRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.commonTopics,
    required this.similarity,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatchRequest.fromJson(Map<String, dynamic> json) {
    return MatchRequest(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      commonTopics: (json['common_topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'common_topics': commonTopics,
      'similarity': similarity,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
}

