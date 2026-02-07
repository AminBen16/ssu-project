class Student {
  final String id;
  final String firstName;
  final String? studentRegId; // The new custom student ID
  final String lastName;
  final String className;
  final String schoolId;
  final List<String> parentIds;
  final List<String> parentNames;
  final List<String> subjectCodes;
  final List<String> subjectNames;
  final String? dateOfBirth;
  final String? sex;
  final String? religion;
  final String? phoneNumber;
  final String? address;
  final String? parentName;
  final String? parentNin;
  final String? parentContact;
  final String? specialNeeds;
  final String? admissionNumber;

  Student({
    required this.id,
    required this.firstName,
    this.studentRegId,
    required this.lastName,
    required this.className,
    required this.schoolId,
    this.parentIds = const [],
    this.parentNames = const [],
    this.subjectCodes = const [],
    this.subjectNames = const [],
    this.dateOfBirth,
    this.sex,
    this.religion,
    this.phoneNumber,
    this.address,
    this.parentName,
    this.parentNin,
    this.parentContact,
    this.specialNeeds,
    this.admissionNumber,
  });

  /// Creates a Student object from a map (typically from an API response).
  factory Student.fromMap(Map<String, dynamic> json) {
    return Student(
      id: json['id'].toString(), // Ensure ID is a string
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      // Use a default or nullable value for fields that might not be in the API response yet
      className: json['class_name'] as String? ?? 'N/A',
      schoolId: json['school_id'] as String? ?? '',
      studentRegId: json['student_reg_id'] as String?,
      parentIds: json['parent_ids'] != null
          ? List<String>.from(json['parent_ids'])
          : [],
      parentNames: json['parent_names'] != null
          ? List<String>.from(json['parent_names'])
          : [],
      subjectCodes: json['subject_codes'] != null
          ? List<String>.from(json['subject_codes'])
          : [],
      subjectNames: json['subject_names'] != null
          ? List<String>.from(json['subject_names'])
          : [],
    );
  }

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'class_name': className,
      'school_id': schoolId,
      'student_reg_id': studentRegId,
      'parent_ids': parentIds,
      'parent_names': parentNames,
      'subject_codes': subjectCodes,
      'subject_names': subjectNames,
      'date_of_birth': dateOfBirth,
      'sex': sex,
      'religion': religion,
      'phone_number': phoneNumber,
      'address': address,
      'parent_name': parentName,
      'parent_nin': parentNin,
      'parent_contact': parentContact,
      'special_needs': specialNeeds,
      'admission_number': admissionNumber,
    };
  }
}
