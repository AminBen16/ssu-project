class StudentApplication {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? schoolId;
  final String grade;
  final DateTime? dateOfBirth;

  StudentApplication({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.schoolId,
    required this.grade,
    this.dateOfBirth,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'schoolId': schoolId,
      'grade': grade,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
    };
  }
}
