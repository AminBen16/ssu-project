enum UserRole {
  pending,
  chiefAdmin,
  headTeacher,
  director,
  deputyHeadTeacher,
  systemAdmin,
  teacher,
  student,
  parent,
  nonTeachingStaff,
  classTeacher,
  headOfDepartment,
  directorOfStudies,
  schoolAdmin,
  // Ugandan School Non-Teaching Roles
  bursar,
  schoolSecretary,
  librarian,
  labTechnician,
  computerLabAttendant,
  schoolNurse,
  counselor,
  securityGuard,
  caretaker,
  cook,
  driver,
  storeKeeper,
  boardingMaster,
  unknown;

  String get displayName {
    switch (this) {
      case UserRole.pending:
        return 'Pending';
      case UserRole.chiefAdmin:
        return 'Chief Admin';
      case UserRole.headTeacher:
        return 'Head Teacher';
      case UserRole.director:
        return 'Director';
      case UserRole.deputyHeadTeacher:
        return 'Deputy Head Teacher';
      case UserRole.systemAdmin:
        return 'System Admin';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.nonTeachingStaff:
        return 'Non-Teaching Staff';
      case UserRole.classTeacher:
        return 'Class Teacher';
      case UserRole.headOfDepartment:
        return 'Head of Department';
      case UserRole.directorOfStudies:
        return 'Director of Studies';
      case UserRole.schoolAdmin:
        return 'School Admin';
      case UserRole.bursar:
        return 'Bursar';
      case UserRole.schoolSecretary:
        return 'School Secretary';
      case UserRole.librarian:
        return 'Librarian';
      case UserRole.labTechnician:
        return 'Lab Technician';
      case UserRole.computerLabAttendant:
        return 'Computer Lab Attendant';
      case UserRole.schoolNurse:
        return 'School Nurse';
      case UserRole.counselor:
        return 'Counselor';
      case UserRole.securityGuard:
        return 'Security Guard';
      case UserRole.caretaker:
        return 'Caretaker';
      case UserRole.cook:
        return 'Cook';
      case UserRole.driver:
        return 'Driver';
      case UserRole.storeKeeper:
        return 'Store Keeper';
      case UserRole.boardingMaster:
        return 'Boarding Master';
      case UserRole.unknown:
        return 'Unknown';
    }
  }

  /// A factory method to create a UserRole from a string.
  /// It's case-insensitive.
  static UserRole fromString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'pending':
        return UserRole.pending;
      case 'chief_admin':
        return UserRole.chiefAdmin;
      case 'head_teacher':
        return UserRole.headTeacher;
      case 'director':
        return UserRole.director;
      case 'deputy_head_teacher':
        return UserRole.deputyHeadTeacher;
      case 'it_admin':
      case 'system_admin':
        return UserRole.systemAdmin;
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      case 'parent':
        return UserRole.parent;
      case 'non_teaching_staff':
        return UserRole.nonTeachingStaff;
      case 'class_teacher':
        return UserRole.classTeacher;
      case 'head_of_department':
        return UserRole.headOfDepartment;
      case 'director_of_studies':
        return UserRole.directorOfStudies;
      case 'school_admin':
        return UserRole.schoolAdmin;
      case 'bursar':
        return UserRole.bursar;
      case 'school_secretary':
        return UserRole.schoolSecretary;
      case 'librarian':
        return UserRole.librarian;
      case 'lab_technician':
        return UserRole.labTechnician;
      case 'computer_lab_attendant':
        return UserRole.computerLabAttendant;
      case 'school_nurse':
        return UserRole.schoolNurse;
      case 'counselor':
        return UserRole.counselor;
      case 'security_guard':
        return UserRole.securityGuard;
      case 'caretaker':
        return UserRole.caretaker;
      case 'cook':
        return UserRole.cook;
      case 'driver':
        return UserRole.driver;
      case 'store_keeper':
        return UserRole.storeKeeper;
      case 'boarding_master':
        return UserRole.boardingMaster;
      default:
        return UserRole.unknown;
    }
  }

  static List<UserRole> get allStaffRoles => [
        UserRole.headTeacher,
        UserRole.director,
        UserRole.deputyHeadTeacher,
        UserRole.systemAdmin,
        UserRole.teacher,
        UserRole.classTeacher,
        UserRole.headOfDepartment,
        UserRole.directorOfStudies,
        UserRole.nonTeachingStaff,
        // Ugandan School Non-Teaching Roles
        UserRole.bursar,
        UserRole.schoolSecretary,
        UserRole.librarian,
        UserRole.labTechnician,
        UserRole.computerLabAttendant,
        UserRole.schoolNurse,
        UserRole.counselor,
        UserRole.securityGuard,
        UserRole.caretaker,
        UserRole.cook,
        UserRole.driver,
        UserRole.storeKeeper,
        UserRole.boardingMaster,
      ];

  static List<UserRole> get allNonTeachingRoles => [
        UserRole.nonTeachingStaff,
        // Ugandan School Non-Teaching Roles
        UserRole.bursar,
        UserRole.schoolSecretary,
        UserRole.librarian,
        UserRole.labTechnician,
        UserRole.computerLabAttendant,
        UserRole.schoolNurse,
        UserRole.counselor,
        UserRole.securityGuard,
        UserRole.caretaker,
        UserRole.cook,
        UserRole.driver,
        UserRole.storeKeeper,
        UserRole.boardingMaster,
      ];

  static List<UserRole> get allTeachingRoles => [
        UserRole.teacher,
        UserRole.classTeacher,
        UserRole.headOfDepartment,
        UserRole.directorOfStudies,
      ];

  static Set<UserRole> get adminRoles => {
        UserRole.headTeacher,
        UserRole.director,
        UserRole.deputyHeadTeacher,
        UserRole.systemAdmin,
      };

  /// Roles that can enroll new users in a school
  static Set<UserRole> get enrollmentRoles => {
        UserRole.schoolAdmin,
        UserRole.systemAdmin,
      };

  /// Converts this UserRole to the server-compatible role string
  String toServerRole() {
    switch (this) {
      case UserRole.teacher:
        return 'teacher';
      case UserRole.classTeacher:
        return 'class_teacher';
      case UserRole.headOfDepartment:
        return 'head_of_department';
      case UserRole.directorOfStudies:
        return 'director_of_studies';
      case UserRole.headTeacher:
        return 'head_teacher';
      case UserRole.director:
        return 'director';
      case UserRole.deputyHeadTeacher:
        return 'deputy_head_teacher';
      case UserRole.systemAdmin:
        return 'system_admin';
      case UserRole.nonTeachingStaff:
        return 'non_teaching_staff';
      case UserRole.student:
        return 'student';
      case UserRole.parent:
        return 'parent';
      case UserRole.bursar:
        return 'bursar';
      case UserRole.schoolSecretary:
        return 'school_secretary';
      case UserRole.librarian:
        return 'librarian';
      case UserRole.labTechnician:
        return 'lab_technician';
      case UserRole.computerLabAttendant:
        return 'computer_lab_attendant';
      case UserRole.schoolNurse:
        return 'school_nurse';
      case UserRole.counselor:
        return 'counselor';
      case UserRole.securityGuard:
        return 'security_guard';
      case UserRole.caretaker:
        return 'caretaker';
      case UserRole.cook:
        return 'cook';
      case UserRole.driver:
        return 'driver';
      case UserRole.storeKeeper:
        return 'store_keeper';
      case UserRole.boardingMaster:
        return 'boarding_master';
      default:
        return 'teacher'; // Default fallback
    }
  }

  bool get isTeacher => allTeachingRoles.contains(this);

  /// Returns the default list of feature keys available for this role.
  /// Used to dynamically render dashboard tiles.
  List<String> get defaultFeatures {
    switch (this) {
      case UserRole.schoolNurse:
        return ['medical_records', 'incident_reporting', 'inventory_medical'];
      case UserRole.driver:
        return [
          'vehicle_logs',
          'route_management',
          'fuel_tracking',
          'trip_scheduling'
        ];
      case UserRole.cook:
        return [
          'kitchen_inventory',
          'meal_planning',
          'supplier_orders',
          'dietary_requirements'
        ];
      case UserRole.securityGuard:
        return [
          'visitor_logs',
          'incident_reporting',
          'patrol_checkpoints',
          'gate_pass'
        ];
      case UserRole.librarian:
        return [
          'book_catalog',
          'issue_return',
          'fine_management',
          'digital_resources'
        ];
      case UserRole.bursar:
        return ['fee_collection', 'expenses', 'payroll', 'financial_reports'];
      case UserRole.storeKeeper:
        return [
          'inventory_general',
          'requisitions',
          'stock_taking',
          'supplier_management'
        ];
      case UserRole.boardingMaster:
        return [
          'dormitory_allocation',
          'roll_call',
          'exeat_management',
          'discipline_records'
        ];
      case UserRole.labTechnician:
      case UserRole.computerLabAttendant:
        return [
          'lab_inventory',
          'equipment_maintenance',
          'practical_schedules'
        ];
      case UserRole.schoolSecretary:
        return [
          'front_desk',
          'appointments',
          'communications',
          'student_records'
        ];
      case UserRole.counselor:
        return ['counseling_sessions', 'student_welfare', 'confidential_notes'];
      case UserRole.systemAdmin:
      case UserRole.schoolAdmin:
      case UserRole.chiefAdmin:
      case UserRole.headTeacher:
        return [
          'admin_dashboard_full',
          'user_management',
          'reports',
          'settings'
        ];
      default:
        // Default fallback for generic staff or teachers
        return [
          'dashboard_overview',
          'attendance',
          'profile',
          'announcements',
          'staff_directory'
        ];
    }
  }
}
