import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:metachat_app/core/network/api_client.dart';
import 'package:metachat_app/features/biometric/domain/models/watch_data.dart';

abstract class BiometricRemoteDataSource {
  Future<BiometricProfile> getBiometricProfile(String userId);
  Future<List<BiometricSummary>> getSummaries(String userId, {int days = 7});
  Future<BiometricSummary> getTodaySummary(String userId);
  Future<void> sendWatchData(String userId, WatchData data);
  Stream<Map<String, dynamic>> connectWebSocket(String userId);
  void disconnectWebSocket();
}

class BiometricRemoteDataSourceImpl implements BiometricRemoteDataSource {
  final ApiClient _apiClient;
  final String _wsBaseUrl;
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _streamController;

  BiometricRemoteDataSourceImpl(this._apiClient, {String? wsBaseUrl})
      : _wsBaseUrl = wsBaseUrl ?? 'ws://localhost:8080';

  @override
  Future<BiometricProfile> getBiometricProfile(String userId) async {
    final response = await _apiClient.get('/biometric/profile/$userId');
    return BiometricProfile.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<BiometricSummary>> getSummaries(String userId, {int days = 7}) async {
    final response = await _apiClient.get('/biometric/summary/$userId', query: {'days': days});
    final data = response.data as List;
    return data.map((e) => BiometricSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<BiometricSummary> getTodaySummary(String userId) async {
    final response = await _apiClient.get('/biometric/summary/$userId/today');
    return BiometricSummary.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> sendWatchData(String userId, WatchData data) async {
    final body = {
      'user_id': userId,
      ...data.toJson(),
    };
    await _apiClient.post('/biometric/watch/data', body: body);
  }

  @override
  Stream<Map<String, dynamic>> connectWebSocket(String userId) {
    disconnectWebSocket();

    _streamController = StreamController<Map<String, dynamic>>.broadcast();
    
    final wsUrl = Uri.parse('$_wsBaseUrl/biometric/ws/$userId');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen(
      (data) {
        try {
          final jsonData = jsonDecode(data as String) as Map<String, dynamic>;
          _streamController?.add(jsonData);
        } catch (e) {
          _streamController?.addError(e);
        }
      },
      onError: (error) {
        _streamController?.addError(error);
      },
      onDone: () {
        _streamController?.close();
      },
    );

    return _streamController!.stream;
  }

  @override
  void disconnectWebSocket() {
    _channel?.sink.close();
    _channel = null;
    _streamController?.close();
    _streamController = null;
  }

  void sendWatchDataViaWebSocket(WatchData data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data.toJson()));
    }
  }
}

