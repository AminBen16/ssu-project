
import 'package:test/services/api_client.dart';

class SocialMediaService {
  final ApiClient _apiClient;

  SocialMediaService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Gets a list of all social posts for a school.
  Future<List<Map<String, dynamic>>> getPosts(String schoolId) async {
    try {
      final response = await _apiClient.get('/api/schools/$schoolId/posts');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Creates a new social post.
  Future<void> createPost(String schoolId, Map<String, dynamic> post) async {
    try {
      await _apiClient.post(
          '/api/schools/$schoolId/posts', body: post);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Deletes a social post.
  Future<void> deletePost(String schoolId, String postId) async {
    try {
      await _apiClient.delete('/api/schools/$schoolId/posts/$postId');
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }
}
