class Chat {
  final String id;
  final String userId1;
  final String userId2;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      userId1: json['user_id1'] as String,
      userId2: json['user_id2'] as String,
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
      'user_id1': userId1,
      'user_id2': userId2,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

