#!/usr/bin/env python3
"""
Create minimal JSON output without empty arrays and null values
"""

import json
from pathlib import Path

def create_minimal_output():
    """Create clean JSON without empty placeholders"""
    
    data_dir = Path("C:/Users/user/SSU/syllabus_data_structure")
    
    print("🧹 CREATING MINIMAL OUTPUT (no empty fields)...")
    
    # Process A-Level data
    with open(data_dir / "alevel_data.json", 'r', encoding='utf-8') as f:
        alevel_data = json.load(f)
    
    # Clean A-Level data
    clean_alevel = []
    for entry in alevel_data:
        clean_entry = clean_entry_data(entry)
        clean_alevel.append(clean_entry)
    
    # Process O-Level data
    with open(data_dir / "olevel_data.json", 'r', encoding='utf-8') as f:
        olevel_data = json.load(f)
    
    # Clean O-Level data
    clean_olevel = []
    for entry in olevel_data:
        clean_entry = clean_entry_data(entry)
        clean_olevel.append(clean_entry)
    
    # Save minimal versions
    with open(data_dir / "alevel_data_minimal.json", 'w', encoding='utf-8') as f:
        json.dump(clean_alevel, f, indent=2, ensure_ascii=False)
    
    with open(data_dir / "olevel_data_minimal.json", 'w', encoding='utf-8') as f:
        json.dump(clean_olevel, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Created minimal versions:")
    print(f"  - alevel_data_minimal.json ({len(clean_alevel)} entries)")
    print(f"  - olevel_data_minimal.json ({len(clean_olevel)} entries)")
    
    # Show sample comparison
    print(f"\n📋 SAMPLE COMPARISON:")
    original_sample = alevel_data[0]["competences"][0]["learning_outcomes"][0]
    clean_sample = clean_alevel[0]["competences"][0]["learning_outcomes"][0]
    
    print(f"Original fields: {len(original_sample)}")
    print(f"Clean fields: {len(clean_sample)}")
    print(f"\nClean version:")
    print(json.dumps(clean_sample, indent=2))
    
    return clean_alevel, clean_olevel

def clean_entry_data(entry):
    """Remove empty arrays and null values from entry"""
    clean_entry = entry.copy()
    
    # Remove null sub_strand
    if clean_entry.get("sub_strand") is None:
        clean_entry.pop("sub_strand", None)
    
    # Clean competences
    clean_competences = []
    for competence in clean_entry.get("competences", []):
        clean_comp = competence.copy()
        
        # Clean learning outcomes
        clean_outcomes = []
        for lo in clean_comp.get("learning_outcomes", []):
            clean_lo = lo.copy()
            
            # Remove empty activities
            if not clean_lo.get("activities"):
                clean_lo.pop("activities", None)
            
            # Remove empty materials
            if not clean_lo.get("materials"):
                clean_lo.pop("materials", None)
            
            # Remove empty cross_cutting_issues
            if not clean_lo.get("cross_cutting_issues"):
                clean_lo.pop("cross_cutting_issues", None)
            
            # Clean assessment
            assessment = clean_lo.get("assessment", {})
            clean_assessment = {}
            
            if assessment.get("guidance") is not None:
                clean_assessment["guidance"] = assessment["guidance"]
            
            if assessment.get("mode"):
                clean_assessment["mode"] = assessment["mode"]
            
            if assessment.get("exam_eligibility"):
                clean_assessment["exam_eligibility"] = assessment["exam_eligibility"]
            
            clean_lo["assessment"] = clean_assessment
            clean_outcomes.append(clean_lo)
        
        clean_comp["learning_outcomes"] = clean_outcomes
        clean_competences.append(clean_comp)
    
    clean_entry["competences"] = clean_competences
    return clean_entry

if __name__ == "__main__":
    create_minimal_output()
