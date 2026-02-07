#!/usr/bin/env python3
"""
Investigate the 12 failed files to understand why they're not extracting
"""

import json
from pathlib import Path
from FINAL_NCDC_EXTRACTOR import FinalNCDCExtractor

def investigate_failed_files():
    extractor = FinalNCDCExtractor()
    
    print("🔍 INVESTIGATING FAILED FILES")
    print("=" * 50)
    
    failed_files = []
    
    # Check A-Level files
    print("\n📚 CHECKING A-LEVEL FILES:")
    alevel_files = list(extractor.alevel_dir.glob("*_clean.md"))
    
    for file_path in alevel_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Try to extract topics
            topics_data = extractor.extract_topics_algorithmic(content)
            
            if not topics_data:
                failed_files.append(("A-Level", file_path.name))
                print(f"  ❌ {file_path.name} - No topics found")
                
                # Show first few lines to understand structure
                lines = content.split('\n')[:10]
                print(f"     First lines: {lines[:3]}")
            else:
                print(f"  ✅ {file_path.name} - {len(topics_data)} topics found")
                
        except Exception as e:
            failed_files.append(("A-Level", file_path.name))
            print(f"  ❌ {file_path.name} - Error: {e}")
    
    # Check O-Level files
    print("\n📚 CHECKING O-LEVEL FILES:")
    olevel_files = list(extractor.olevel_dir.glob("*_clean.md"))
    
    for file_path in olevel_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Try to extract topics
            topics_data = extractor.extract_topics_algorithmic(content)
            
            if not topics_data:
                failed_files.append(("O-Level", file_path.name))
                print(f"  ❌ {file_path.name} - No topics found")
                
                # Show first few lines to understand structure
                lines = content.split('\n')[:10]
                print(f"     First lines: {lines[:3]}")
            else:
                print(f"  ✅ {file_path.name} - {len(topics_data)} topics found")
                
        except Exception as e:
            failed_files.append(("O-Level", file_path.name))
            print(f"  ❌ {file_path.name} - Error: {e}")
    
    # Summary
    print(f"\n📊 FAILED FILES SUMMARY:")
    print(f"  Total Failed: {len(failed_files)}")
    
    for level, filename in failed_files:
        print(f"  - {level}: {filename}")
    
    # Try to read one failed file to understand structure
    if failed_files:
        level, filename = failed_files[0]
        if level == "A-Level":
            file_path = extractor.alevel_dir / filename
        else:
            file_path = extractor.olevel_dir / filename
        
        print(f"\n🔍 DETAILED ANALYSIS OF {filename}:")
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            print(f"  File size: {len(content)} characters")
            print(f"  First 500 characters:")
            print(f"  {content[:500]}...")
            
            # Check for common patterns
            if "####" in content:
                print(f"  ✅ Contains '####' headers")
            else:
                print(f"  ❌ No '####' headers found")
            
            if "**Competency:**" in content:
                print(f"  ✅ Contains '**Competency:**' pattern")
            else:
                print(f"  ❌ No '**Competency:**' pattern found")
                
            if "**Learning Outcomes:**" in content:
                print(f"  ✅ Contains '**Learning Outcomes:**' pattern")
            else:
                print(f"  ❌ No '**Learning Outcomes:**' pattern found")
                
        except Exception as e:
            print(f"  Error reading file: {e}")
    
    return failed_files

if __name__ == "__main__":
    investigate_failed_files()
