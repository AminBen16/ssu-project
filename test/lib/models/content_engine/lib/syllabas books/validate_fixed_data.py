#!/usr/bin/env python3
"""
Validate the fixed outcome type data
"""

from syllabus_validator import NCDCSyllabusValidator

def main():
    validator = NCDCSyllabusValidator()
    
    print('🔍 VALIDATING FIXED DATA...')
    print('=' * 50)
    
    # Validate fixed O-Level data
    olevel_result = validator.validate_dataset('olevel_syllabus_data_fixed.json')
    print(f'📊 O-LEVEL FIXED RESULTS:')
    print(f'  Status: {"✅ VALID" if olevel_result.is_valid else "❌ INVALID"}')
    print(f'  Total Entries: {olevel_result.stats.get("total_entries", 0)}')
    print(f'  Valid Entries: {olevel_result.stats.get("valid_entries", 0)}')
    print(f'  Invalid Entries: {olevel_result.stats.get("invalid_entries", 0)}')
    print(f'  Errors: {len(olevel_result.errors)}')
    
    # Validate fixed A-Level data
    alevel_result = validator.validate_dataset('alevel_syllabus_data_fixed.json')
    print(f'\n📊 A-LEVEL FIXED RESULTS:')
    print(f'  Status: {"✅ VALID" if alevel_result.is_valid else "❌ INVALID"}')
    print(f'  Total Entries: {alevel_result.stats.get("total_entries", 0)}')
    print(f'  Valid Entries: {alevel_result.stats.get("valid_entries", 0)}')
    print(f'  Invalid Entries: {alevel_result.stats.get("invalid_entries", 0)}')
    print(f'  Errors: {len(alevel_result.errors)}')
    
    # Summary
    total_entries = olevel_result.stats.get('total_entries', 0) + alevel_result.stats.get('total_entries', 0)
    total_valid = olevel_result.stats.get('valid_entries', 0) + alevel_result.stats.get('valid_entries', 0)
    total_errors = len(olevel_result.errors) + len(alevel_result.errors)
    accuracy = (total_valid / total_entries * 100) if total_entries > 0 else 0
    
    print(f'\n🎯 OVERALL RESULTS:')
    print(f'  Total Entries: {total_entries}')
    print(f'  Valid Entries: {total_valid}')
    print(f'  Total Errors: {total_errors}')
    print(f'  Overall Accuracy: {accuracy:.1f}%')
    
    # Show sample errors if any
    if olevel_result.errors:
        print(f'\n❌ O-LEVEL SAMPLE ERRORS:')
        for error in olevel_result.errors[:3]:
            print(f'  - {error}')
    
    if alevel_result.errors:
        print(f'\n❌ A-LEVEL SAMPLE ERRORS:')
        for error in alevel_result.errors[:3]:
            print(f'  - {error}')
    
    return olevel_result, alevel_result

if __name__ == "__main__":
    main()
