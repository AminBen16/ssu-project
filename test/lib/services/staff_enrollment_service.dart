import 'package:flutter/foundation.dart';
import 'package:test/models/user_roles.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';

class StaffEnrollmentService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = OfflineService();

  /// Enrolls a new staff member by sending their details to the backend API with offline support.
  Future<void> enrollStaff({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String schoolId,
    required UserRole role,
    // Add other staff details as needed
    String? title,
    String? phoneNumber,
    double? salary,
    double? allowances,
    required List<String> subjectCodes,
    String? address,
    String? nin,
    DateTime? dateOfBirth,
    String? maritalStatus,
    String? qualification,
    String? sex,
    List<String>? teachingClasses,
    List<String>? teachingDays,
  }) async {
    // Build the payload dynamically, only including non-null optional values.
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'schoolId': schoolId,
      'role': role.toServerRole(), // Convert to server-compatible role string
      if (subjectCodes.isNotEmpty) 'subjectCodes': subjectCodes,
    };

    if (title != null && title.isNotEmpty) payload['title'] = title;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      payload['phoneNumber'] = phoneNumber;
    }
    if (salary != null) payload['salary'] = salary;
    if (allowances != null) payload['allowances'] = allowances;
    if (address != null && address.isNotEmpty) payload['address'] = address;
    if (nin != null && nin.isNotEmpty) payload['nin'] = nin;
    if (dateOfBirth != null) {
      // Send as milliseconds since epoch for better compatibility with server-side Date objects.
      payload['dateOfBirth'] = dateOfBirth.millisecondsSinceEpoch;
    }
    if (maritalStatus != null) payload['maritalStatus'] = maritalStatus;
    if (qualification != null && qualification.isNotEmpty) {
      payload['qualification'] = qualification;
    }
    if (sex != null) payload['sex'] = sex;
    if (teachingClasses != null && teachingClasses.isNotEmpty) {
      payload['teachingClasses'] = teachingClasses;
    }
    if (teachingDays != null && teachingDays.isNotEmpty) {
      payload['teachingDays'] = teachingDays;
    }

    final online = await _offlineService.isOnline;
    if (online) {
      try {
        // Call the backend API endpoint to enroll the staff member
        await _apiClient.post('/api/schools/$schoolId/users', body: payload);
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService.queueForSync('insert', {
          'table': 'staff_enrollments',
          'schoolId': schoolId,
          ...payload,
        });
        debugPrint('Staff enrollment queued for sync: $e');
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'staff_enrollments',
        'schoolId': schoolId,
        ...payload,
      });
      debugPrint('Staff enrollment queued for offline sync');
    }
  }
}
