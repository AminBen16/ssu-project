import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:test/models/fee_balance_model.dart';
import 'package:test/models/student_model.dart';
import 'package:test/screens/student_report_list_screen.dart';
import 'package:test/services/fee_service.dart';
import 'package:test/services/pdf_service.dart';
import 'package:test/services/local_database_service.dart';
import 'package:test/widgets/future_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:test/screens/make_payment_screen.dart';
// import 'package:test/widgets/dashboard_action_button.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/user_data_provider.dart';

/// Defines the display mode for the [ChildInfoCard].
enum ViewMode { list, grid }

/// A card widget that displays information and actions for a single student (child).
class ChildInfoCard extends StatefulWidget {
  final Student child;
  final String schoolId;
  final FeeService feeService;

  final ViewMode viewMode;
  const ChildInfoCard({
    super.key,
    required this.child,
    required this.schoolId,
    required this.feeService,
    this.viewMode = ViewMode.list,
  });

  @override
  State<ChildInfoCard> createState() => _ChildInfoCardState();
}

class _ChildInfoCardState extends State<ChildInfoCard>
    with SingleTickerProviderStateMixin {
  late Future<FeeBalance> _balanceFuture;
  final PdfService _pdfService = PdfService();
  late AnimationController _animationController;
  bool _isInitialLoad = true;
  bool _isRefreshing = false;
  final LocalDatabaseService _localDb = localDatabaseService;
  Map<String, bool> _syncStatus = {};
  final Map<String, dynamic> _queueStatus = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _refreshBalance();
    _checkSyncStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _refreshBalance() {
    setState(() {
      _balanceFuture = widget.feeService.getStudentFeeBalance(widget.child.id);
    });
  }

  Future<void> _checkSyncStatus() async {
    final studentCacheKey = 'student_${widget.child.id}';
    final feeCacheKey = 'fee_balance_${widget.child.id}';
    final reportCacheKey = 'report_card_${widget.child.id}_';

    final studentCached = await _localDb.getCache(studentCacheKey) != null;
    final feeCached = await _localDb.getCache(feeCacheKey) != null;
    final reportCached = await _localDb.getCache(reportCacheKey) != null;

    setState(() {
      _syncStatus = {
        'student': studentCached,
        'fees': feeCached,
        'reports': reportCached,
      };
    });
  }

  void _handleRefresh() {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _animationController.repeat();
    _refreshBalance();
    _balanceFuture.whenComplete(() {
      if (mounted) {
        _animationController.stop();
        setState(() => _isRefreshing = false);
      }
    });
  }

  Future<void> _sendSmsReminder(double balance) async {
    // if (widget.child.parentContact == null ||
    //     widget.child.parentContact!.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('No parent contact number available.')),
    //   );
    //   return;
    // }

    // try {
    //   final callable =
    //       FirebaseFunctions.instance.httpsCallable('sendSmsReminder');
    //   await callable.call<Map<String, dynamic>>({
    //     'studentId': widget.child.id,
    //     'schoolId': widget.schoolId,
    //     'balance': balance,
    //     'parentContact': widget.child.parentContact,
    //     'studentName': widget.child.fullName,
    //   });

    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text('SMS reminder sent successfully!'),
    //         backgroundColor: Colors.green,
    //       ),
    //     );
    //   }
    // } catch (e) {
    //   if (mounted)
    //     ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(content: Text('Could not open SMS app: $e')));
    // }
  }

  Future<void> _sharePaymentDetails(double balance) async {
    if (!mounted) return;
    final userDataProvider =
        Provider.of<UserDataProvider>(context, listen: false);
    final scaffoldMessenger =
        ScaffoldMessenger.of(context); // Capture before async gap

    final school = userDataProvider.school;
    if (school == null) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('School information not found.')));
      return;
    }

    try {
      final feeBalance = await _balanceFuture;
      final pdfBytes = await _pdfService.generatePaymentDetailsPdf(
        student: widget.child,
        balance: balance,
        feeBalance: feeBalance,
        school: school,
      );
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'Payment_Details_${widget.child.fullName.replaceAll(' ', '_')}.pdf';
      final file =
          await File('${tempDir.path}/$fileName').writeAsBytes(pdfBytes);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        // shareXFiles is the correct method in recent versions
        [XFile(file.path)],
        text: 'Payment details for ${widget.child.fullName}',
        subject: 'Payment Details - ${widget.child.fullName}',
      );
    } catch (e) {
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
    }
  }

  Future<void> _printPaymentDetails(double balance) async {
    if (!mounted) return;
    final school = Provider.of<UserDataProvider>(context, listen: false).school;
    if (school == null) return;
    final feeBalance = await _balanceFuture;
    final pdfBytes = await _pdfService.generatePaymentDetailsPdf(
      student: widget.child,
      balance: balance,
      feeBalance: feeBalance,
      school: school,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  Future<void> _savePaymentDetailsPdf(double balance) async {
    if (!mounted) return;
    final userDataProvider =
        Provider.of<UserDataProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final school = userDataProvider.school;
    if (school == null) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('School information not found.')));
      return;
    }

    try {
      final feeBalance = await _balanceFuture;
      final pdfBytes = await _pdfService.generatePaymentDetailsPdf(
        student: widget.child,
        balance: balance,
        feeBalance: feeBalance,
        school: school,
      );
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save Payment Details',
        fileName:
            'Payment_Details_${widget.child.fullName.replaceAll(' ', '_')}.pdf',
        bytes: pdfBytes,
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to save PDF: $e')),
      );
    }
  }

  Future<void> _showPaymentConfirmationDialog(double balance) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Payment for ${widget.child.fullName}'),
          content: Text(
              'You are about to proceed to the payment screen. The outstanding balance is ${NumberFormat.currency(symbol: 'UGX ').format(balance)}.\n\nDo you wish to continue?'),
          actions: <Widget>[
            TextButton.icon(
              icon: const Icon(Icons.save_alt, size: 16),
              label: const Text('Save PDF'),
              onPressed: () => _savePaymentDetailsPdf(balance),
            ),
            TextButton.icon(
              icon: const Icon(Icons.print, size: 16),
              label: const Text('Print'),
              onPressed: () => _printPaymentDetails(balance),
            ),
            TextButton.icon(
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Share'),
              onPressed: () => _sharePaymentDetails(balance),
            ),
            TextButton.icon(
              icon: const Icon(Icons.sms, size: 16),
              label: const Text('Send Reminder'),
              onPressed: () => _sendSmsReminder(balance),
            ),
            // if (widget.child.parentContact != null &&
            //     widget.child.parentContact!.isNotEmpty)
            //   TextButton.icon(
            //     icon: const Icon(Icons.phone, size: 16),
            //     label: const Text('Copy Contact'),
            //     onPressed: () {
            //       Clipboard.setData(
            //           ClipboardData(text: widget.child.parentContact!));
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(
            //             content: Text("Parent's contact copied to clipboard")),
            //       );
            //     },
            //     style: TextButton.styleFrom(
            //         foregroundColor:
            //             Theme.of(context).textTheme.bodySmall?.color),
            //   ),
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy ID'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.child.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Student ID copied to clipboard')),
                );
              },
              style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).textTheme.bodySmall?.color),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue to Payment'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return MakePaymentScreen(
            studentId: widget.child.id,
            studentName: widget.child.fullName,
            balance: balance,
          );
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viewMode == ViewMode.grid) {
      return _buildGridLayout(context);
    }
    return _buildListLayout(context);
  }

  Widget _buildListLayout(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Header
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      child: Text(
                        widget.child.firstName.isNotEmpty
                            ? widget.child.firstName[0]
                            : '?',
                      ),
                    ),
                    // Offline indicator
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _syncStatus['student'] == true
                              ? Colors.green
                              : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _syncStatus['student'] == true
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.child.fullName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          // Sync status indicators
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Fee sync status
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _syncStatus['fees'] == true
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _syncStatus['fees'] == true
                                      ? Icons.account_balance_wallet
                                      : Icons.account_balance_wallet_outlined,
                                  size: 14,
                                  color: _syncStatus['fees'] == true
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Report sync status
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _syncStatus['reports'] == true
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _syncStatus['reports'] == true
                                      ? Icons.receipt_long
                                      : Icons.receipt_long_outlined,
                                  size: 14,
                                  color: _syncStatus['reports'] == true
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                              // Payment queue indicator
                              if (_queueStatus['payments'] == true)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${_queueStatus['pendingCount'] ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        widget.child.className,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Fee Balance and Actions
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: FutureHandler<FeeBalance>(
                key: ValueKey(_balanceFuture),
                future: _balanceFuture,
                loadingWidget: _isInitialLoad
                    ? _buildShimmerPlaceholder()
                    : const SizedBox.shrink(),
                errorBuilder: (context, error) => Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${error.toString()}'),
                      IconButton(
                        icon: const Icon(Icons
                            .refresh), // No animation on error for simplicity
                        onPressed: _handleRefresh,
                      )
                    ],
                  ),
                ),
                emptyMessage: 'Balance not available',
                builder: (context, feeBalance) {
                  if (_isInitialLoad) {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => setState(() => _isInitialLoad = false));
                  }
                  final balance = feeBalance.balance;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (balance > 0)
                            Text(
                              'Balance: ${NumberFormat.currency(symbol: 'UGX ').format(balance)}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          else
                            Text(
                              'Paid in Full',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          const SizedBox(width: 8),
                          RotationTransition(
                            turns: _animationController,
                            child: IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _handleRefresh,
                              tooltip: 'Refresh Balance',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                      //   children: [
                      //     if (balance > 0)
                      //       DashboardActionButton(
                      //         icon: Icons.payment,
                      //         label: 'Pay Fees',
                      //         onTap: () =>
                      //             _showPaymentConfirmationDialog(balance),
                      //         color: Theme.of(context).colorScheme.onPrimary,
                      //         backgroundColor:
                      //             Theme.of(context).colorScheme.primary,
                      //       ),
                      //     DashboardActionButton(
                      //       icon: Icons.receipt_long,
                      //       label: 'Reports',
                      //       onTap: () {
                      //         Navigator.of(context).push(MaterialPageRoute(
                      //           builder: (context) => StudentReportListScreen(
                      //               studentId: widget.child.id),
                      //         ));
                      //       },
                      //     ),
                      //     DashboardActionButton(
                      //       icon: Icons.history,
                      //       label: 'History',
                      //       onTap: () {
                      //         Navigator.of(context).push(MaterialPageRoute(
                      //           builder: (context) => PaymentHistoryScreen(
                      //             studentId: widget.child.id,
                      //             studentName: widget.child.fullName,
                      //           ),
                      //         ));
                      //       },
                      //     ),
                      //   ],
                      // ),,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Student Header (Compact)
            CircleAvatar(
              radius: 24,
              child: Text(
                widget.child.firstName.isNotEmpty
                    ? widget.child.firstName[0]
                    : '?',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.child.fullName,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.child.className,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 16),
            // Fee Balance and Actions (Compact)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: FutureHandler<FeeBalance>(
                  key: ValueKey(_balanceFuture),
                  future: _balanceFuture,
                  loadingWidget: _isInitialLoad
                      ? _buildShimmerPlaceholder()
                      : const SizedBox.shrink(),
                  errorBuilder: (context, error) => Center(
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _handleRefresh,
                      tooltip: 'Retry',
                    ),
                  ),
                  emptyMessage: 'N/A',
                  builder: (context, feeBalance) {
                    if (_isInitialLoad) {
                      WidgetsBinding.instance.addPostFrameCallback(
                          (_) => setState(() => _isInitialLoad = false));
                    }
                    final balance = feeBalance.balance;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Balance Text
                        if (balance > 0)
                          Text(
                            NumberFormat.currency(
                                    symbol: 'UGX ', decimalDigits: 0)
                                .format(balance),
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            'Paid',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Action Buttons (Compact)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (balance > 0)
                              IconButton(
                                icon: Icon(Icons.payment,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                tooltip: 'Pay Fees',
                                onPressed: () =>
                                    _showPaymentConfirmationDialog(balance),
                              ),
                            IconButton(
                              icon: const Icon(Icons.receipt_long),
                              tooltip: 'View Reports',
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => StudentReportListScreen(
                                      studentId: widget.child.id),
                                ));
                              },
                            ),
                            // IconButton(
                            //   icon: const Icon(Icons.history),
                            //   tooltip: 'Payment History',
                            //   onPressed: () {
                            //     Navigator.of(context).push(MaterialPageRoute(
                            //       builder: (context) => PaymentHistoryScreen(
                            //         studentId: widget.child.id,
                            //         studentName: widget.child.fullName,
                            //       ),
                            //     ));
                            //   },
                            // ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                const CircleAvatar(radius: 12, backgroundColor: Colors.white),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                  3,
                  (_) => Container(
                        width: 80,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8)),
                      )),
            ),
          ],
        ),
      ),
    );
  }
}
