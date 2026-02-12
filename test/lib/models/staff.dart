import 'package:test/models/user_roles.dart';
import 'package:test/models/user_profile.dart';

class Staff {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? schoolId;
  final Map<String, dynamic>? profile;
  final UserRole? role;
  final List<String>? subjectCodes;
  final List<String>? teachingDays;
  final String? qualification;
  final int? maxPeriodsPerDay;
  final int? maxConsecutivePeriods;
  final List<String>? preferredTimeSlots;
  final List<String>? preferredDays;
  final List<String>? assignedSubjects;
  final List<Map<String, dynamic>>? qualifications;
  final int? yearsOfExperience;

  Staff({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.schoolId,
    this.profile,
    this.role,
    this.subjectCodes,
    this.teachingDays,
    this.qualification,
    this.maxPeriodsPerDay,
    this.maxConsecutivePeriods,
    this.preferredTimeSlots,
    this.preferredDays,
    this.assignedSubjects,
    this.qualifications,
    this.yearsOfExperience,
  });

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'schoolId': schoolId,
      'profile': profile,
      'role': role?.name,
      'subjectCodes': subjectCodes,
      'teachingDays': teachingDays,
      'qualification': qualification,
      'maxPeriodsPerDay': maxPeriodsPerDay,
      'maxConsecutivePeriods': maxConsecutivePeriods,
      'preferredTimeSlots': preferredTimeSlots,
      'preferredDays': preferredDays,
      'assignedSubjects': assignedSubjects,
      'qualifications': qualifications,
      'yearsOfExperience': yearsOfExperience,
    };
  }

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      schoolId: map['schoolId'] as String?,
      profile: map['profile'] as Map<String, dynamic>?,
      role: map['role'] != null
          ? UserRole.fromString(map['role'] as String)
          : null,
      subjectCodes: (map['subjectCodes'] as List<dynamic>?)?.cast<String>(),
      teachingDays: (map['teachingDays'] as List<dynamic>?)?.cast<String>(),
      qualification: map['qualification'] as String?,
      maxPeriodsPerDay: map['maxPeriodsPerDay'] as int?,
      maxConsecutivePeriods: map['maxConsecutivePeriods'] as int?,
      preferredTimeSlots:
          (map['preferredTimeSlots'] as List<dynamic>?)?.cast<String>(),
      preferredDays: (map['preferredDays'] as List<dynamic>?)?.cast<String>(),
      assignedSubjects:
          (map['assignedSubjects'] as List<dynamic>?)?.cast<String>(),
      qualifications: (map['qualifications'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      yearsOfExperience: map['yearsOfExperience'] as int?,
    );
  }

  UserProfile toUserProfile() {
    return UserProfile(
      id: id,
      uid: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role ?? UserRole.pending,
      schoolId: schoolId,
      profilePictureUrl: profile?['profilePictureUrl'] as String?,
      phoneNumber: phoneNumber,
      qualification: qualification,
      subjectCodes: subjectCodes,
      teachingDays: teachingDays,
    );
  }
}
