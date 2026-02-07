#!/usr/bin/env python3
"""
Test script to validate all extraction results and compare accuracy
"""

from syllabus_validator import NCDCSyllabusValidator

def main():
    validator = NCDCSyllabusValidator()
    
    print("🔍 COMPREHENSIVE VALIDATION COMPARISON")
    print("=" * 60)
    
    datasets = [
        ("Original", "alevel_syllabus_data.json", "olevel_syllabus_data.json"),
        ("Improved", "alevel_syllabus_data_improved.json", "olevel_syllabus_data_improved.json"),
        ("Final Optimized", "alevel_syllabus_data_final_optimized.json", "olevel_syllabus_data_final_optimized.json")
    ]
    
    results_summary = []
    
    for name, alevel_file, olevel_file in datasets:
        print(f"\n📊 {name.upper()} RESULTS:")
        print("-" * 40)
        
        try:
            # Validate A-Level
            alevel_result = validator.validate_dataset(alevel_file)
            
            # Validate O-Level
            olevel_result = validator.validate_dataset(olevel_file)
            
            # Calculate totals
            total_entries = alevel_result.stats.get('total_entries', 0) + olevel_result.stats.get('total_entries', 0)
            total_valid = alevel_result.stats.get('valid_entries', 0) + olevel_result.stats.get('valid_entries', 0)
            total_invalid = alevel_result.stats.get('invalid_entries', 0) + olevel_result.stats.get('invalid_entries', 0)
            total_errors = len(alevel_result.errors) + len(olevel_result.errors)
            
            accuracy_rate = (total_valid / total_entries * 100) if total_entries > 0 else 0
            
            print(f"  Total Entries: {total_entries}")
            print(f"  Valid Entries: {total_valid}")
            print(f"  Invalid Entries: {total_invalid}")
            print(f"  Total Errors: {total_errors}")
            print(f"  Overall Accuracy: {accuracy_rate:.1f}%")
            
            results_summary.append({
                'name': name,
                'total_entries': total_entries,
                'valid_entries': total_valid,
                'invalid_entries': total_invalid,
                'total_errors': total_errors,
                'accuracy': accuracy_rate
            })
            
        except Exception as e:
            print(f"  ❌ Validation failed: {e}")
            results_summary.append({
                'name': name,
                'total_entries': 0,
                'valid_entries': 0,
                'invalid_entries': 0,
                'total_errors': float('inf'),
                'accuracy': 0
            })
    
    # Summary comparison
    print(f"\n🎯 ACCURACY COMPARISON SUMMARY")
    print("=" * 60)
    print(f"{'Version':<20} {'Entries':<10} {'Valid':<10} {'Errors':<10} {'Accuracy':<10}")
    print("-" * 60)
    
    for result in results_summary:
        print(f"{result['name']:<20} {result['total_entries']:<10} {result['valid_entries']:<10} "
              f"{result['total_errors']:<10} {result['accuracy']:<10.1f}%")
    
    # Best accuracy recommendation
    best_result = max(results_summary, key=lambda x: x['accuracy'])
    print(f"\n🏆 RECOMMENDED VERSION: {best_result['name']}")
    print(f"   Accuracy: {best_result['accuracy']:.1f}%")
    print(f"   Entries: {best_result['total_entries']}")
    print(f"   Errors: {best_result['total_errors']}")
    
    # File recommendation
    if best_result['name'] == 'Original':
        print(f"\n📁 RECOMMENDED FILES:")
        print(f"   - alevel_syllabus_data.json")
        print(f"   - olevel_syllabus_data.json")
    elif best_result['name'] == 'Improved':
        print(f"\n📁 RECOMMENDED FILES:")
        print(f"   - alevel_syllabus_data_improved.json")
        print(f"   - olevel_syllabus_data_improved.json")
    else:
        print(f"\n📁 RECOMMENDED FILES:")
        print(f"   - alevel_syllabus_data_final_optimized.json")
        print(f"   - olevel_syllabus_data_final_optimized.json")
    
    return results_summary

if __name__ == "__main__":
    main()
