import 'package:flutter/material.dart';
import 'package:test/models/student_model.dart';
import 'package:test/services/student_service.dart';
import 'package:test/widgets/section_card.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Student _student;
  final StudentService _studentService = StudentService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _loadStudentDetails();
  }

  Future<void> _loadStudentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updatedStudent = await _studentService.getStudent(_student.id);
      if (mounted) {
        setState(() {
          _student = updatedStudent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load student details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_student.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudentDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStudentDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildStudentDetails(),
    );
  }

  Widget _buildStudentDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Avatar and Basic Info
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    _student.firstName.isNotEmpty
                        ? _student.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _student.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (_student.studentRegId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${_student.studentRegId}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Personal Information Section
          SectionCard(
            title: 'Personal Information',
            children: [
              _buildInfoRow('First Name', _student.firstName),
              _buildInfoRow('Last Name', _student.lastName),
              if (_student.studentRegId != null)
                _buildInfoRow(
                    'Student Registration ID', _student.studentRegId!),
              _buildInfoRow('Student ID', _student.id),
              if (_student.dateOfBirth != null)
                _buildInfoRow('Date of Birth', _student.dateOfBirth!),
              if (_student.sex != null)
                _buildInfoRow('Sex', _student.sex!),
              if (_student.religion != null)
                _buildInfoRow('Religion', _student.religion!),
              if (_student.phoneNumber != null)
                _buildInfoRow('Phone Number', _student.phoneNumber!),
              if (_student.address != null)
                _buildInfoRow('Address', _student.address!),
              if (_student.specialNeeds != null)
                _buildInfoRow('Special Needs', _student.specialNeeds!),
              if (_student.admissionNumber != null)
                _buildInfoRow('Admission Number', _student.admissionNumber!),
            ],
          ),
          const SizedBox(height: 16),

          // Academic Information Section
          SectionCard(
            title: 'Academic Information',
            children: [
              _buildInfoRow('Class', _student.className),
              _buildInfoRow('School ID', _student.schoolId),
            ],
          ),
          const SizedBox(height: 16),

          // Parent Information Section
          if (_student.parentName != null || _student.parentNin != null || _student.parentContact != null)
            SectionCard(
              title: 'Parent Information',
              children: [
                if (_student.parentName != null)
                  _buildInfoRow('Parent Name', _student.parentName!),
                if (_student.parentNin != null)
                  _buildInfoRow('Parent NIN', _student.parentNin!),
                if (_student.parentContact != null)
                  _buildInfoRow('Parent Contact', _student.parentContact!),
              ],
            ),
          if (_student.parentName != null || _student.parentNin != null || _student.parentContact != null)
            const SizedBox(height: 16),

          // Parents Section
          if (_student.parentNames.isNotEmpty) ...[
            SectionCard(
              title: 'Parents',
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _student.parentNames.map((parentName) {
                    return Chip(
                      label: Text(parentName),
                      backgroundColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Subjects Section
          if (_student.subjectNames.isNotEmpty) ...[
            SectionCard(
              title: 'Subjects',
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _student.subjectNames.map((subjectName) {
                    return Chip(
                      label: Text(subjectName),
                      backgroundColor: Theme.of(context)
                          .secondaryHeaderColor
                          .withValues(alpha: 0.1),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not specified',
              style: TextStyle(
                color: value.isNotEmpty ? null : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
