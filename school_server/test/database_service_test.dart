import 'package:test/test.dart';
import '../lib/database_service.dart';

void main() {
  late DatabaseService dbService;

  setUp(() async {
    dbService = DatabaseService();
    await dbService.initialize();
  });

  tearDown(() async {
    await dbService.close();
  });

  group('DatabaseService Tests', () {
    test('should initialize database successfully', () async {
      // Database should be initialized in setUp
      expect(dbService, isNotNull);
    });

    test('should create user successfully', () async {
      final userData = await dbService.createUser(
        email: 'test@example.com',
        hashedPassword: 'hashed_password',
        otherData: {
          'first_name': 'John',
          'last_name': 'Doe',
          'role': 'parent',
        },
      );

      expect(userData, isNotNull);
      expect(userData['email'], 'test@example.com');
      expect(userData['first_name'], 'John');
      expect(userData['last_name'], 'Doe');
      expect(userData['role'], 'parent');
    });

    test('should find user by email', () async {
      // First create a user
      await dbService.createUser(
        email: 'find@example.com',
        hashedPassword: 'hashed_password',
        otherData: {'first_name': 'Jane'},
      );

      // Then find the user
      final user = await dbService.findUserByEmail('find@example.com');
      expect(user, isNotNull);
      expect(user!['email'], 'find@example.com');
      expect(user['first_name'], 'Jane');
    });

    test('should return null for non-existent user', () async {
      final user = await dbService.findUserByEmail('nonexistent@example.com');
      expect(user, isNull);
    });

    test('should find user by ID', () async {
      // Create a user first
      final createdUser = await dbService.createUser(
        email: 'idtest@example.com',
        hashedPassword: 'hashed_password',
        otherData: {'first_name': 'ID Test'},
      );

      // Find by ID
      final user = await dbService.findUserById(createdUser['id'].toString());
      expect(user, isNotNull);
      expect(user!['id'], createdUser['id']);
      expect(user['email'], 'idtest@example.com');
    });

    test('should get total user count', () async {
      final initialCount = await dbService.getTotalUserCount();

      // Create a user
      await dbService.createUser(
        email: 'count@example.com',
        hashedPassword: 'hashed_password',
        otherData: {},
      );

      final finalCount = await dbService.getTotalUserCount();
      expect(finalCount, initialCount + 1);
    });

    test('should update user settings', () async {
      // Create a user
      final createdUser = await dbService.createUser(
        email: 'update@example.com',
        hashedPassword: 'hashed_password',
        otherData: {'first_name': 'Original'},
      );

      // Update settings
      await dbService.updateUserSettings(createdUser['id'].toString(), {
        'firstName': 'Updated',
        'lastName': 'Name',
        'phoneNumber': '1234567890',
      });

      // Verify update
      final updatedUser =
          await dbService.findUserById(createdUser['id'].toString());
      expect(updatedUser!['first_name'], 'Updated');
      expect(updatedUser['last_name'], 'Name');
      expect(updatedUser['phone_number'], '1234567890');
    });

    test('should link parent to students', () async {
      // Create a parent user
      final parent = await dbService.createUser(
        email: 'parent@example.com',
        hashedPassword: 'hashed_password',
        otherData: {'first_name': 'Parent'},
      );

      // Test that the linkParentToStudents method can be called without error
      // (even with empty student IDs)
      await dbService.linkParentToStudents(
        parentUserId: parent['id'].toString(),
        studentIds: [],
      );

      // Verify no students are linked
      final linkedStudents =
          await dbService.getStudentsByParentId(parent['id'].toString());
      expect(linkedStudents.length, 0);
    });

    test('should get students by parent ID', () async {
      // Create a parent
      final parent = await dbService.createUser(
        email: 'parent2@example.com',
        hashedPassword: 'hashed_password',
        otherData: {},
      );

      // Test that the method exists and can be called (would return empty list with no linked students)
      final students =
          await dbService.getStudentsByParentId(parent['id'].toString());
      expect(students, isA<List<Map<String, dynamic>>>());
      expect(students.length, 0); // No students linked yet
    });

    test('should handle unique email constraint', () async {
      // Create first user
      await dbService.createUser(
        email: 'unique@example.com',
        hashedPassword: 'password1',
        otherData: {},
      );

      // Try to create another user with same email - should fail
      expect(
        () async => await dbService.createUser(
          email: 'unique@example.com',
          hashedPassword: 'password2',
          otherData: {},
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
