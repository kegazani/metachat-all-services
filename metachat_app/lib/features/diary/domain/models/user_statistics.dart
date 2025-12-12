class UserStatistics {
  final int totalDiaryEntries;
  final int totalMoodAnalyses;
  final int totalTokens;
  final String dominantEmotion;
  final List<String> topTopics;
  final DateTime profileCreatedAt;
  final DateTime lastPersonalityUpdate;

  UserStatistics({
    required this.totalDiaryEntries,
    required this.totalMoodAnalyses,
    required this.totalTokens,
    required this.dominantEmotion,
    required this.topTopics,
    required this.profileCreatedAt,
    required this.lastPersonalityUpdate,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalDiaryEntries: json['total_diary_entries'] as int? ?? 0,
      totalMoodAnalyses: json['total_mood_analyses'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
      dominantEmotion: json['dominant_emotion'] as String? ?? '',
      topTopics: (json['top_topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      profileCreatedAt: json['profile_created_at'] != null
          ? DateTime.parse(json['profile_created_at'] as String)
          : DateTime.now(),
      lastPersonalityUpdate: json['last_personality_update'] != null
          ? DateTime.parse(json['last_personality_update'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_diary_entries': totalDiaryEntries,
      'total_mood_analyses': totalMoodAnalyses,
      'total_tokens': totalTokens,
      'dominant_emotion': dominantEmotion,
      'top_topics': topTopics,
      'profile_created_at': profileCreatedAt.toIso8601String(),
      'last_personality_update': lastPersonalityUpdate.toIso8601String(),
    };
  }
}

