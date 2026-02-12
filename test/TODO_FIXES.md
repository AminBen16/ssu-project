# Flutter Code Fixes - TODO List

## Phase 1: Critical Errors (3 issues)
- [ ] Fix curriculum_database_service.dart - 'Competency' type not defined
- [ ] Fix curriculum_service.dart - unchecked_use_of_nullable_value

## Phase 2: Service Layer Fixes
- [ ] Fix data_validation_service.dart - invalid_null_aware_operator, unnecessary_null_comparison
- [ ] Fix fee_service.dart - unnecessary_cast (2 issues)
- [ ] Fix library_service.dart - unnecessary_cast (2 issues)
- [ ] Fix parent_fee_service.dart - unnecessary_cast (3 issues)
- [ ] Fix school_service.dart - override_on_non_overriding_member

## Phase 3: Communication Services
- [ ] Fix bluetooth_transport.dart - deprecated_member_use, unnecessary_null_comparison
- [ ] Fix encryption_service.dart - unused_local_variable
- [ ] Fix transport_layer.dart - avoid_print
- [ ] Remove unnecessary imports in lora_transport.dart, satellite_transport.dart, transport_manager.dart, wifi_direct_transport.dart
- [ ] Fix dangling_library_doc_comments in final_system_validation.dart, mvp_implementation_plan.dart

## Phase 4: Screen/UI Fixes
- [ ] Fix appearance_settings_screen.dart - deprecated Radio APIs
- [ ] Fix auto_lesson_plan_screen.dart - use_super_parameters, library_private_types_in_public_api, prefer_final_fields, deprecated value, use_build_context_synchronously
- [ ] Fix book_catalog_screen.dart - use_build_context_synchronously (9 issues)
- [ ] Fix curriculum_integrity_audit_screen.dart - use_super_parameters, library_private_types_in_public_api, unnecessary_to_list_in_spreads, deprecated withOpacity
- [ ] Fix curriculum_management_screen.dart - library_private_types_in_public_api, use_super_parameters
- [ ] Fix curriculum_subject_detail_screen.dart - library_private_types_in_public_api, use_build_context_synchronously
- [ ] Fix curriculum_topic_detail_screen.dart - library_private_types_in_public_api, use_build_context_synchronously (many)
- [ ] Fix dashboard_screen.dart - unreachable_switch_default
- [ ] Fix exams_screen.dart - prefer_null_aware_operators
- [ ] Fix expense_reports_screen.dart - deprecated withOpacity
- [ ] Fix financial_reports_screen.dart - deprecated withOpacity
- [ ] Fix pending_user_screen.dart - use_build_context_synchronously
- [ ] Fix privacy_settings_screen.dart - use_build_context_synchronously
- [ ] Fix school_budget_screen.dart - unused_local_variable, deprecated withOpacity
- [ ] Fix student_borrowing_screen.dart - dead_null_aware_expression, use_build_context_synchronously
- [ ] Fix syllabus_browser_screen.dart - unnecessary_import, use_super_parameters, library_private_types_in_public_api, use_build_context_synchronously, deprecated withOpacity

## Phase 5: Other Services
- [ ] Fix enrollment_service.dart - unused_import
- [ ] Fix error_handling_service.dart - unused_import, unused_field, unrelated_type_equality_checks
- [ ] Fix incremental_sync_service.dart - unused_import
- [ ] Fix marks_service.dart - unused_import
- [ ] Fix ncdc_curriculum_parser.dart - unused_local_variable, unused_element (2)
- [ ] Fix notification_service.dart - unused_import (2)
- [ ] Fix parent_fee_service.dart - unused_import (3)
- [ ] Fix pdf_service.dart - unused_import
- [ ] Fix report_card_service.dart - unused_import
- [ ] Fix staff_auth_service.dart - use_build_context_synchronously
- [ ] Fix staff_enrollment_service.dart - unused_import
- [ ] Fix sync_conflict_resolution_service.dart - unused_import, unused_field
- [ ] Fix teacher_communication_service.dart - unused_local_variable (2)
- [ ] Fix timetable_generator_service.dart - unused_import (2), unused_local_variable
- [ ] Fix user_profile_service.dart - unused_shown_name
- [ ] Fix web_safe_local_database.dart - unused_local_variable

## Phase 6: Navigation & Models
- [ ] Fix app_router.dart - unrelated_type_equality_checks
- [ ] Fix curriculum_integrity_audit_service.dart - unused_local_variable (2)
- [ ] Fix ncdc_exam_generator.dart - prefer_interpolation_to_compose_strings

## Phase 7: Final Verification
- [ ] Run flutter analyze to verify 0 issues
- [ ] Run flutter build to ensure no build errors
