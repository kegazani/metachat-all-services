import '../../../../core/network/api_client.dart';
import '../../../domain/models/match_request.dart';

class MatchRequestRemoteDataSource {
  final ApiClient apiClient;

  MatchRequestRemoteDataSource(this.apiClient);

  Future<MatchRequest> createMatchRequest({
    required String fromUserId,
    required String toUserId,
    required List<String> commonTopics,
    required double similarity,
  }) async {
    try {
      final response = await apiClient.post('/match-requests', data: {
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'common_topics': commonTopics,
        'similarity': similarity,
      });
      return MatchRequest.fromJson(response.data['match_request'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to create match request: $e');
    }
  }

  Future<List<MatchRequest>> getUserMatchRequests(String userId, {String? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : {};
      final response = await apiClient.get('/match-requests/user/$userId', queryParameters: queryParams);
      final List<dynamic> data = response.data['match_requests'] ?? response.data;
      return data.map((json) => MatchRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user match requests: $e');
    }
  }

  Future<MatchRequest> acceptMatchRequest(String requestId, String userId) async {
    try {
      final response = await apiClient.put('/match-requests/$requestId/accept', queryParameters: {'user_id': userId});
      return MatchRequest.fromJson(response.data['match_request'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to accept match request: $e');
    }
  }

  Future<MatchRequest> rejectMatchRequest(String requestId, String userId) async {
    try {
      final response = await apiClient.put('/match-requests/$requestId/reject', queryParameters: {'user_id': userId});
      return MatchRequest.fromJson(response.data['match_request'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to reject match request: $e');
    }
  }

  Future<MatchRequest> cancelMatchRequest(String requestId, String userId) async {
    try {
      final response = await apiClient.delete('/match-requests/$requestId', queryParameters: {'user_id': userId});
      return MatchRequest.fromJson(response.data['match_request'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to cancel match request: $e');
    }
  }

  Future<List<String>> getCommonTopics(String userId1, String userId2) async {
    try {
      final response = await apiClient.get('/users/$userId1/common-topics/$userId2');
      return List<String>.from(response.data['common_topics'] ?? []);
    } catch (e) {
      throw Exception('Failed to get common topics: $e');
    }
  }
}

