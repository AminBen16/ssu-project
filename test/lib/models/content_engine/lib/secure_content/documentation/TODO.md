# TODO Implementation Plan

## 1. Implement proper local cache update mechanism with studentId tracking in notification_service.dart
- Add notifications table to local_database_service.dart
- Modify _updateLocalNotificationReadStatus method to update cache with studentId tracking

## 2. Implement subjects property in UserProfile model
- Add subjects getter that converts subjectCodes to Subject objects
- Ensure Subject model is available

## 3. Implement employmentStatus property in UserProfile model
- Add employmentStatus field to UserProfile
- Update fromMap and toMap methods
- Add to copyWith method

## 4. Update view_staff_screen.dart to use the new properties
- Replace TODO comments with actual logic using subjects and employmentStatus properties

## 5. Test the changes
- Verify that the notification cache updates work correctly
- Verify that staff filtering works with subjects and employment status
