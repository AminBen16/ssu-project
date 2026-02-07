import 'package:sqlite3/sqlite3.dart';

/// Migration to add email verification fields
void addEmailVerificationFields(Database db) {
  print('Adding email verification fields...');
  
  try {
    // Check if email verification columns already exist
    final result = db.prepare("SELECT name FROM pragma_table_info('users') WHERE name IN ('email_verified', 'verification_token', 'verification_expires')").select();
    bool hasEmailVerified = result.any((row) => row['name'] == 'email_verified');
    bool hasVerificationToken = result.any((row) => row['name'] == 'verification_token');
    bool hasVerificationExpires = result.any((row) => row['name'] == 'verification_expires');
    
    if (!hasEmailVerified) {
      print('Adding email_verified column...');
      db.execute('ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE');
    }
    
    if (!hasVerificationToken) {
      print('Adding verification_token column...');
      db.execute('ALTER TABLE users ADD COLUMN verification_token TEXT');
    }
    
    if (!hasVerificationExpires) {
      print('Adding verification_expires column...');
      db.execute('ALTER TABLE users ADD COLUMN verification_expires TEXT');
    }
    
    print('Email verification fields added successfully!');
    
  } catch (e) {
    print('Error adding email verification fields: $e');
    rethrow;
  }
}
