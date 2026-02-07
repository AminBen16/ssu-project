import 'package:test/models/salary_model.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/services/api_client.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/services/offline_service.dart';

class SalaryService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;

  /// Fetches all staff members who can receive a salary.
  Future<List<UserProfile>> getSalariedStaff(String schoolId) async {
    final response = await _apiClient.get(
      '/api/schools/$schoolId/staff',
      queryParameters: {
        'roles': UserRole.allStaffRoles.map((r) => r.name).join(',')
      },
    );
    final List<dynamic> staffList = response as List<dynamic>;
    return staffList
        .map((json) => UserProfile.fromMap(json, json['id']))
        .toList();
  }

  /// Records a salary payment for a staff member with offline support.
  Future<void> recordSalaryPayment({
    required String schoolId,
    required String staffId,
    required double amount,
    required String month,
    required int year,
    required String recordedById,
    required String recordedByName,
  }) async {
    final paymentData = {
      'staff_id': staffId,
      'basic_salary': amount.toString(),
      'allowances': '0',
      'deductions': '0',
      'net_salary': amount.toString(),
      'month': month,
      'year': year.toString(),
      'status': 'paid',
    };

    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient.post('/api/schools/$schoolId/salaries',
            body: paymentData);
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService.queueForSync('insert', {
          'table': 'salary_payments',
          'schoolId': schoolId,
          'staff_id': staffId,
          'basic_salary': amount.toString(),
          'allowances': '0',
          'deductions': '0',
          'net_salary': amount.toString(),
          'month': month,
          'year': year.toString(),
          'status': 'paid',
        });
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'salary_payments',
        'schoolId': schoolId,
        ...paymentData,
      });
    }
  }

  Future<List<SalaryPayment>> getStaffPaymentHistory({
    required String schoolId,
    required String staffId,
    String? year,
  }) async {
    final queryParameters = <String, String>{};
    if (year != null) {
      queryParameters['year'] = year;
    }

    final response = await _apiClient.get(
      '/api/staff/$staffId/salaries',
      queryParameters: queryParameters,
    );

    final List<dynamic> data = response['salary_records'] as List<dynamic>;
    return data.map((json) => SalaryPayment.fromMap(json)).toList();
  }

  /// Fetches a set of staff IDs who have been paid for a specific month and year.
  Future<Set<String>> getPaidStaffIdsForMonth({
    required String schoolId,
    required String month,
    required int year,
  }) async {
    final response = await _apiClient.get(
      '/api/schools/$schoolId/salaries',
      queryParameters: {
        'month': month,
        'year': year.toString(),
      },
    );
    final List<dynamic> data = response['salary_records'] as List<dynamic>;
    return data.map((record) => record['staff_id'].toString()).toSet();
  }

  /// Records multiple salary payments in a single atomic batch.
  Future<void> recordBulkSalaryPayments({
    required String schoolId,
    required List<Map<String, dynamic>>
        payments, // List of {'staffId': String, 'amount': double}
    required String month,
    required int year,
    required String recordedById,
    required String recordedByName,
  }) async {
    for (final payment in payments) {
      await _apiClient.post('/api/schools/$schoolId/salaries', body: {
        'staff_id': payment['staffId'],
        'basic_salary': payment['amount'].toString(),
        'allowances': '0',
        'deductions': '0',
        'net_salary': payment['amount'].toString(),
        'month': month,
        'year': year.toString(),
        'status': 'paid',
      });
    }
  }
}
