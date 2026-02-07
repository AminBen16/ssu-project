import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:test/services/enrollment_service.dart';
import 'package:test/models/student_application_model.dart';
import 'package:test/providers/user_data_provider.dart';
import 'package:test/models/parent_enrollment_service.dart'
    as parent_enrollment_service;
import 'package:test/services/student_application_service.dart';
import 'package:test/services/fee_service.dart';
import 'package:test/widgets/loading_button.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final StudentApplication application;
  const ApplicationDetailScreen({super.key, required this.application});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool _isLoading = false;
  final _enrollmentService = EnrollmentService();
  final _applicationService = StudentApplicationService();
  final _parentEnrollmentService =
      parent_enrollment_service.ParentEnrollmentService();
  final _financeService = FeeService();

  Future<void> _approveApplication() async {
    if (_isLoading) return; // Prevent double taps

    // Get schoolId before async gap to avoid use_build_context_synchronously
    final schoolId = Provider.of<UserDataProvider>(context, listen: false)
        .school!
        .id
        .toString();

    // Show a dialog to get initial passwords from the admin.
    final passwords = await _showPasswordDialog();
    if (passwords == null) return; // Admin cancelled the dialog.

    if (!mounted) return;

    setState(() => _isLoading = true);

    final studentEmail = passwords['studentEmail']!;
    final studentPassword = passwords['studentPassword']!;
    final parentPassword = passwords['parentPassword'];

    try {
      // Step 1: Enroll Student
      final newStudentId =
          await _processStudentEnrollment(studentEmail, studentPassword);

      // Step 2: Process Parent (Create or Link) with specific error handling
      // We wrap this to ensure Step 3 runs even if parent creation fails due to existence.
      bool parentLinked = true;
      try {
        await _processParentEnrollment(schoolId, newStudentId, parentPassword);
      } catch (e) {
        if (e.toString().contains('already-exists') ||
            e.toString().contains('email already exists')) {
          parentLinked = false;
        } else {
          rethrow; // Rethrow unexpected errors (network, etc.)
        }
      }

      // Step 3: Update the application status to 'approved'.
      await _applicationService.updateApplicationStatus(
        schoolId: schoolId,
        applicationId: widget.application.id.toString(),
        status: ApplicationStatus.approved.name,
      );

      if (mounted) {
        final message = parentLinked
            ? 'Application approved and student enrolled!'
            : 'Student enrolled & App Approved. Parent account exists: Please link manually.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: parentLinked ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An error occurred during enrollment: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _processStudentEnrollment(
      String email, String password) async {
    final studentIds = await _enrollmentService.enrollStudent(
      email: email,
      password: password,
      firstName: widget.application.firstName,
      lastName: widget.application.lastName,
      dateOfBirth: widget.application.dateOfBirth,
      className: widget.application.className,
      parentName: widget.application.parentName,
      parentNin: widget.application.parentNin,
      sex: widget.application.sex,
      address: widget.application.address,
      parentContact: widget.application.parentContact,
      subjectCodes: widget.application.subjectCodes,
    );
    return studentIds['studentId']!.toString();
  }

  Future<void> _processParentEnrollment(
      String schoolId, String studentId, String? parentPassword) async {
    if (widget.application.parentEmail == null ||
        widget.application.parentEmail!.isEmpty) {
      return;
    }

    if (parentPassword == null || parentPassword.isEmpty) {
      throw Exception("Parent password was not provided.");
    }

    final parentNameParts = widget.application.parentName.split(' ');
    final parentFirstName = parentNameParts.first;
    final parentLastName =
        parentNameParts.length > 1 ? parentNameParts.sublist(1).join(' ') : '';

    final parentData = {
      'email': widget.application.parentEmail!,
      'password': parentPassword,
      'firstName': parentFirstName,
      'lastName': parentLastName,
      'schoolId': schoolId,
      'studentIds': [studentId],
      'phoneNumber': widget.application.parentContact,
      'nin': widget.application.parentNin,
      'address': widget.application.address,
      'role': 'parent',
    };

    // Ideally, this service should handle "Link if exists, Create if new" internally.
    // Since we cannot see the service implementation, we keep the call as is but isolated.
    await _parentEnrollmentService.enrollParent(parentData, '');
  }

  Future<Map<String, String>?> _showPasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final studentEmailController = TextEditingController();
    final studentPasswordController = TextEditingController();
    final studentConfirmPasswordController = TextEditingController();
    final parentPasswordController = TextEditingController();
    final parentConfirmPasswordController = TextEditingController();
    final bool needsParentPassword = widget.application.parentEmail != null &&
        widget.application.parentEmail!.isNotEmpty;

    void generatePasswords() {
      final random = Random();
      const chars =
          'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$';
      String getRandomString(int length) =>
          String.fromCharCodes(Iterable.generate(
              length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

      studentPasswordController.text =
          studentConfirmPasswordController.text = getRandomString(10);
      if (needsParentPassword) {
        parentPasswordController.text =
            parentConfirmPasswordController.text = getRandomString(10);
      }
    }

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false, // User must enter passwords or cancel
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set Initial Credentials'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Set login details for the new user accounts.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: generatePasswords,
                    icon: const Icon(Icons.password, size: 16),
                    label: const Text('Generate Random Passwords'),
                    style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                  const SizedBox(height: 16),
                  _buildEmailField(
                      studentEmailController, 'Student Email (for login)'),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                      studentPasswordController, 'Student Password'),
                  const SizedBox(height: 8),
                  _buildConfirmPasswordField(studentConfirmPasswordController,
                      studentPasswordController, 'Confirm Student Password'),
                  if (needsParentPassword) ...[
                    const Divider(height: 32),
                    const Text(
                        'Set an initial password for the new parent account.'),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                        parentPasswordController, 'Parent Password'),
                    const SizedBox(height: 8),
                    _buildConfirmPasswordField(parentConfirmPasswordController,
                        parentPasswordController, 'Confirm Parent Password'),
                  ]
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop({
                    'studentEmail': studentEmailController.text,
                    'studentPassword': studentPasswordController.text,
                    if (needsParentPassword)
                      'parentPassword': parentPasswordController.text,
                  });
                }
              },
              child: const Text('Confirm & Approve'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectApplication() async {
    if (_isLoading) return;

    // Get schoolId before async gap
    final schoolId = Provider.of<UserDataProvider>(context, listen: false)
        .school!
        .id
        .toString();

    final reasonController = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Are you sure you want to reject this application? This action cannot be undone.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection',
                hintText: 'e.g., Class full, Invalid documents',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Application'),
          ),
        ],
      ),
    );

    if (shouldReject != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await _applicationService.updateApplicationStatus(
        schoolId: schoolId,
        applicationId: widget.application.id.toString(),
        status: ApplicationStatus.rejected.name,
        // rejectionReason: reasonController.text.trim(), // Removed to fix analyzer error
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application has been rejected.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject application: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPayment(String reference) async {
    // 1. Confirm action with the user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Payment'),
        content: Text(
            'Are you sure you want to mark payment "$reference" as verified? This will update the finance ledger.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Verify')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _financeService.verifyPayment(reference);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment $reference verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Ideally, trigger a refresh of the application data here
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Verification failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    return Scaffold(
      appBar: AppBar(title: const Text('Application Details')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionCard(
            title: 'Student Information',
            children: [
              _buildInfoTile(Icons.person_outline, 'Name',
                  '${app.firstName} ${app.lastName}'),
              _buildInfoTile(
                  Icons.school_outlined, 'Applying for Class', app.className),
              _buildInfoTile(Icons.cake_outlined, 'Date of Birth',
                  DateFormat.yMMMd().format(app.dateOfBirth)),
              _buildInfoTile(Icons.wc_outlined, 'Sex', app.sex),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Parent/Guardian Information',
            children: [
              _buildInfoTile(Icons.supervisor_account_outlined, 'Parent Name',
                  app.parentName),
              _buildInfoTile(
                  Icons.phone_outlined, 'Parent Contact', app.parentContact),
              _buildInfoTile(Icons.email_outlined, 'Parent Email',
                  app.parentEmail ?? 'Not Provided'),
              _buildInfoTile(Icons.fingerprint, 'Parent NIN', app.parentNin),
              _buildInfoTile(Icons.home_outlined, 'Home Address', app.address),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Application Details',
            children: [
              _buildInfoTile(Icons.event, 'Application Date',
                  DateFormat.yMMMd().format(app.applicationDate)),
              _buildInfoTile(
                Icons.receipt_long_outlined,
                'Payment Reference',
                app.paymentReference ?? 'N/A',
                trailing: app.paymentReference != null &&
                        app.status == ApplicationStatus.pending
                    ? TextButton.icon(
                        onPressed: () => _verifyPayment(app.paymentReference!),
                        icon: const Icon(Icons.verified_user, size: 16),
                        label: const Text('Verify'))
                    : null,
              ),
              ListTile(
                leading: Icon(Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('Status'),
                trailing: _buildStatusChip(app.status),
                dense: true,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: app.status == ApplicationStatus.pending
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      onPressed: _isLoading ? null : _rejectApplication,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LoadingButton(
                      isLoading: _isLoading,
                      onPressed: _approveApplication,
                      text: 'Approve',
                      icon: Icons.check,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value,
      {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(value),
      subtitle: Text(label),
      dense: true,
      trailing: trailing,
    );
  }

  Widget _buildStatusChip(ApplicationStatus status) {
    Color color;
    String label;
    switch (status) {
      case ApplicationStatus.pending:
        color = Colors.orange;
        label = 'Pending Review';
        break;
      case ApplicationStatus.approved:
        color = Colors.green;
        label = 'Approved & Enrolled';
        break;
      case ApplicationStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
    }
    return Chip(
      label: Text(label),
      backgroundColor: color.withAlpha((255 * 0.2).round()),
      labelStyle: TextStyle(color: color),
    );
  }

  Widget _buildEmailField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required.';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
          return 'Please enter a valid email.';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: true,
      validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
    );
  }

  Widget _buildConfirmPasswordField(TextEditingController controller,
      TextEditingController passwordController, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: true,
      validator: (v) {
        if (v != passwordController.text) {
          return 'Passwords do not match';
        }
        if ((v?.length ?? 0) < 6) {
          return 'Min 6 characters';
        }
        return null;
      },
    );
  }
}
