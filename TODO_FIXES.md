# Flutter Analyze Fixes - 162 Issues to 0

## Current Status: 162 issues found

## Phase 2: Fix Flutter Analyze Warnings (162 issues to 0)

### Priority 1: Warnings (Critical)
- [ ] Remove unused imports (multiple files)
- [ ] Fix unused fields and variables
- [ ] Fix unnecessary casts and null operations
- [ ] Fix unreachable code and dead expressions

### Priority 2: Info Issues (Important)
- [ ] Fix deprecated member uses (withOpacity, RadioGroup, etc.)
- [ ] Add super parameters where applicable
- [ ] Fix BuildContext async gaps
- [ ] Remove unnecessary imports
- [ ] Fix string interpolations and other minor issues

### Files with Most Issues:
- lib/screens/auto_lesson_plan_screen.dart: 12 issues
- lib/screens/curriculum_topic_detail_screen.dart: 15 issues
- lib/screens/curriculum_subject_detail_screen.dart: 9 issues
- lib/services/data_validation_service.dart: 7 issues
- lib/services/fee_service.dart: 2 issues
- lib/services/library_service.dart: 2 issues
- lib/services/parent_fee_service.dart: 3 issues

### Common Issues:
- deprecated_member_use: withOpacity -> withValues()
- use_super_parameters: Add super parameters
- use_build_context_synchronously: Fix async context usage
- unused_import: Remove unused imports
- unnecessary_cast: Remove unnecessary casts
- prefer_null_aware_operators: Use ?. instead of explicit null checks

## Progress Tracking
- [ ] Start with warnings (unused imports, fields, variables)
- [ ] Fix deprecated members (withOpacity, RadioGroup)
- [ ] Add super parameters
- [ ] Fix BuildContext issues
- [ ] Clean up remaining info issues
- [ ] Final verification: 0 warnings
