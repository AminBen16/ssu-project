import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:test/models/fee_structure_model.dart';
import 'package:test/models/fee_payment_model.dart';
import 'package:test/services/api_client.dart';
import 'package:test/models/fee_balance_model.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

class FeeService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;

  /// Fetches all fee structures for a given school.
  Future<List<FeeStructure>> getFeeStructures(String schoolId) async {
    final cacheKey = 'fee_structures_$schoolId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response =
            await _apiClient.get('/api/schools/$schoolId/fee-structures');
        if (response == null) return [];
        final List<dynamic> data = response['fee_structures'] as List<dynamic>;
        return data.map((json) => FeeStructure.fromMap(json)).toList();
      },
      offlineFallback: () async {
        // Try to get cached fee structures
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final List<dynamic> data = jsonDecode(cached);
          return data.map((json) => FeeStructure.fromMap(json)).toList();
        }
        return [];
      },
      cacheKey: cacheKey,
    );
  }

  /// Creates or updates a fee structure.
  Future<FeeStructure> saveFeeStructure(
      String schoolId, FeeStructure feeStructure) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        final payload = feeStructure.toJson();
        final response = await _apiClient.post(
          '/api/schools/$schoolId/fee-structures',
          body: payload,
        );
        return FeeStructure.fromMap(response);
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService.queueForSync('insert', {
          'table': 'fee_structures',
          'schoolId': schoolId,
          ...feeStructure.toJson(),
        });
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'fee_structures',
        'schoolId': schoolId,
        ...feeStructure.toJson(),
      });
      // Return the fee structure as if it was saved (optimistic update)
      return feeStructure;
    }
  }

  /// Updates an existing fee structure.
  Future<void> updateFeeStructure(String schoolId, String structureId,
      Map<String, dynamic> updateData) async {
    await _apiClient.put(
      '/api/schools/$schoolId/fee-structures/$structureId',
      body: updateData,
    );
  }

  /// Deletes a fee structure.
  Future<void> deleteFeeStructure(
      String schoolId, String feeStructureId) async {
    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient
            .delete('/api/schools/$schoolId/fee-structures/$feeStructureId');
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService.queueForSync('delete', {
          'table': 'fee_structures',
          'schoolId': schoolId,
          'feeStructureId': feeStructureId,
        });
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('delete', {
        'table': 'fee_structures',
        'schoolId': schoolId,
        'feeStructureId': feeStructureId,
      });
    }
  }

  /// Records a new fee payment for a student.
  Future<void> recordPayment(Map<String, dynamic> paymentData) async {
    final String schoolId = paymentData['schoolId'] as String;
    final String studentId =
        paymentData['studentId'].toString(); // Ensure it's String
    final double amountPaid = paymentData['amountPaid'] as double;
    final String paymentMethod = paymentData['paymentMethod'] as String;
    final String recordedById = paymentData['recordedById'] as String;
    final String recordedByName = paymentData['recordedByName'] as String;
    final DateTime paymentDate =
        paymentData['paymentDate'] as DateTime; // Already DateTime

    // Create a FeePayment object for internal use (e.g., caching)
    final FeePayment feePayment = FeePayment(
      id: const Uuid().v4(),
      studentId: studentId,
      amountPaid: amountPaid,
      paymentDate: paymentDate,
      status: 'Paid', // Default status for recorded payments
      description:
          'Payment via $paymentMethod by $recordedByName', // Default description
    );

    // Prepare payload for API
    final apiPayload = {
      'id': feePayment.id,
      'schoolId': schoolId,
      'studentId': feePayment.studentId,
      'amountPaid': feePayment.amountPaid,
      'paymentMethod': paymentMethod,
      'recordedById': recordedById,
      'recordedByName': recordedByName,
      'paymentDate': feePayment.paymentDate.toIso8601String(),
      'status': feePayment.status,
      'description': feePayment.description,
    };

    final online = await _offlineService.isOnline;
    if (online) {
      try {
        await _apiClient.post('/api/fee-payments', body: apiPayload);
        await _localDb.saveData('fees', feePayment.id, feePayment.toMap());
      } catch (e) {
        // If online call fails, queue for sync
        await _offlineService.queueForSync('insert', {
          'table': 'fees', // Use 'fees' table as per LocalDatabaseService
          ...apiPayload, // Queue the full API payload
        });
        await _localDb.saveData('fees', feePayment.id, feePayment.toMap());
        rethrow;
      }
    } else {
      // Queue for sync when offline
      await _offlineService.queueForSync('insert', {
        'table': 'fees', // Use 'fees' table as per LocalDatabaseService
        ...apiPayload, // Queue the full API payload
      });
      await _localDb.saveData('fees', feePayment.id, feePayment.toMap());
    }
  }

  /// Fetches the fee balance for a specific student.
  Future<FeeBalance> getStudentFeeBalance(String studentId) async {
    final cacheKey = 'fee_balance_$studentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response =
            await _apiClient.get('/api/students/$studentId/fee-balance');
        return FeeBalance.fromMap(response!);
      },
      offlineFallback: () async {
        // Try to get cached fee balance
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final Map<String, dynamic> data = cached as Map<String, dynamic>;
          return FeeBalance.fromMap(data);
        }
        return null;
      },
      cacheKey: cacheKey,
    );
  }

  /// Fetches the payment history for a specific student.
  Future<List<FeePayment>> getStudentFeeHistory(String studentId) async {
    final cacheKey = 'fee_history_$studentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response =
            await _apiClient.get('/api/students/$studentId/fees/history');
        if (response == null) return [];
        final List<dynamic> data = response as List<dynamic>;
        return data.map((json) => FeePayment.fromMap(json)).toList();
      },
      offlineFallback: () async {
        // 1. Try to get cached fee history (list)
        final cachedJson = await _localDb.getCache(cacheKey);
        if (cachedJson != null) {
          final List<dynamic> data = jsonDecode(cachedJson);
          return data.map((json) => FeePayment.fromMap(json)).toList();
        }

        // 2. If no cached list, try to get all individual fee payments from 'fees' table
        final allLocalFeePayments = await _localDb.getAllData('fees');
        return allLocalFeePayments
            .map((json) => FeePayment.fromMap(json as Map<String, dynamic>))
            .where((payment) => payment.studentId == studentId)
            .toList();
      },
      cacheKey: cacheKey,
    );
  }

  /// Fetches the overall fee summary for the school.
  Future<Map<String, double>> getSchoolFeeSummary(String schoolId) async {
    final cacheKey = 'fee_summary_$schoolId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response =
            await _apiClient.get('/api/schools/$schoolId/fees/summary');
        if (response == null) {
          return {'totalExpected': 0.0, 'totalCollected': 0.0};
        }
        final data = response as Map<String, dynamic>;
        // Ensure values are doubles
        return {
          'totalExpected': (data['total_fees'] as num?)?.toDouble() ?? 0.0,
          'totalCollected': (data['total_paid'] as num?)?.toDouble() ?? 0.0,
        };
      },
      offlineFallback: () async {
        // Try to get cached fee summary
        final cached = await _localDb.getCache(cacheKey);
        if (cached != null) {
          final Map<String, dynamic> data = cached as Map<String, dynamic>;
          return {
            'totalExpected': (data['totalExpected'] as num?)?.toDouble() ?? 0.0,
            'totalCollected':
                (data['totalCollected'] as num?)?.toDouble() ?? 0.0,
          };
        }
        return {'totalExpected': 0.0, 'totalCollected': 0.0};
      },
      cacheKey: cacheKey,
    );
  }

  /// Verifies a payment with the given reference.
  Future<void> verifyPayment(String reference) async {
    await _apiClient
        .post('/api/payments/verify', body: {'reference': reference});
  }
}
