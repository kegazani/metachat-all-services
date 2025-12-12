import 'dart:async';
import 'package:metachat_app/features/biometric/data/datasources/biometric_remote_data_source.dart';
import 'package:metachat_app/features/biometric/domain/models/watch_data.dart';

class BiometricService {
  final BiometricRemoteDataSource _remoteDataSource;
  StreamSubscription? _wsSubscription;
  Timer? _syncTimer;
  
  final _profileController = StreamController<BiometricProfile>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  BiometricService(this._remoteDataSource);

  Stream<BiometricProfile> get profileStream => _profileController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  Future<BiometricProfile> getBiometricProfile(String userId) async {
    final profile = await _remoteDataSource.getBiometricProfile(userId);
    _profileController.add(profile);
    return profile;
  }

  Future<List<BiometricSummary>> getSummaries(String userId, {int days = 7}) async {
    return _remoteDataSource.getSummaries(userId, days: days);
  }

  Future<BiometricSummary> getTodaySummary(String userId) async {
    return _remoteDataSource.getTodaySummary(userId);
  }

  Future<void> sendWatchData(String userId, WatchData data) async {
    await _remoteDataSource.sendWatchData(userId, data);
    final profile = await getBiometricProfile(userId);
    _profileController.add(profile);
  }

  void startRealtimeSync(String userId) {
    _connectionStatusController.add(true);
    
    final stream = _remoteDataSource.connectWebSocket(userId);
    _wsSubscription = stream.listen(
      (data) {
        if (data['status'] == 'ok') {
          getBiometricProfile(userId);
        }
      },
      onError: (error) {
        _connectionStatusController.add(false);
      },
      onDone: () {
        _connectionStatusController.add(false);
      },
    );

    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      try {
        await getBiometricProfile(userId);
      } catch (_) {}
    });
  }

  void stopRealtimeSync() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    _remoteDataSource.disconnectWebSocket();
    _connectionStatusController.add(false);
  }

  void dispose() {
    stopRealtimeSync();
    _profileController.close();
    _connectionStatusController.close();
  }
}

