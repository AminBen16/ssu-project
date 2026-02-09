class Staff {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? schoolId;

  Staff({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.schoolId,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'schoolId': schoolId,
    };
  }
}
