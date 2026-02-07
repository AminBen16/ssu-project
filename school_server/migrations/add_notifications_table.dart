import 'package:sqlite3/sqlite3.dart';

/// Migration to add notifications table
void addNotificationsTable(Database db) {
  print('Adding notifications table...');
  
  try {
    // Check if notifications table already exists
    final result = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='notifications'").select();
    bool hasNotificationsTable = result.isNotEmpty;
    
    if (!hasNotificationsTable) {
      print('Creating notifications table...');
      db.execute('''
        CREATE TABLE notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'general',
          priority TEXT NOT NULL DEFAULT 'medium',
          target_type TEXT NOT NULL DEFAULT 'all',
          target_id TEXT,
          action_url TEXT,
          is_read BOOLEAN DEFAULT FALSE,
          read_at DATETIME,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Create indexes for better performance
      db.execute('CREATE INDEX idx_notifications_target ON notifications(target_type, target_id)');
      db.execute('CREATE INDEX idx_notifications_read ON notifications(is_read)');
      db.execute('CREATE INDEX idx_notifications_created ON notifications(created_at DESC)');
      
      print('Notifications table created successfully!');
    } else {
      print('Notifications table already exists.');
    }
    
    // Add some sample notifications for testing
    final sampleNotifications = [
      {
        'title': 'Welcome to School!',
        'message': 'Your account has been successfully created. Explore your dashboard to get started.',
        'type': 'announcement',
        'priority': 'medium',
        'target_type': 'all',
      },
      {
        'title': 'Upcoming Exam',
        'message': 'Mathematics Paper 1 is scheduled for next Monday. Please prepare well.',
        'type': 'exam',
        'priority': 'high',
        'target_type': 'all',
      },
      {
        'title': 'Fee Payment Reminder',
        'message': 'Your school fees for this term are due. Please make payment at the earliest.',
        'type': 'fee',
        'priority': 'medium',
        'target_type': 'all',
      },
    ];
    
    // Insert sample notifications
    for (final notification in sampleNotifications) {
      db.execute('''
        INSERT INTO notifications (title, message, type, priority, target_type, target_id)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        notification['title'],
        notification['message'],
        notification['type'],
        notification['priority'],
        notification['target_type'],
        notification['target_id'],
      ]);
    }
    
    print('Sample notifications added successfully!');
    
  } catch (e) {
    print('Error creating notifications table: $e');
    rethrow;
  }
}
