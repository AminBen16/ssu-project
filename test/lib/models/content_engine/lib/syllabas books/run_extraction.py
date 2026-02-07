#!/usr/bin/env python3
"""
Simple runner script for NCDC syllabus extraction
"""

import sys
import os
from pathlib import Path

# Add current directory to Python path
sys.path.append(str(Path(__file__).parent))

try:
    from syllabus_extractor import NCDCSyllabusExtractor
    from syllabus_validator import NCDCSyllabusValidator
    
    def main():
        print("🚀 Starting NCDC Syllabus Extraction and Validation...")
        print("=" * 60)
        
        # Step 1: Extract data
        print("\n📊 STEP 1: Extracting curriculum data...")
        extractor = NCDCSyllabusExtractor()
        extraction_results = extractor.run_extraction()
        
        # Step 2: Validate data
        print("\n✅ STEP 2: Validating extracted data...")
        validator = NCDCSyllabusValidator()
        validation_results = validator.run_validation()
        
        # Step 3: Summary
        print("\n📋 EXTRACTION SUMMARY:")
        print(f"Total files processed: {extraction_results['summary']['total_files']}")
        print(f"Successfully processed: {extraction_results['summary']['processed_files']}")
        print(f"Failed files: {len(extraction_results['summary']['failed_files'])}")
        print(f"Total curriculum entries: {extraction_results['summary']['total_entries']}")
        
        print("\n🔍 VALIDATION SUMMARY:")
        for dataset, result in validation_results.items():
            status = "✅ VALID" if result.is_valid else "❌ INVALID"
            print(f"{dataset.upper()}: {status}")
            if result.errors:
                print(f"  Errors: {len(result.errors)}")
            if result.warnings:
                print(f"  Warnings: {len(result.warnings)}")
        
        print("\n📁 Files created:")
        print("  - syllabus_data_structure/alevel_syllabus_data.json")
        print("  - syllabus_data_structure/olevel_syllabus_data.json")
        print("  - syllabus_data_structure/all_syllabus_data.json")
        print("  - syllabus_data_structure/extraction_summary.json")
        print("  - syllabus_data_structure/validation_report.md")
        
        print("\n🎉 Process completed!")
        
        return extraction_results, validation_results
    
    if __name__ == "__main__":
        main()
        
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Make sure all required files are in the same directory.")
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
