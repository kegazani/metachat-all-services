import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:metachat_app/features/biometric/domain/models/watch_data.dart';
import 'package:metachat_app/features/biometric/domain/services/biometric_service.dart';

class BiometricProvider extends ChangeNotifier {
  final BiometricService _biometricService;
  
  BiometricProfile? _profile;
  List<BiometricSummary> _summaries = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String? _error;
  String? _userId;

  StreamSubscription? _profileSubscription;
  StreamSubscription? _connectionSubscription;

  BiometricProvider(this._biometricService);

  BiometricProfile? get profile => _profile;
  List<BiometricSummary> get summaries => _summaries;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get error => _error;

  int? get healthScore => _profile?.healthScore;
  double? get currentHeartRate => _profile?.currentHeartRate;
  int? get todaySteps => _profile?.todaySteps;
  double? get todayCalories => _profile?.todayCalories;
  int? get lastSleepScore => _profile?.lastSleepScore;
  double? get avgStressLevel => _profile?.avgStressLevel;

  void initialize(String userId) {
    _userId = userId;
    _listenToStreams();
  }

  void _listenToStreams() {
    _profileSubscription = _biometricService.profileStream.listen((profile) {
      _profile = profile;
      notifyListeners();
    });

    _connectionSubscription = _biometricService.connectionStatusStream.listen((status) {
      _isConnected = status;
      notifyListeners();
    });
  }

  Future<void> loadProfile() async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _biometricService.getBiometricProfile(_userId!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSummaries({int days = 7}) async {
    if (_userId == null) return;

    try {
      _summaries = await _biometricService.getSummaries(_userId!, days: days);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendWatchData(WatchData data) async {
    if (_userId == null) return;

    try {
      await _biometricService.sendWatchData(_userId!, data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void startRealtimeSync() {
    if (_userId == null) return;
    _biometricService.startRealtimeSync(_userId!);
  }

  void stopRealtimeSync() {
    _biometricService.stopRealtimeSync();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _connectionSubscription?.cancel();
    _biometricService.dispose();
    super.dispose();
  }
}

