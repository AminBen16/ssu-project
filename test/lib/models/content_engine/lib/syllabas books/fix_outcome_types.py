#!/usr/bin/env python3
"""
Fix outcome_type classification issues in extracted data
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Any

class OutcomeTypeFixer:
    def __init__(self, data_dir: str = "C:/Users/user/SSU/syllabus_data_structure"):
        self.data_dir = Path(data_dir)
        
        # Enhanced verb sets with better coverage
        self.knowledge_verbs = {
            'understand', 'know', 'explain', 'describe', 'identify', 'state', 'list', 'name', 
            'recognize', 'recall', 'outline', 'summarize', 'classify', 'distinguish',
            'appreciate', 'comprehend', 'recognize', 'remember', 'select', 'indicate', 
            'specify', 'label', 'locate', 'match', 'define', 'explain', 'describe'
        }
        
        self.skill_verbs = {
            'apply', 'analyze', 'create', 'develop', 'demonstrate', 'design', 
            'implement', 'use', 'perform', 'show', 'carry out', 'conduct',
            'measure', 'calculate', 'solve', 'construct', 'produce', 'handle',
            'prepare', 'establish', 'grow', 'maintain', 'process', 'extract', 
            'interpret', 'organize', 'plan', 'practice', 'record', 'show',
            'demonstrate', 'identify', 'establish', 'grow', 'maintain'
        }
        
        self.value_verbs = {
            'evaluate', 'assess', 'compare', 'appreciate', 'respect', 'value', 
            'justify', 'critique', 'judge', 'recommend', 'prefer', 'choose',
            'accept', 'acknowledge', 'believe', 'commit', 'contribute', 'cooperate'
        }
    
    def determine_outcome_type_fixed(self, outcome_text: str) -> str:
        """Fixed outcome type determination with better logic"""
        text_lower = outcome_text.lower()
        
        # Priority 1: Check for skill verbs first (most specific)
        skill_count = sum(1 for verb in self.skill_verbs if f' {verb} ' in f' {text_lower} ')
        if skill_count > 0:
            return "skill"
        
        # Priority 2: Check for knowledge verbs
        knowledge_count = sum(1 for verb in self.knowledge_verbs if f' {verb} ' in f' {text_lower} ')
        if knowledge_count > 0:
            return "knowledge"
        
        # Priority 3: Check for value verbs
        value_count = sum(1 for verb in self.value_verbs if f' {verb} ' in f' {text_lower} ')
        if value_count > 0:
            return "value"
        
        # Fallback: Check word boundaries more carefully
        for verb in self.skill_verbs:
            if re.search(r'\b' + re.escape(verb) + r'\b', text_lower):
                return "skill"
        
        for verb in self.knowledge_verbs:
            if re.search(r'\b' + re.escape(verb) + r'\b', text_lower):
                return "knowledge"
        
        for verb in self.value_verbs:
            if re.search(r'\b' + re.escape(verb) + r'\b', text_lower):
                return "value"
        
        return "knowledge"  # Default to knowledge instead of unset
    
    def fix_outcome_types_in_file(self, input_file: str, output_file: str) -> Dict[str, Any]:
        """Fix outcome types in a JSON file"""
        print(f"🔧 Fixing outcome types in {input_file}...")
        
        # Load data
        with open(self.data_dir / input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Track changes
        changes = {
            "total_entries": len(data),
            "entries_fixed": 0,
            "outcomes_fixed": 0,
            "outcome_type_distribution": {"knowledge": 0, "skill": 0, "value": 0, "unset": 0}
        }
        
        # Fix each entry
        for entry in data:
            entry_fixed = False
            
            for competence in entry.get("competences", []):
                for learning_outcome in competence.get("learning_outcomes", []):
                    old_type = learning_outcome.get("outcome_type", "unset")
                    
                    # Apply fixed classification
                    new_type = self.determine_outcome_type_fixed(learning_outcome.get("text", ""))
                    learning_outcome["outcome_type"] = new_type
                    
                    # Track changes
                    if old_type != new_type:
                        changes["outcomes_fixed"] += 1
                        entry_fixed = True
                        print(f"  Fixed: '{old_type}' → '{new_type}' for: {learning_outcome.get('text', '')[:60]}...")
                    
                    # Count distribution
                    if new_type in changes["outcome_type_distribution"]:
                        changes["outcome_type_distribution"][new_type] += 1
                    else:
                        changes["outcome_type_distribution"]["unset"] += 1
            
            if entry_fixed:
                changes["entries_fixed"] += 1
        
        # Save fixed data
        with open(self.data_dir / output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Fixed data saved to {output_file}")
        return changes
    
    def run_fix(self):
        """Run the fix for both A-Level and O-Level data"""
        print("🚀 Starting Outcome Type Fix...")
        print("=" * 50)
        
        results = {}
        
        # Fix O-Level data
        olevel_changes = self.fix_outcome_types_in_file(
            "olevel_syllabus_data.json", 
            "olevel_syllabus_data_fixed.json"
        )
        results["olevel"] = olevel_changes
        
        print(f"\n📊 O-LEVEL FIX RESULTS:")
        print(f"  Total Entries: {olevel_changes['total_entries']}")
        print(f"  Entries Fixed: {olevel_changes['entries_fixed']}")
        print(f"  Outcomes Fixed: {olevel_changes['outcomes_fixed']}")
        print(f"  Outcome Type Distribution:")
        for outcome_type, count in olevel_changes['outcome_type_distribution'].items():
            print(f"    {outcome_type}: {count}")
        
        # Fix A-Level data
        alevel_changes = self.fix_outcome_types_in_file(
            "alevel_syllabus_data.json", 
            "alevel_syllabus_data_fixed.json"
        )
        results["alevel"] = alevel_changes
        
        print(f"\n📊 A-LEVEL FIX RESULTS:")
        print(f"  Total Entries: {alevel_changes['total_entries']}")
        print(f"  Entries Fixed: {alevel_changes['entries_fixed']}")
        print(f"  Outcomes Fixed: {alevel_changes['outcomes_fixed']}")
        print(f"  Outcome Type Distribution:")
        for outcome_type, count in alevel_changes['outcome_type_distribution'].items():
            print(f"    {outcome_type}: {count}")
        
        # Summary
        total_outcomes_fixed = olevel_changes['outcomes_fixed'] + alevel_changes['outcomes_fixed']
        print(f"\n🎯 SUMMARY:")
        print(f"  Total Outcomes Fixed: {total_outcomes_fixed}")
        print(f"  Files Created:")
        print(f"    - olevel_syllabus_data_fixed.json")
        print(f"    - alevel_syllabus_data_fixed.json")
        
        return results

def main():
    fixer = OutcomeTypeFixer()
    results = fixer.run_fix()
    print("\n🎉 Outcome type fixing completed!")
    return results

if __name__ == "__main__":
    main()
