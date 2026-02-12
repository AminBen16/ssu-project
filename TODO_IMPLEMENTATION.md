# Implementation Plan for Production Logic

## Information Gathered
- Identified TODOs and placeholders in multiple files from grep searches
- UserProfile model lacks `subjects` and `employmentStatus` properties needed for staff filtering
- NotificationService has TODO for proper local cache update mechanism
- ErrorHandlingService has TODO for real connectivity checking with connectivity_plus
- MarksService has TODO for backend endpoint implementation
- Multiple services (communication, curriculum, etc.) use placeholder/stub implementations
- Current project flow must be maintained, no features removed or commented out

## Plan
1. **Add missing properties to UserProfile model**
   - Add `subjects` property (derived from subjectCodes)
   - Add `employmentStatus` property for staff status filtering

2. **Implement real staff filtering logic in ViewStaffScreen**
   - Replace TODO placeholders with actual property checks
   - Ensure filtering works with new UserProfile properties

3. **Implement proper cache update in NotificationService**
   - Add studentId tracking for local cache updates
   - Implement proper update mechanism for notification read status

4. **Integrate real connectivity checking in ErrorHandlingService**
   - Add connectivity_plus dependency to pubspec.yaml
   - Replace placeholder connectivity check with real implementation

5. **Implement real curriculum data fetching in CurriculumService**
   - Replace placeholder data returns with actual database/API calls
   - Ensure offline fallbacks work properly

6. **Replace stub implementations in communication services**
   - Implement real Wi-Fi Direct, Bluetooth, etc. transport logic
   - Remove all "stub" comments and placeholder returns

7. **Implement backend endpoint logic in MarksService**
   - Add real API calls for student grades endpoint
   - Ensure offline caching works

8. **Fix all Flutter code warnings**
   - Address any linting issues introduced by changes
   - Ensure code compiles without warnings

## Dependent Files to be edited
- test/lib/models/user_profile.dart
- test/lib/screens/view_staff_screen.dart
- test/lib/services/notification_service.dart
- test/lib/services/error_handling_service.dart
- test/lib/services/curriculum_service.dart
- test/lib/services/communication/*.dart (multiple files)
- test/lib/models/marks_service.dart
- test/pubspec.yaml (for connectivity_plus)

## Followup steps
- Run flutter analyze to check for warnings
- Test all implemented features
- Ensure no breaking changes to project flow
- Verify offline functionality still works
