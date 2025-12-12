import 'dart:async';
import 'dart:io';
import 'package:health/health.dart';
import 'package:metachat_app/features/biometric/domain/models/watch_data.dart';

class HealthKitService {
  final Health _health = Health();
  bool _isAuthorized = false;
  Timer? _syncTimer;

  static const List<HealthDataType> _healthDataTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_IN_BED,
  ];

  bool get isAuthorized => _isAuthorized;

  Future<bool> requestAuthorization() async {
    try {
      await _health.configure();
      
      final permissions = _healthDataTypes.map((e) => HealthDataAccess.READ).toList();
      _isAuthorized = await _health.requestAuthorization(_healthDataTypes, permissions: permissions);
      
      return _isAuthorized;
    } catch (e) {
      _isAuthorized = false;
      return false;
    }
  }

  Future<WatchData> fetchLatestHealthData() async {
    if (!_isAuthorized) {
      throw Exception('Health data access not authorized');
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final yesterday = startOfDay.subtract(const Duration(days: 1));

    double? heartRate;
    double? hrv;
    double? restingHeartRate;
    double? bloodOxygen;
    double? respiratoryRate;
    double? bodyTemperature;
    int? steps;
    double? distance;
    double? calories;
    int? sleepMinutes;

    try {
      final heartRateData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now,
      );
      if (heartRateData.isNotEmpty) {
        heartRate = (heartRateData.last.value as NumericHealthValue).numericValue.toDouble();
      }

      final hrvData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        startTime: startOfDay,
        endTime: now,
      );
      if (hrvData.isNotEmpty) {
        hrv = (hrvData.last.value as NumericHealthValue).numericValue.toDouble();
      }

      final restingHRData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.RESTING_HEART_RATE],
        startTime: startOfDay,
        endTime: now,
      );
      if (restingHRData.isNotEmpty) {
        restingHeartRate = (restingHRData.last.value as NumericHealthValue).numericValue.toDouble();
      }

      final spo2Data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_OXYGEN],
        startTime: startOfDay,
        endTime: now,
      );
      if (spo2Data.isNotEmpty) {
        bloodOxygen = (spo2Data.last.value as NumericHealthValue).numericValue.toDouble();
      }

      final stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );
      if (stepsData.isNotEmpty) {
        steps = stepsData.fold<int>(0, (sum, data) => 
            sum + (data.value as NumericHealthValue).numericValue.toInt());
      }

      final distanceData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
        startTime: startOfDay,
        endTime: now,
      );
      if (distanceData.isNotEmpty) {
        distance = distanceData.fold<double>(0, (sum, data) => 
            sum + (data.value as NumericHealthValue).numericValue.toDouble());
      }

      final caloriesData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: now,
      );
      if (caloriesData.isNotEmpty) {
        calories = caloriesData.fold<double>(0, (sum, data) => 
            sum + (data.value as NumericHealthValue).numericValue.toDouble());
      }

      final sleepData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: yesterday,
        endTime: now,
      );
      if (sleepData.isNotEmpty) {
        sleepMinutes = sleepData.fold<int>(0, (sum, data) {
          final start = data.dateFrom;
          final end = data.dateTo;
          return sum + end.difference(start).inMinutes;
        });
      }
    } catch (e) {
      rethrow;
    }

    return WatchData(
      deviceId: Platform.isIOS ? 'apple_health' : 'google_fit',
      deviceType: Platform.isIOS ? 'apple_watch' : 'wear_os',
      heartRate: heartRate,
      heartRateVariability: hrv,
      restingHeartRate: restingHeartRate,
      bloodOxygen: bloodOxygen,
      respiratoryRate: respiratoryRate,
      bodyTemperature: bodyTemperature,
      sleepData: sleepMinutes != null 
          ? SleepData(totalSleepMinutes: sleepMinutes)
          : null,
      activity: ActivityData(
        steps: steps,
        distanceMeters: distance,
        caloriesBurned: calories,
      ),
      recordedAt: now,
    );
  }

  void startPeriodicSync(Function(WatchData) onData, {Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) async {
      try {
        final data = await fetchLatestHealthData();
        onData(data);
      } catch (_) {}
    });
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void dispose() {
    stopPeriodicSync();
  }
}

