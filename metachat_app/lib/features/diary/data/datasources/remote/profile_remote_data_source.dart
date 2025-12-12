import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../domain/models/profile_progress.dart';
import '../../../domain/models/user_statistics.dart';

class ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSource(this.apiClient);

  Future<ProfileProgress> getProfileProgress(String userId) async {
    try {
      final response = await apiClient.get('/users/$userId/profile-progress');
      return ProfileProgress.fromJson(response.data['progress'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to get profile progress: $e');
    }
  }

  Future<UserStatistics> getUserStatistics(String userId) async {
    try {
      final response = await apiClient.get('/users/$userId/statistics');
      return UserStatistics.fromJson(response.data['statistics'] ?? response.data);
    } catch (e) {
      throw Exception('Failed to get user statistics: $e');
    }
  }
}

