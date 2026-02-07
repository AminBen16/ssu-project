import 'dart:typed_data';
import 'package:test/models/student_model.dart';
import 'package:test/models/user_profile.dart';

class ExportService {
  /// Export students to Excel format (CSV)
  static Future<String> exportStudentsToExcel(List<Student> students) async {
    final csvData = <List<String>>[];
    
    // Add header
    csvData.add([
      'Student ID',
      'Registration ID',
      'First Name',
      'Last Name',
      'Class',
      'Gender',
      'Date of Birth',
      'Phone Number',
      'Address',
      'Parent Name',
      'Parent Contact',
      'Admission Number',
      'Special Needs'
    ]);
    
    // Add student data
    for (final student in students) {
      csvData.add([
        student.id,
        student.studentRegId ?? '',
        student.firstName,
        student.lastName,
        student.className,
        student.sex ?? '',
        student.dateOfBirth ?? '',
        student.phoneNumber ?? '',
        student.address ?? '',
        student.parentName ?? '',
        student.parentContact ?? '',
        student.admissionNumber ?? '',
        student.specialNeeds ?? '',
      ]);
    }
    
    // Convert to CSV string
    return csvData
        .map((row) => row.map((cell) => '"${cell.toString().replaceAll('"', '""')}"').join(','))
        .join('\n');
  }

  /// Export students to PDF format
  static Future<Uint8List> exportStudentsToPDF(List<Student> students) async {
    final pdfContent = StringBuffer();
    pdfContent.writeln('STUDENT LIST REPORT');
    pdfContent.writeln('=' * 50);
    pdfContent.writeln('Generated: ${DateTime.now().toString()}');
    pdfContent.writeln('Total Students: ${students.length}');
    pdfContent.writeln('');
    
    for (final student in students) {
      pdfContent.writeln('Student ID: ${student.id}');
      pdfContent.writeln('Name: ${student.fullName}');
      pdfContent.writeln('Class: ${student.className}');
      if (student.studentRegId != null) {
        pdfContent.writeln('Reg ID: ${student.studentRegId}');
      }
      if (student.sex != null) {
        pdfContent.writeln('Gender: ${student.sex}');
      }
      if (student.parentName != null) {
        pdfContent.writeln('Parent: ${student.parentName}');
      }
      pdfContent.writeln('-' * 30);
      pdfContent.writeln('');
    }
    
    return Uint8List.fromList(pdfContent.toString().codeUnits);
  }

  /// Export staff to Excel format (CSV)
  static Future<String> exportStaffToExcel(List<UserProfile> staff) async {
    final csvData = <List<String>>[];
    
    // Add header
    csvData.add([
      'Staff ID',
      'First Name',
      'Last Name',
      'Email',
      'Phone Number',
      'Role',
      'Employment Status',
      'Salary',
      'Date Joined'
    ]);
    
    // Add staff data
    for (final staffMember in staff) {
      csvData.add([
        staffMember.uid,
        staffMember.firstName ?? '',
        staffMember.lastName ?? '',
        staffMember.email,
        staffMember.phoneNumber ?? '',
        staffMember.role.displayName,
        'Active', // Default status since employmentStatus is not available
        staffMember.salary?.toString() ?? '0',
        '', // Date joined - using empty string since createdAt is not available
      ]);
    }
    
    // Convert to CSV string
    return csvData
        .map((row) => row.map((cell) => '"${cell.toString().replaceAll('"', '""')}"').join(','))
        .join('\n');
  }

  /// Export staff to PDF format
  static Future<Uint8List> exportStaffToPDF(List<UserProfile> staff) async {
    final pdfContent = StringBuffer();
    pdfContent.writeln('STAFF LIST REPORT');
    pdfContent.writeln('=' * 50);
    pdfContent.writeln('Generated: ${DateTime.now().toString()}');
    pdfContent.writeln('Total Staff: ${staff.length}');
    pdfContent.writeln('');
    
    for (final staffMember in staff) {
      pdfContent.writeln('Staff ID: ${staffMember.uid}');
      pdfContent.writeln('Name: ${staffMember.fullName}');
      pdfContent.writeln('Email: ${staffMember.email}');
      pdfContent.writeln('Role: ${staffMember.role.displayName}');
      if (staffMember.phoneNumber != null) {
        pdfContent.writeln('Phone: ${staffMember.phoneNumber}');
      }
      if (staffMember.salary != null) {
        pdfContent.writeln('Salary: UGX ${staffMember.salary}');
      }
      pdfContent.writeln('-' * 30);
      pdfContent.writeln('');
    }
    
    return Uint8List.fromList(pdfContent.toString().codeUnits);
  }
}
