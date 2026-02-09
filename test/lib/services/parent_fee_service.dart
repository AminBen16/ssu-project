import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:test/models/user_profile.dart';
import 'package:test/models/student_model.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';
import 'package:logger/logger.dart';

/// Model for fee payment data
class FeePaymentData {
  final String paymentId;
  final String studentId;
  final String studentName;
  final double amount;
  final String currency;
  final String paymentMethod;
  final DateTime paymentDate;
  final String status; // 'pending', 'processing', 'completed', 'failed'
  final String? transactionId;
  final String? failureReason;
  final DateTime createdAt;
  final bool isOfflinePayment; // true if queued for offline sync

  FeePaymentData({
    required this.paymentId,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentDate,
    required this.status,
    this.transactionId,
    this.failureReason,
    required this.createdAt,
    this.isOfflinePayment = false,
  });

  factory FeePaymentData.fromMap(Map<String, dynamic> map) {
    return FeePaymentData(
      paymentId: map['paymentId'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      paymentMethod: map['paymentMethod'] as String,
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      status: map['status'] as String,
      transactionId: map['transactionId'] as String?,
      failureReason: map['failureReason'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isOfflinePayment: map['isOfflinePayment'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate.toIso8601String(),
      'status': status,
      'transactionId': transactionId,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
      'isOfflinePayment': isOfflinePayment,
    };
  }
}

/// Model for fee balance data
class FeeBalanceData {
  final String studentId;
  final String studentName;
  final double totalFees;
  final double amountPaid;
  final double balance;
  final String currency;
  final String academicYear;
  final String term;

  FeeBalanceData({
    required this.studentId,
    required this.studentName,
    required this.totalFees,
    required this.amountPaid,
    required this.balance,
    required this.currency,
    required this.academicYear,
    required this.term,
  });

  factory FeeBalanceData.fromMap(Map<String, dynamic> map) {
    return FeeBalanceData(
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      totalFees: (map['totalFees'] as num).toDouble(),
      amountPaid: (map['amountPaid'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      academicYear: map['academicYear'] as String,
      term: map['term'] as String,
    );
  }
}

/// Service for managing parent fee operations
class ParentFeeService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;
  final Logger _logger = Logger();

  /// Fetches fee balance for a specific student
  Future<FeeBalanceData?> getStudentFeeBalance(String studentId) async {
    try {
      final cacheKey = 'fee_balance_$studentId';

      return await _offlineService.callWithOfflineFallback(
        onlineCall: () async {
          final response =
              await _apiClient.get('/api/students/$studentId/fee-balance');
          if (response == null) return null;

          return FeeBalanceData.fromMap(
              response['feeBalance'] as Map<String, dynamic>);
        },
        offlineFallback: () async {
          final cached = await _localDb.getCache(cacheKey);
          if (cached != null) {
            final data = jsonDecode(cached) as Map<String, dynamic>;
            return FeeBalanceData.fromMap(data);
          }
          return null;
        },
        cacheKey: cacheKey,
      );
    } catch (e) {
      _logger.e('Error fetching fee balance for student $studentId: $e');
      return null;
    }
  }

  /// Fetches payment history for a student
  Future<List<FeePaymentData>> getPaymentHistory(String studentId) async {
    try {
      final cacheKey = 'payment_history_$studentId';

      return await _offlineService.callWithOfflineFallback(
        onlineCall: () async {
          final response =
              await _apiClient.get('/api/students/$studentId/payments');
          if (response == null) return [];

          final List<dynamic> payments = response['payments'] as List<dynamic>;
          return payments
              .map((p) => FeePaymentData.fromMap(p as Map<String, dynamic>))
              .toList();
        },
        offlineFallback: () async {
          final cached = await _localDb.getCache(cacheKey);
          if (cached != null) {
            final List<dynamic> payments = jsonDecode(cached);
            return payments
                .map((p) => FeePaymentData.fromMap(p as Map<String, dynamic>))
                .toList();
          }

          // Try to get from local database
          final localPayments = await _localDb.getAllData('payments');
          final studentPayments =
              localPayments.where((p) => p['studentId'] == studentId).toList();
          return studentPayments
              .map((p) => FeePaymentData.fromMap(p as Map<String, dynamic>))
              .toList();
        },
        cacheKey: cacheKey,
      );
    } catch (e) {
      _logger.e('Error fetching payment history for student $studentId: $e');
      return [];
    }
  }

  /// Records a new fee payment
  Future<bool> recordPayment(FeePaymentData payment) async {
    try {
      final isOnline = await _offlineService.isOnline;

      if (isOnline) {
        // Try to sync to server first
        try {
          final response = await _apiClient.post(
            '/api/students/${payment.studentId}/payments',
            body: payment.toMap(),
          );

          if (response != null) {
            // Cache the successful payment
            await _localDb.setCache(
                'payment_${payment.paymentId}', jsonEncode(payment.toMap()));
            return true;
          }
        } catch (e) {
          _logger.w(
              'Failed to sync payment to server, will queue for offline: $e');
        }
      }

      // Queue for offline sync or store locally
      final offlinePayment = FeePaymentData(
        paymentId: payment.paymentId,
        studentId: payment.studentId,
        studentName: payment.studentName,
        amount: payment.amount,
        currency: payment.currency,
        paymentMethod: payment.paymentMethod,
        paymentDate: payment.paymentDate,
        status: isOnline ? payment.status : 'pending',
        transactionId: payment.transactionId,
        failureReason: payment.failureReason,
        createdAt: payment.createdAt,
        isOfflinePayment: !isOnline,
      );

      // Store in local database for offline sync
      await _localDb.insert('payments', offlinePayment.toMap());
      await _localDb.setCache(
          'payment_${payment.paymentId}', jsonEncode(offlinePayment.toMap()));

      return true;
    } catch (e) {
      _logger.e('Error recording payment: $e');
      return false;
    }
  }

  /// Generates payment receipt
  Future<Map<String, dynamic>?> generateReceipt(String paymentId) async {
    try {
      final cacheKey = 'receipt_$paymentId';

      return await _offlineService.callWithOfflineFallback(
        onlineCall: () async {
          final response =
              await _apiClient.get('/api/payments/$paymentId/receipt');
          return response;
        },
        offlineFallback: () async {
          final cached = await _localDb.getCache(cacheKey);
          if (cached != null) {
            return jsonDecode(cached);
          }
          return null;
        },
        cacheKey: cacheKey,
      );
    } catch (e) {
      _logger.e('Error generating receipt for payment $paymentId: $e');
      return null;
    }
  }

  /// Syncs pending offline payments
  Future<void> syncPendingPayments() async {
    try {
      final isOnline = await _offlineService.isOnline;
      if (!isOnline) return;

      final pendingPayments = await _localDb.getAll('payments');
      final offlinePayments =
          pendingPayments.where((p) => p['isOfflinePayment'] == true).toList();

      for (final paymentData in offlinePayments) {
        try {
          final payment =
              FeePaymentData.fromMap(paymentData as Map<String, dynamic>);

          final response = await _apiClient.post(
            '/api/students/${payment.studentId}/payments',
            body: payment.toMap(),
          );

          if (response != null) {
            // Mark as synced
            paymentData['isOfflinePayment'] = false;
            paymentData['status'] = 'completed';
            await _localDb.update('payments', paymentData);
            _logger.i('Successfully synced payment: ${payment.paymentId}');
          }
        } catch (e) {
          _logger.e('Failed to sync payment ${paymentData['paymentId']}: $e');
        }
      }
    } catch (e) {
      _logger.e('Error syncing pending payments: $e');
    }
  }

  /// Gets fee structure for student's class
  Future<Map<String, dynamic>?> getStudentFeeStructure(String studentId) async {
    try {
      final cacheKey = 'fee_structure_student_$studentId';

      return await _offlineService.callWithOfflineFallback(
        onlineCall: () async {
          final response =
              await _apiClient.get('/api/students/$studentId/fee-structure');
          return response;
        },
        offlineFallback: () async {
          final cached = await _localDb.getCache(cacheKey);
          if (cached != null) {
            return jsonDecode(cached);
          }
          return null;
        },
        cacheKey: cacheKey,
      );
    } catch (e) {
      _logger.e('Error fetching fee structure for student $studentId: $e');
      return null;
    }
  }

  /// Calculates expected payment amount for a term
  Future<double?> calculateTermPayment(
      String studentId, String term, String academicYear) async {
    try {
      final feeStructure = await getStudentFeeStructure(studentId);
      if (feeStructure == null) return null;

      // Extract term-specific fees from structure
      final termFees = feeStructure['termFees'] as Map<String, dynamic>?;
      if (termFees == null || !termFees.containsKey(term)) return null;

      return (termFees[term] as num).toDouble();
    } catch (e) {
      _logger.e('Error calculating term payment: $e');
      return null;
    }
  }

  /// Gets fee summary for a student
  Future<Map<String, dynamic>> getFeeSummary(String studentId, {String? schoolId, String? parentId}) async {
    try {
      final cacheKey = 'fee_summary_$studentId';

      return await _offlineService.callWithOfflineFallback(
        onlineCall: () async {
          final response =
              await _apiClient.get('/api/students/$studentId/fee-summary');
          return response ?? {};
        },
        offlineFallback: () async {
          final cached = await _localDb.getCache(cacheKey);
          if (cached != null) {
            return jsonDecode(cached);
          }
          return {};
        },
        cacheKey: cacheKey,
      );
    } catch (e) {
      _logger.e('Error fetching fee summary for student $studentId: $e');
      return {};
    }
  }

  /// Gets all payments for a school (for admin/fee collection screen)
  Future<List<FeePaymentData>> getAllPaymentsForSchool(String schoolId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final cacheKey = 'school_payments_$schoolId';

      return await _offlineService.callWithOfflineFallback(
        onlineCall: () async {
          final queryParams = <String, String>{};
          if (startDate != null) {
            queryParams['startDate'] = startDate.toIso8601String();
          }
          if (endDate != null) {
            queryParams['endDate'] = endDate.toIso8601String();
          }
          
          final response = await _apiClient.get(
            '/api/schools/$schoolId/payments',
            queryParameters: queryParams.isNotEmpty ? queryParams : null,
          );

          
          if (response == null) return [];

          final List<dynamic> payments = response['payments'] as List<dynamic>? ?? [];
          return payments
              .map((p) => FeePaymentData.fromMap(p as Map<String, dynamic>))
              .toList();
        },
        offlineFallback: () async {
          final cached = await _localDb.getCache(cacheKey);
          if (cached != null) {
            final List<dynamic> payments = jsonDecode(cached);
            return payments
                .map((p) => FeePaymentData.fromMap(p as Map<String, dynamic>))
                .toList();
          }

          // Get all local payments and filter by school if possible
          final allPayments = await _localDb.getAllData('payments');
          return allPayments
              .map((p) => FeePaymentData.fromMap(p as Map<String, dynamic>))
              .toList();
        },
        cacheKey: cacheKey,
      );
    } catch (e) {
      _logger.e('Error fetching payments for school $schoolId: $e');
      return [];
    }
  }
}


// Singleton instance
final parentFeeService = ParentFeeService();
