#!/usr/bin/env python3
"""
Validate the final clean data files
"""

from syllabus_validator import NCDCSyllabusValidator

def main():
    validator = NCDCSyllabusValidator()
    
    print('🔍 VALIDATING FINAL CLEAN DATA...')
    print('=' * 50)
    
    # Validate final A-Level data
    alevel_result = validator.validate_dataset('alevel_data.json')
    print(f'📊 A-LEVEL FINAL RESULTS:')
    print(f'  Status: {"✅ VALID" if alevel_result.is_valid else "❌ INVALID"}')
    print(f'  Total Entries: {alevel_result.stats.get("total_entries", 0)}')
    print(f'  Valid Entries: {alevel_result.stats.get("valid_entries", 0)}')
    print(f'  Invalid Entries: {alevel_result.stats.get("invalid_entries", 0)}')
    print(f'  Errors: {len(alevel_result.errors)}')
    
    # Validate final O-Level data
    olevel_result = validator.validate_dataset('olevel_data.json')
    print(f'\n📊 O-LEVEL FINAL RESULTS:')
    print(f'  Status: {"✅ VALID" if olevel_result.is_valid else "❌ INVALID"}')
    print(f'  Total Entries: {olevel_result.stats.get("total_entries", 0)}')
    print(f'  Valid Entries: {olevel_result.stats.get("valid_entries", 0)}')
    print(f'  Invalid Entries: {olevel_result.stats.get("invalid_entries", 0)}')
    print(f'  Errors: {len(olevel_result.errors)}')
    
    # Summary
    total_entries = alevel_result.stats.get('total_entries', 0) + olevel_result.stats.get('total_entries', 0)
    total_valid = alevel_result.stats.get('valid_entries', 0) + olevel_result.stats.get('valid_entries', 0)
    total_errors = len(alevel_result.errors) + len(olevel_result.errors)
    accuracy = (total_valid / total_entries * 100) if total_entries > 0 else 0
    
    print(f'\n🎯 FINAL OVERALL RESULTS:')
    print(f'  Total Entries: {total_entries}')
    print(f'  Valid Entries: {total_valid}')
    print(f'  Total Errors: {total_errors}')
    print(f'  Overall Accuracy: {accuracy:.1f}%')
    print(f'  Status: {"✅ PRODUCTION READY" if total_errors == 0 else "❌ NEEDS FIXES"}')
    
    # Show sample data structure
    print(f'\n📋 SAMPLE DATA STRUCTURE:')
    if alevel_result.stats.get('total_entries', 0) > 0:
        print(f'  A-Level sample entry available')
    if olevel_result.stats.get('total_entries', 0) > 0:
        print(f'  O-Level sample entry available')
    
    return alevel_result, olevel_result

if __name__ == "__main__":
    main()
