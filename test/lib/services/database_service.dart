import 'package:test/services/api_client.dart';

class DatabaseService {
  final ApiClient _apiClient = ApiClient();

  Future<void> delete(String itemId, String itemType) async {
    try {
      await _apiClient.delete('/$itemType/$itemId');
    } catch (e) {
      // Handle or re-throw the exception
      rethrow;
    }
  }
}
