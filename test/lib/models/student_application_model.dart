enum ApplicationStatus { pending, approved, rejected }

class StudentApplication {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String className;
  final String sex;
  final String parentName;
  final String parentContact;
  final String parentNin;
  final String? parentEmail;
  final String address;
  final ApplicationStatus status;
  final DateTime
      applicationDate; // Assuming this comes as a string or timestamp
  final String? paymentReference;
  final List<String> subjectCodes;

  StudentApplication({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.className,
    required this.sex,
    required this.parentName,
    required this.parentContact,
    required this.parentNin,
    this.parentEmail,
    required this.address,
    required this.status,
    required this.applicationDate,
    this.paymentReference,
    this.subjectCodes = const [],
  });

  /// Creates a StudentApplication object from a JSON map.
  factory StudentApplication.fromMap(Map<String, dynamic> data) {
    // Helper to parse the status string into an enum, defaulting to pending.
    ApplicationStatus getStatus(String? statusString) {
      return ApplicationStatus.values.firstWhere(
        (e) => e.name == statusString,
        orElse: () => ApplicationStatus.pending,
      );
    }

    // Helper to safely parse dates, whether they are ISO strings or timestamps.
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      // Return a default date if the format is unexpected.
      return DateTime.now();
    }

    return StudentApplication(
      id: data['id'] as String,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      dateOfBirth: parseDate(data['dateOfBirth']),
      className: data['className'] ?? '',
      parentName: data['parentName'] ?? '',
      parentNin: data['parentNin'] ?? '',
      sex: data['sex'] ?? '',
      address: data['address'] ?? '',
      parentContact: data['parentContact'] ?? '',
      parentEmail: data['parentEmail'],
      applicationDate: parseDate(data['applicationDate']),
      subjectCodes: List<String>.from(data['subjectCodes'] ?? []),
      paymentReference: data['paymentReference'],
      status: getStatus(data['status']),
    );
  }
}
