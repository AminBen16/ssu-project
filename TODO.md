# Flutter Errors and Warnings Fix Plan

## Current Status: ANALYZED

## Summary of Issues Found

- **Total Issues:** 647 (ran in 14.5s)
- **Errors:** Multiple critical compilation errors
- **Warnings:** Unused imports, deprecated members, etc.

## Priority Error Fixes (Critical - Must Fix)

### 1. Student List Screen Errors

- [ ] Fix `Student` type not defined - likely missing import or model
- [ ] Fix `StudentService` undefined method
- [ ] Fix null safety issues with `firstName` and `lastName`

### 2. Timetable Generator Screen Errors

- [ ] Fix missing `subject_service.dart` import
- [ ] Fix `TimetableGeneratorService` undefined methods
- [ ] Fix abstract class instantiation issues
- [ ] Fix argument type mismatches

### 3. Curriculum Service Errors

- [ ] Fix missing required parameters in curriculum methods
- [ ] Fix undefined named parameters
- [ ] Fix type argument issues with `Competence`

### 4. Report Card Service Errors

- [ ] Fix syntax errors in try-catch block
- [ ] Fix undefined variables `reportData`
- [ ] Fix missing catch or finally clause

### 5. Auth Service Errors

- [ ] Fix missing `changePassword` method
- [ ] Fix missing `deleteAccount` method
- [ ] Fix missing `currentUser` getter in UserDataProvider

### 6. Fee Collection Screen Errors

- [ ] Fix undefined `getAllPaymentsForSchool` method in ParentFeeService

### 7. Communication Service Errors

- [ ] Fix missing required `license` parameter in bluetooth transport
- [ ] Fix undefined methods in wifi_direct_transport.dart
- [ ] Fix enum constant issues

### 8. Other Service Errors

- [ ] Fix undefined methods in various services (lesson_plan_service, etc.)
- [ ] Fix type assignment issues
- [ ] Fix null safety violations

## Warning Fixes (Lower Priority)

### 1. Unused Imports

- [ ] Remove unused imports across multiple files
- [ ] Clean up unnecessary dependencies

### 2. Deprecated Members

- [ ] Replace deprecated Radio widget properties
- [ ] Update deprecated form field properties
- [ ] Replace deprecated color methods

### 3. Unused Elements

- [ ] Remove unused fields, variables, and methods
- [ ] Clean up dead code

### 4. Code Quality

- [ ] Fix unnecessary braces in string interpolation
- [ ] Add missing type annotations
- [ ] Fix unnecessary casts

## Followup Steps

- [ ] Run flutter analyze after each major fix
- [ ] Test compilation after error fixes
- [ ] Validate app functionality
- [ ] Ensure no regressions introduced

## Blocked Items

- Platform Channels: BLOCKED (external SDK dependencies)
