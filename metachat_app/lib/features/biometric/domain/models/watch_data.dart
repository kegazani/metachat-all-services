class WatchData {
  final String? deviceId;
  final String? deviceType;
  final double? heartRate;
  final double? heartRateVariability;
  final double? restingHeartRate;
  final double? bloodOxygen;
  final double? respiratoryRate;
  final double? bodyTemperature;
  final int? stressLevel;
  final int? energyLevel;
  final SleepData? sleepData;
  final ActivityData? activity;
  final DateTime? recordedAt;

  WatchData({
    this.deviceId,
    this.deviceType,
    this.heartRate,
    this.heartRateVariability,
    this.restingHeartRate,
    this.bloodOxygen,
    this.respiratoryRate,
    this.bodyTemperature,
    this.stressLevel,
    this.energyLevel,
    this.sleepData,
    this.activity,
    this.recordedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (deviceId != null) 'device_id': deviceId,
      if (deviceType != null) 'device_type': deviceType,
      if (heartRate != null) 'heart_rate': heartRate,
      if (heartRateVariability != null) 'heart_rate_variability': heartRateVariability,
      if (restingHeartRate != null) 'resting_heart_rate': restingHeartRate,
      if (bloodOxygen != null) 'blood_oxygen': bloodOxygen,
      if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
      if (bodyTemperature != null) 'body_temperature': bodyTemperature,
      if (stressLevel != null) 'stress_level': stressLevel,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (sleepData != null) 'sleep_data': sleepData!.toJson(),
      if (activity != null) 'activity': activity!.toJson(),
      'recorded_at': (recordedAt ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }
}

class SleepData {
  final int? totalSleepMinutes;
  final int? timeInBedMinutes;
  final double? sleepEfficiency;
  final int? sleepScore;
  final List<SleepSegment>? segments;

  SleepData({
    this.totalSleepMinutes,
    this.timeInBedMinutes,
    this.sleepEfficiency,
    this.sleepScore,
    this.segments,
  });

  Map<String, dynamic> toJson() {
    return {
      if (totalSleepMinutes != null) 'total_sleep_minutes': totalSleepMinutes,
      if (timeInBedMinutes != null) 'time_in_bed_minutes': timeInBedMinutes,
      if (sleepEfficiency != null) 'sleep_efficiency': sleepEfficiency,
      if (sleepScore != null) 'sleep_score': sleepScore,
      if (segments != null) 'segments': segments!.map((s) => s.toJson()).toList(),
    };
  }

  factory SleepData.fromJson(Map<String, dynamic> json) {
    return SleepData(
      totalSleepMinutes: json['total_sleep_minutes'] as int?,
      timeInBedMinutes: json['time_in_bed_minutes'] as int?,
      sleepEfficiency: (json['sleep_efficiency'] as num?)?.toDouble(),
      sleepScore: json['sleep_score'] as int?,
    );
  }
}

class SleepSegment {
  final String stage;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  SleepSegment({
    required this.stage,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
    };
  }
}

class ActivityData {
  final int? steps;
  final double? distanceMeters;
  final double? caloriesBurned;
  final int? activeMinutes;
  final int? floorsClimbed;
  final String? activityType;

  ActivityData({
    this.steps,
    this.distanceMeters,
    this.caloriesBurned,
    this.activeMinutes,
    this.floorsClimbed,
    this.activityType,
  });

  Map<String, dynamic> toJson() {
    return {
      if (steps != null) 'steps': steps,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
      if (activeMinutes != null) 'active_minutes': activeMinutes,
      if (floorsClimbed != null) 'floors_climbed': floorsClimbed,
      if (activityType != null) 'activity_type': activityType,
    };
  }

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      steps: json['steps'] as int?,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
      activeMinutes: json['active_minutes'] as int?,
      floorsClimbed: json['floors_climbed'] as int?,
      activityType: json['activity_type'] as String?,
    );
  }
}

class BiometricProfile {
  final String userId;
  final double? currentHeartRate;
  final double? restingHeartRate;
  final double? avgHrv;
  final double? avgBloodOxygen;
  final double? avgStressLevel;
  final int? todaySteps;
  final double? todayCalories;
  final int? lastSleepScore;
  final double? lastSleepDurationHours;
  final int? healthScore;
  final DateTime? lastSync;
  final String? deviceType;
  final Map<String, dynamic>? trends;

  BiometricProfile({
    required this.userId,
    this.currentHeartRate,
    this.restingHeartRate,
    this.avgHrv,
    this.avgBloodOxygen,
    this.avgStressLevel,
    this.todaySteps,
    this.todayCalories,
    this.lastSleepScore,
    this.lastSleepDurationHours,
    this.healthScore,
    this.lastSync,
    this.deviceType,
    this.trends,
  });

  factory BiometricProfile.fromJson(Map<String, dynamic> json) {
    return BiometricProfile(
      userId: json['user_id'] as String,
      currentHeartRate: (json['current_heart_rate'] as num?)?.toDouble(),
      restingHeartRate: (json['resting_heart_rate'] as num?)?.toDouble(),
      avgHrv: (json['avg_hrv'] as num?)?.toDouble(),
      avgBloodOxygen: (json['avg_blood_oxygen'] as num?)?.toDouble(),
      avgStressLevel: (json['avg_stress_level'] as num?)?.toDouble(),
      todaySteps: json['today_steps'] as int?,
      todayCalories: (json['today_calories'] as num?)?.toDouble(),
      lastSleepScore: json['last_sleep_score'] as int?,
      lastSleepDurationHours: (json['last_sleep_duration_hours'] as num?)?.toDouble(),
      healthScore: json['health_score'] as int?,
      lastSync: json['last_sync'] != null ? DateTime.parse(json['last_sync'] as String) : null,
      deviceType: json['device_type'] as String?,
      trends: json['trends'] as Map<String, dynamic>?,
    );
  }

  bool get isConnected => lastSync != null && 
      DateTime.now().difference(lastSync!).inMinutes < 30;
}

class BiometricSummary {
  final String userId;
  final String date;
  final double? avgHeartRate;
  final double? avgHrv;
  final double? avgBloodOxygen;
  final double? avgStressLevel;
  final int? totalSteps;
  final double? totalCalories;
  final int? totalSleepMinutes;
  final int? sleepScore;
  final int dataPoints;
  final DateTime lastUpdated;

  BiometricSummary({
    required this.userId,
    required this.date,
    this.avgHeartRate,
    this.avgHrv,
    this.avgBloodOxygen,
    this.avgStressLevel,
    this.totalSteps,
    this.totalCalories,
    this.totalSleepMinutes,
    this.sleepScore,
    required this.dataPoints,
    required this.lastUpdated,
  });

  factory BiometricSummary.fromJson(Map<String, dynamic> json) {
    return BiometricSummary(
      userId: json['user_id'] as String,
      date: json['date'] as String,
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toDouble(),
      avgHrv: (json['avg_hrv'] as num?)?.toDouble(),
      avgBloodOxygen: (json['avg_blood_oxygen'] as num?)?.toDouble(),
      avgStressLevel: (json['avg_stress_level'] as num?)?.toDouble(),
      totalSteps: json['total_steps'] as int?,
      totalCalories: (json['total_calories'] as num?)?.toDouble(),
      totalSleepMinutes: json['total_sleep_minutes'] as int?,
      sleepScore: json['sleep_score'] as int?,
      dataPoints: json['data_points'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }
}

