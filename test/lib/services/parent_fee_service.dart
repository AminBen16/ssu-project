import 'package:logger/logger.dart';
import 'package:test/services/api_client.dart';
import 'package:test/services/offline_service.dart';
import 'package:test/services/local_database_service.dart';

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

/// Model for fee balance information
class FeeBalanceData {
  final String studentId;
  final String studentName;
  final double totalFees;
  final double paidAmount;
  final double outstandingAmount;
  final double overdueAmount;
  final List<FeeBreakdown> feeBreakdown;
  final DateTime lastUpdated;

  FeeBalanceData({
    required this.studentId,
    required this.studentName,
    required this.totalFees,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.overdueAmount,
    required this.feeBreakdown,
    required this.lastUpdated,
  });

  factory FeeBalanceData.fromMap(Map<String, dynamic> map) {
    return FeeBalanceData(
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      totalFees: (map['totalFees'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      outstandingAmount: (map['outstandingAmount'] as num).toDouble(),
      overdueAmount: (map['overdueAmount'] as num).toDouble(),
      feeBreakdown: (map['feeBreakdown'] as List<dynamic>?)
              ?.map((e) => FeeBreakdown.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'totalFees': totalFees,
      'paidAmount': paidAmount,
      'outstandingAmount': outstandingAmount,
      'overdueAmount': overdueAmount,
      'feeBreakdown': feeBreakdown.map((e) => e.toMap()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Model for fee breakdown by category
class FeeBreakdown {
  final String category;
  final double amount;
  final double paidAmount;
  final double outstandingAmount;
  final DateTime dueDate;
  final String status; // 'paid', 'partially_paid', 'unpaid', 'overdue'

  FeeBreakdown({
    required this.category,
    required this.amount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.dueDate,
    required this.status,
  });

  factory FeeBreakdown.fromMap(Map<String, dynamic> map) {
    return FeeBreakdown(
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      outstandingAmount: (map['outstandingAmount'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'amount': amount,
      'paidAmount': paidAmount,
      'outstandingAmount': outstandingAmount,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
    };
  }
}

/// Service for handling parent fee payments with offline queuing support
class ParentFeeService {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = offlineService;
  final LocalDatabaseService _localDb = localDatabaseService;
  final Logger _logger = Logger();

  /// Get fee balance for a specific child
  Future<FeeBalanceData> getChildFeeBalance({
    required String schoolId,
    required String parentId,
    required String studentId,
  }) async {
    final cacheKey = 'fee_balance_${schoolId}_${parentId}_$studentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/students/$studentId/fees/balance',
        );
        final balanceData =
            FeeBalanceData.fromMap(response as Map<String, dynamic>);

        // Cache the balance data locally
        await _localDb.saveData('fee_balance', studentId, balanceData.toMap());

        return balanceData;
      },
      offlineFallback: () async {
        // Try to get cached balance data
        final cached = await _localDb.getData('fee_balance', studentId);
        if (cached != null) {
          return FeeBalanceData.fromMap(cached);
        }
        throw Exception(
            'No cached fee balance data available for student $studentId');
      },
      cacheKey: cacheKey,
    );
  }

  /// Get fee balances for all children of a parent
  Future<List<FeeBalanceData>> getAllChildrenFeeBalances({
    required String schoolId,
    required String parentId,
  }) async {
    final cacheKey = 'all_children_fee_balances_${schoolId}_$parentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/children/fees/balances',
        );
        final List<dynamic> data = response as List<dynamic>;
        final balancesList = data
            .map((item) => FeeBalanceData.fromMap(item as Map<String, dynamic>))
            .toList();

        // Cache all children fee balance data
        for (final balance in balancesList) {
          await _localDb.saveData(
              'fee_balance', balance.studentId, balance.toMap());
        }

        return balancesList;
      },
      offlineFallback: () async {
        // Get all cached children fee balance data
        final allCached = await _localDb.getAllData('fee_balance');
        return allCached.map((item) => FeeBalanceData.fromMap(item)).toList();
      },
      cacheKey: cacheKey,
    );
  }

  /// Make a fee payment with offline queuing support
  Future<FeePaymentData> makeFeePayment({
    required String schoolId,
    required String parentId,
    required String studentId,
    required String studentName,
    required double amount,
    required String paymentMethod,
    String currency = 'USD',
  }) async {
    final paymentId = 'fee_payment_${DateTime.now().millisecondsSinceEpoch}';
    final paymentData = FeePaymentData(
      paymentId: paymentId,
      studentId: studentId,
      studentName: studentName,
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod,
      paymentDate: DateTime.now(),
      status: 'pending',
      createdAt: DateTime.now(),
      isOfflinePayment: false,
    );

    final isOnline = await _offlineService.isOnline;

    if (isOnline) {
      try {
        final response = await _apiClient.post(
          '/api/schools/$schoolId/parents/$parentId/students/$studentId/fees/payments',
          body: {
            'amount': amount,
            'paymentMethod': paymentMethod,
            'currency': currency,
          },
        );

        final completedPayment =
            FeePaymentData.fromMap(response as Map<String, dynamic>);

        // Cache the completed payment locally
        await _localDb.saveData('fee_payments', completedPayment.paymentId,
            completedPayment.toMap());

        return completedPayment;
      } catch (e) {
        // Queue payment for offline sync
        final offlinePaymentData = FeePaymentData(
          paymentId: paymentData.paymentId,
          studentId: paymentData.studentId,
          studentName: paymentData.studentName,
          amount: paymentData.amount,
          currency: paymentData.currency,
          paymentMethod: paymentData.paymentMethod,
          paymentDate: paymentData.paymentDate,
          status: paymentData.status,
          transactionId: paymentData.transactionId,
          failureReason: paymentData.failureReason,
          createdAt: paymentData.createdAt,
          isOfflinePayment: true,
        );
        await _offlineService.queueForSync('insert', {
          'table': 'fee_payments',
          'schoolId': schoolId,
        '__endpoint': '/api/schools/$schoolId/parents/$parentId/students/$studentId/fees/payments',
          'parentId': parentId,
          ...offlinePaymentData.toMap(),
        });

        // Cache locally for immediate display
        await _localDb.saveData(
            'fee_payments', paymentId, offlinePaymentData.toMap());

        rethrow;
      }
    } else {
      // Queue payment for offline sync
      final offlinePaymentData = FeePaymentData(
        paymentId: paymentData.paymentId,
        studentId: paymentData.studentId,
        studentName: paymentData.studentName,
        amount: paymentData.amount,
        currency: paymentData.currency,
        paymentMethod: paymentData.paymentMethod,
        paymentDate: paymentData.paymentDate,
        status: 'queued',
        transactionId: paymentData.transactionId,
        failureReason: paymentData.failureReason,
        createdAt: paymentData.createdAt,
        isOfflinePayment: true,
      );
      await _offlineService.queueForSync('insert', {
        'table': 'fee_payments',
        'schoolId': schoolId,
        '__endpoint': '/api/schools/$schoolId/parents/$parentId/students/$studentId/fees/payments',
        'parentId': parentId,
        ...offlinePaymentData.toMap(),
      });

      // Cache locally for immediate display
      await _localDb.saveData(
          'fee_payments', paymentId, offlinePaymentData.toMap());

      return offlinePaymentData;
    }
  }

  /// Get payment history for a specific child
  Future<List<FeePaymentData>> getChildPaymentHistory({
    required String schoolId,
    required String parentId,
    required String studentId,
    int limit = 20,
  }) async {
    final cacheKey =
        'payment_history_${schoolId}_${parentId}_${studentId}_$limit';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/students/$studentId/fees/payments?limit=$limit',
        );
        final List<dynamic> data = response as List<dynamic>;
        final paymentsList = data
            .map((item) => FeePaymentData.fromMap(item as Map<String, dynamic>))
            .toList();

        // Cache payment history locally
        for (final payment in paymentsList) {
          await _localDb.saveData(
              'fee_payments', payment.paymentId, payment.toMap());
        }

        return paymentsList;
      },
      offlineFallback: () async {
        // Get cached payment history for this student
        final allPayments = await _localDb.getAllData('fee_payments');
        return allPayments
            .map((item) => FeePaymentData.fromMap(item))
            .where((payment) => payment.studentId == studentId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
      cacheKey: cacheKey,
    );
  }

  /// Get payment history for all children of a parent
  Future<List<FeePaymentData>> getAllChildrenPaymentHistory({
    required String schoolId,
    required String parentId,
    int limit = 50,
  }) async {
    final cacheKey =
        'all_children_payment_history_${schoolId}_${parentId}_$limit';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/children/fees/payments?limit=$limit',
        );
        final List<dynamic> data = response as List<dynamic>;
        final paymentsList = data
            .map((item) => FeePaymentData.fromMap(item as Map<String, dynamic>))
            .toList();

        // Cache all payment history locally
        for (final payment in paymentsList) {
          await _localDb.saveData(
              'fee_payments', payment.paymentId, payment.toMap());
        }

        return paymentsList;
      },
      offlineFallback: () async {
        // Get all cached payment history
        final allPayments = await _localDb.getAllData('fee_payments');
        return allPayments.map((item) => FeePaymentData.fromMap(item)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
      cacheKey: cacheKey,
    );
  }

  /// Get pending/queued payments that need to be synced
  Future<List<FeePaymentData>> getPendingPayments(String parentId) async {
    final allPayments = await _localDb.getAllData('fee_payments');
    return allPayments
        .map((item) => FeePaymentData.fromMap(item))
        .where((payment) =>
            payment.isOfflinePayment &&
            (payment.status == 'pending' || payment.status == 'queued'))
        .toList();
  }

  /// Retry failed or queued payments
  Future<void> retryPendingPayments({
    required String schoolId,
    required String parentId,
  }) async {
    final isOnline = await _offlineService.isOnline;
    if (!isOnline) return;

    // Trigger generic sync which now handles custom endpoints
    await _offlineService.processSyncQueue();

    // Refresh payment history to update local status (isOfflinePayment -> false)
    // This ensures the UI reflects the synced state
    await getAllChildrenPaymentHistory(schoolId: schoolId, parentId: parentId);
  }

  /// Get fee payment statistics for a parent
  Future<Map<String, dynamic>> getFeePaymentStats({
    required String schoolId,
    required String parentId,
  }) async {
    final cacheKey = 'fee_payment_stats_${schoolId}_$parentId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/fees/stats',
        );
        final stats = response as Map<String, dynamic>;

        // Cache stats locally
        await _localDb.saveData('fee_payment_stats', parentId, {
          ...stats,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return stats;
      },
      offlineFallback: () async {
        // Try to get cached stats
        final cached = await _localDb.getData('fee_payment_stats', parentId);
        if (cached != null) {
          return Map<String, dynamic>.from(cached)..remove('lastUpdated');
        }

        // Calculate stats from cached data
        final allBalances = await getAllChildrenFeeBalances(
          schoolId: schoolId,
          parentId: parentId,
        );
        final allPayments = await getAllChildrenPaymentHistory(
          schoolId: schoolId,
          parentId: parentId,
        );

        double totalOutstanding = 0.0;
        double totalOverdue = 0.0;
        double totalPaidThisMonth = 0.0;

        for (final balance in allBalances) {
          totalOutstanding += balance.outstandingAmount;
          totalOverdue += balance.overdueAmount;
        }

        final now = DateTime.now();
        final thisMonth = DateTime(now.year, now.month);
        for (final payment in allPayments) {
          if (payment.status == 'completed' &&
              payment.paymentDate.isAfter(thisMonth)) {
            totalPaidThisMonth += payment.amount;
          }
        }

        return {
          'totalOutstanding': totalOutstanding,
          'totalOverdue': totalOverdue,
          'totalPaidThisMonth': totalPaidThisMonth,
          'numberOfChildren': allBalances.length,
          'pendingPayments': (await getPendingPayments(parentId)).length,
        };
      },
      cacheKey: cacheKey,
    );
  }

  /// Get upcoming fee due dates
  Future<List<Map<String, dynamic>>> getUpcomingFeeDues({
    required String schoolId,
    required String parentId,
    int daysAhead = 30,
  }) async {
    final cacheKey = 'upcoming_fee_dues_${schoolId}_${parentId}_$daysAhead';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/parents/$parentId/fees/upcoming-dues?days=$daysAhead',
        );
        final List<dynamic> dues = response as List<dynamic>;
        final duesList = dues.cast<Map<String, dynamic>>();

        // Cache upcoming dues
        await _localDb
            .saveData('upcoming_fee_dues', '${parentId}_$daysAhead', {
          'dues': duesList,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return duesList;
      },
      offlineFallback: () async {
        // Try to get cached upcoming dues
        final cached = await _localDb.getData(
            'upcoming_fee_dues', '${parentId}_$daysAhead');
        if (cached != null && cached['dues'] != null) {
          return List<Map<String, dynamic>>.from(cached['dues']);
        }

        // Calculate from cached balance data
        final balances = await getAllChildrenFeeBalances(
          schoolId: schoolId,
          parentId: parentId,
        );

        final upcomingDues = <Map<String, dynamic>>[];
        final now = DateTime.now();
        final cutoffDate = now.add(Duration(days: daysAhead));

        for (final balance in balances) {
          for (final breakdown in balance.feeBreakdown) {
            if (breakdown.outstandingAmount > 0 &&
                breakdown.dueDate.isAfter(now) &&
                breakdown.dueDate.isBefore(cutoffDate)) {
              upcomingDues.add({
                'studentId': balance.studentId,
                'studentName': balance.studentName,
                'category': breakdown.category,
                'amount': breakdown.outstandingAmount,
                'dueDate': breakdown.dueDate.toIso8601String(),
                'daysUntilDue': breakdown.dueDate.difference(now).inDays,
              });
            }
          }
        }

        upcomingDues.sort((a, b) =>
            (a['dueDate'] as String).compareTo(b['dueDate'] as String));
        return upcomingDues;
      },
      cacheKey: cacheKey,
    );
  }

  /// Get payment methods available for a school
  Future<List<Map<String, dynamic>>> getAvailablePaymentMethods({
    required String schoolId,
  }) async {
    final cacheKey = 'payment_methods_$schoolId';

    return await _offlineService.callWithOfflineFallback(
      onlineCall: () async {
        final response = await _apiClient.get(
          '/api/schools/$schoolId/fees/payment-methods',
        );
        final List<dynamic> methods = response as List<dynamic>;
        final methodsList = methods.cast<Map<String, dynamic>>();

        // Cache payment methods
        await _localDb.saveData('payment_methods', schoolId, {
          'methods': methodsList,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        return methodsList;
      },
      offlineFallback: () async {
        // Try to get cached payment methods
        final cached = await _localDb.getData('payment_methods', schoolId);
        if (cached != null && cached['methods'] != null) {
          return List<Map<String, dynamic>>.from(cached['methods']);
        }

        // Return default payment methods
        return [
          {'id': 'card', 'name': 'Credit/Debit Card', 'enabled': true},
          {'id': 'bank_transfer', 'name': 'Bank Transfer', 'enabled': true},
          {'id': 'cash', 'name': 'Cash Payment', 'enabled': true},
          {'id': 'mobile_money', 'name': 'Mobile Money', 'enabled': false},
        ];
      },
      cacheKey: cacheKey,
    );
  }

  /// Refresh fee data for a specific child
  Future<void> refreshChildFeeData({
    required String schoolId,
    required String parentId,
    required String studentId,
  }) async {
    final isOnline = await _offlineService.isOnline;
    if (!isOnline) return;

    try {
      await getChildFeeBalance(
        schoolId: schoolId,
        parentId: parentId,
        studentId: studentId,
      );
    } catch (e) {
      _logger.e('Error refreshing child fee data: $e');
    }
  }

  /// Clear cached fee data for a parent
  Future<void> clearParentFeeCache(String parentId) async {
    // This would need to be implemented to clear all fee-related caches for a parent
    // For now, we'll clear all fee-related caches
    await _localDb.clearCache();
  }

  /// Get fee summary for dashboard display
  Future<Map<String, dynamic>> getFeeSummary({
    required String schoolId,
    required String parentId,
  }) async {
    final balances = await getAllChildrenFeeBalances(
      schoolId: schoolId,
      parentId: parentId,
    );
    final pendingPayments = await getPendingPayments(parentId);
    final upcomingDues = await getUpcomingFeeDues(
      schoolId: schoolId,
      parentId: parentId,
      daysAhead: 7, // Next week
    );

    double totalOutstanding = 0.0;
    double totalOverdue = 0.0;
    int childrenWithOutstandingFees = 0;

    for (final balance in balances) {
      totalOutstanding += balance.outstandingAmount;
      totalOverdue += balance.overdueAmount;
      if (balance.outstandingAmount > 0) {
        childrenWithOutstandingFees++;
      }
    }

    return {
      'totalOutstanding': totalOutstanding,
      'totalOverdue': totalOverdue,
      'childrenWithOutstandingFees': childrenWithOutstandingFees,
      'pendingPaymentsCount': pendingPayments.length,
      'upcomingDuesCount': upcomingDues.length,
      'totalChildren': balances.length,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}

// Singleton instance
final parentFeeService = ParentFeeService();
