import 'package:test/services/api_client.dart';

/// A service to interact with the backend payment gateway functions.
class PaymentGatewayService {
  final ApiClient _apiClient = ApiClient();

  /// Initializes a transaction by calling the local backend API.
  ///
  /// This function communicates with the local server for payment processing.
  /// It returns a payment link for the user to complete the transaction.
  Future<String> initializeTransaction({
    required double amount,
    required String email,
    required String studentId,
    required String studentName,
    required String schoolId,
  }) async {
    try {
      final response = await _apiClient.post('/payments/initialize', body: {
        'amount': amount,
        'email': email,
        'studentId': studentId,
        'studentName': studentName,
        'schoolId': schoolId,
      });

      final paymentLink = response['paymentLink'] as String?;
      if (paymentLink == null || paymentLink.isEmpty) {
        throw Exception('Backend did not return a valid payment link.');
      }
      return paymentLink;
    } catch (e) {
      throw Exception('Payment initialization error: ${e.toString()}');
    }
  }
}
