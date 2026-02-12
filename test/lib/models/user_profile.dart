import 'package:test/models/user_roles.dart';

class UserProfile {
  final String id;
  final String uid;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool isFirstTimeSetupComplete;
  final UserRole role;
  final String? preferredLanguage;
  final String? schoolId;
  final String? themeMode;
  final int? themeColor;
  final String? profilePictureUrl;
  final String? qualification;
  final String? title;
  final String? phoneNumber;
  final String? address;
  final String? nin;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? maritalStatus;
  final List<String>? subjectCodes;
  final List<String>? teachingDays;
  final List<String>? teachingClasses;
  final String? userRegId;
  final double? salary;
  final double? allowances;
  final String? plan;
  final String? employmentStatus;

  UserProfile({
    required this.id,
    required this.uid,
    required this.email,
    this.firstName,
    this.lastName,
    this.isFirstTimeSetupComplete = false,
    this.role = UserRole.pending,
    this.preferredLanguage,
    this.schoolId,
    this.themeMode,
    this.themeColor,
    this.profilePictureUrl,
    this.qualification,
    this.title,
    this.phoneNumber,
    this.address,
    this.nin,
    this.dateOfBirth,
    this.sex,
    this.maritalStatus,
    this.subjectCodes,
    this.teachingDays,
    this.teachingClasses,
    this.userRegId,
    this.salary,
    this.allowances,
    this.plan,
    this.employmentStatus,
  })  : assert(id.isNotEmpty, 'id cannot be empty'),
        assert(uid.isNotEmpty, 'uid cannot be empty'),
        assert(email.isNotEmpty, 'email cannot be empty');

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  List<String> get subjects => subjectCodes ?? [];

  factory UserProfile.fromMap(Map<String, dynamic> data, String documentId) {
    return UserProfile(
      id: documentId,
      uid: data['id']?.toString() ?? data['uid']?.toString() ?? documentId,
      email: data['email']?.toString() ?? '',
      firstName: data['first_name']?.toString() ?? '',
      lastName: data['last_name']?.toString() ?? '',
      isFirstTimeSetupComplete: data['is_first_time_setup_complete'] is bool
          ? data['is_first_time_setup_complete']
          : (data['is_first_time_setup_complete']?.toString() == '1' ||
              data['is_first_time_setup_complete']?.toString().toLowerCase() ==
                  'true'),
      role: UserRole.fromString(data['role']?.toString() ?? 'pending'),
      preferredLanguage: data['preferred_language']?.toString() ?? '',
      schoolId: (data['school_id']?.toString() ?? '').isEmpty
          ? null
          : data['school_id'].toString(),
      themeMode: data['theme_mode']?.toString() ?? '',
      themeColor: data['theme_color'] is int
          ? data['theme_color'] as int
          : int.tryParse(data['theme_color']?.toString() ?? ''),
      profilePictureUrl: (data['profile_picture_url']?.toString() ?? '').isEmpty
          ? null
          : data['profile_picture_url'].toString(),
      qualification: data['qualification']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      phoneNumber: data['phone_number']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      nin: data['nin']?.toString() ?? '',
      dateOfBirth: data['date_of_birth'] != null
          ? DateTime.tryParse(data['date_of_birth'].toString())
          : null,
      sex: data['sex']?.toString() ?? '',
      maritalStatus: data['marital_status']?.toString() ?? '',
      subjectCodes: (data['subject_codes'] as List<dynamic>?)?.cast<String>(),
      teachingDays: (data['teaching_days'] as List<dynamic>?)?.cast<String>(),
      teachingClasses:
          (data['teaching_classes'] as List<dynamic>?)?.cast<String>(),
      userRegId: data['user_reg_id']?.toString() ?? '',
      salary: (data['salary'] as num?)?.toDouble(),
      allowances: (data['allowances'] as num?)?.toDouble(),
      plan: data['plan']?.toString() ?? '',
      employmentStatus: data['employment_status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'is_first_time_setup_complete': isFirstTimeSetupComplete,
      'role': role.name,
      'preferred_language': preferredLanguage,
      'school_id': schoolId,
      'themeMode': themeMode,
      'theme_color': themeColor,
      'profile_picture_url': profilePictureUrl,
      'qualification': qualification,
      'title': title,
      'phone_number': phoneNumber,
      'address': address,
      'nin': nin,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'sex': sex,
      'marital_status': maritalStatus,
      'subject_codes': subjectCodes,
      'teaching_days': teachingDays,
      'teaching_classes': teachingClasses,
      'user_reg_id': userRegId,
      'salary': salary,
      'allowances': allowances,
      'plan': plan,
      'employment_status': employmentStatus,
    };
  }

  UserProfile copyWith({
    String? id,
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    bool? isFirstTimeSetupComplete,
    UserRole? role,
    String? preferredLanguage,
    String? schoolId,
    String? themeMode,
    int? themeColor,
    String? profilePictureUrl,
    String? qualification,
    String? title,
    String? phoneNumber,
    String? address,
    String? nin,
    DateTime? dateOfBirth,
    String? sex,
    String? maritalStatus,
    List<String>? subjectCodes,
    List<String>? teachingDays,
    List<String>? teachingClasses,
    String? userRegId,
    double? salary,
    double? allowances,
    String? plan,
    String? employmentStatus,
  }) {
    return UserProfile(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isFirstTimeSetupComplete:
          isFirstTimeSetupComplete ?? this.isFirstTimeSetupComplete,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      qualification: qualification ?? this.qualification,
      title: title ?? this.title,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      nin: nin ?? this.nin,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      subjectCodes: subjectCodes ?? this.subjectCodes,
      teachingDays: teachingDays ?? this.teachingDays,
      teachingClasses: teachingClasses ?? this.teachingClasses,
      userRegId: userRegId ?? this.userRegId,
      salary: salary ?? this.salary,
      allowances: allowances ?? this.allowances,
      plan: plan ?? this.plan,
      employmentStatus: employmentStatus ?? this.employmentStatus,
    );
  }
}
