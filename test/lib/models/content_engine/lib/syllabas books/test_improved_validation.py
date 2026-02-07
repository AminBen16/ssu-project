#!/usr/bin/env python3
"""
Test script to validate improved extraction results
"""

from syllabus_validator import NCDCSyllabusValidator

def main():
    validator = NCDCSyllabusValidator()
    
    # Validate improved files
    print("🔍 VALIDATING IMPROVED EXTRACTION RESULTS...")
    print("=" * 60)
    
    # Test improved files
    try:
        alevel_result = validator.validate_dataset("alevel_syllabus_data_improved.json")
        print(f"📊 A-LEVEL RESULTS:")
        print(f"  Status: {'✅ VALID' if alevel_result.is_valid else '❌ INVALID'}")
        print(f"  Total Entries: {alevel_result.stats.get('total_entries', 0)}")
        print(f"  Valid Entries: {alevel_result.stats.get('valid_entries', 0)}")
        print(f"  Invalid Entries: {alevel_result.stats.get('invalid_entries', 0)}")
        print(f"  Errors: {len(alevel_result.errors)}")
        print(f"  Warnings: {len(alevel_result.warnings)}")
        
        if alevel_result.errors:
            print(f"  Sample Errors:")
            for error in alevel_result.errors[:5]:
                print(f"    - {error}")
        
        print()
        
        olevel_result = validator.validate_dataset("olevel_syllabus_data_improved.json")
        print(f"📊 O-LEVEL RESULTS:")
        print(f"  Status: {'✅ VALID' if olevel_result.is_valid else '❌ INVALID'}")
        print(f"  Total Entries: {olevel_result.stats.get('total_entries', 0)}")
        print(f"  Valid Entries: {olevel_result.stats.get('valid_entries', 0)}")
        print(f"  Invalid Entries: {olevel_result.stats.get('invalid_entries', 0)}")
        print(f"  Errors: {len(olevel_result.errors)}")
        print(f"  Warnings: {len(olevel_result.warnings)}")
        
        if olevel_result.errors:
            print(f"  Sample Errors:")
            for error in olevel_result.errors[:5]:
                print(f"    - {error}")
        
        print()
        print("🎯 ACCURACY IMPROVEMENT SUMMARY:")
        print("=" * 40)
        
        # Calculate improvement
        total_entries = alevel_result.stats.get('total_entries', 0) + olevel_result.stats.get('total_entries', 0)
        total_valid = alevel_result.stats.get('valid_entries', 0) + olevel_result.stats.get('valid_entries', 0)
        total_invalid = alevel_result.stats.get('invalid_entries', 0) + olevel_result.stats.get('invalid_entries', 0)
        total_errors = len(alevel_result.errors) + len(olevel_result.errors)
        
        accuracy_rate = (total_valid / total_entries * 100) if total_entries > 0 else 0
        
        print(f"Total Entries: {total_entries}")
        print(f"Valid Entries: {total_valid}")
        print(f"Invalid Entries: {total_invalid}")
        print(f"Total Errors: {total_errors}")
        print(f"Overall Accuracy: {accuracy_rate:.1f}%")
        
        # Compare with original results
        print(f"\n📈 COMPARISON WITH ORIGINAL:")
        print(f"Original Errors: 2257 (755 A-Level + 1502 O-Level)")
        print(f"Improved Errors: {total_errors}")
        if total_errors < 2257:
            improvement = ((2257 - total_errors) / 2257) * 100
            print(f"Error Reduction: {improvement:.1f}%")
        
        return alevel_result, olevel_result
        
    except Exception as e:
        print(f"❌ Validation failed: {e}")
        import traceback
        traceback.print_exc()
        return None, None

if __name__ == "__main__":
    main()
