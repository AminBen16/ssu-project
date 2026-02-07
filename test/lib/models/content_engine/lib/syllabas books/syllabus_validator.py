#!/usr/bin/env python3
"""
NCDC Syllabus Data Validation Script
Validates extracted curriculum data against NCDC specifications
Ensures accuracy and completeness of structured data
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Any, Set
from dataclasses import dataclass

@dataclass
class ValidationResult:
    is_valid: bool
    errors: List[str]
    warnings: List[str]
    stats: Dict[str, Any]

class NCDCSyllabusValidator:
    def __init__(self, data_dir: str = "C:/Users/user/SSU/syllabus_data_structure"):
        self.data_dir = Path(data_dir)
        
        # Valid enum values
        self.valid_outcome_types = {"knowledge", "skill", "value"}
        self.valid_assessment_modes = {"formative", "summative", "both", "unset"}
        self.valid_lesson_units = {"single_outcome"}
        self.valid_exam_eligibility = {"yes", "no", "unset"}
        
        # Required fields
        self.required_fields = {
            "subject", "level", "class", "strand", "topic", "competences"
        }
        
        # Command verbs for exam eligibility
        self.exam_verbs = {
            'define', 'explain', 'describe', 'apply', 'analyze', 'evaluate',
            'identify', 'compare', 'contrast', 'discuss', 'demonstrate',
            'calculate', 'solve', 'create', 'design', 'develop', 'assess'
        }
    
    def load_data(self, file_path: str) -> List[Dict]:
        """Load JSON data from file"""
        try:
            with open(self.data_dir / file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading {file_path}: {e}")
            return []
    
    def validate_enum_values(self, data: Dict) -> List[str]:
        """Validate that enum values are from allowed sets"""
        errors = []
        
        for competence in data.get("competences", []):
            for learning_outcome in competence.get("learning_outcomes", []):
                # Validate outcome_type
                outcome_type = learning_outcome.get("outcome_type", "")
                if outcome_type and outcome_type not in self.valid_outcome_types:
                    errors.append(f"Invalid outcome_type: {outcome_type}")
                
                # Validate lesson_unit
                lesson_unit = learning_outcome.get("lesson_unit", "")
                if lesson_unit and lesson_unit not in self.valid_lesson_units:
                    errors.append(f"Invalid lesson_unit: {lesson_unit}")
                
                # Validate assessment mode
                assessment = learning_outcome.get("assessment", {})
                mode = assessment.get("mode", "")
                if mode and mode not in self.valid_assessment_modes:
                    errors.append(f"Invalid assessment mode: {mode}")
                
                # Validate exam_eligibility
                exam_eligibility = assessment.get("exam_eligibility", "")
                if exam_eligibility and exam_eligibility not in self.valid_exam_eligibility:
                    errors.append(f"Invalid exam_eligibility: {exam_eligibility}")
        
        return errors
    
    def validate_required_fields(self, data: Dict) -> List[str]:
        """Validate that all required fields are present and not empty"""
        errors = []
        
        for field in self.required_fields:
            if field not in data or data[field] in [None, "", []]:
                errors.append(f"Missing or empty required field: {field}")
        
        # Validate competence structure
        competences = data.get("competences", [])
        if competences:
            for i, competence in enumerate(competences):
                if "text" not in competence or not competence["text"]:
                    errors.append(f"Competence {i}: Missing or empty text")
                
                learning_outcomes = competence.get("learning_outcomes", [])
                if not learning_outcomes:
                    errors.append(f"Competence {i}: No learning outcomes")
                else:
                    for j, lo in enumerate(learning_outcomes):
                        if "text" not in lo or not lo["text"]:
                            errors.append(f"Learning outcome {i}-{j}: Missing or empty text")
        
        return errors
    
    def validate_exam_eligibility_logic(self, data: Dict) -> List[str]:
        """Validate exam eligibility based on command verbs"""
        errors = []
        
        for competence in data.get("competences", []):
            for learning_outcome in competence.get("learning_outcomes", []):
                text = learning_outcome.get("text", "").lower()
                exam_eligibility = learning_outcome.get("assessment", {}).get("exam_eligibility", "")
                
                # Check if text contains exam verbs
                has_exam_verb = any(verb in text for verb in self.exam_verbs)
                
                if has_exam_verb and exam_eligibility != "yes":
                    errors.append(f"Exam eligibility mismatch: '{learning_outcome.get('text', '')[:50]}...' should have exam_eligibility='yes'")
                elif not has_exam_verb and exam_eligibility == "yes":
                    errors.append(f"Exam eligibility mismatch: '{learning_outcome.get('text', '')[:50]}...' has exam_eligibility='yes' but no exam verbs")
        
        return errors
    
    def validate_no_empty_strings(self, data: Dict) -> List[str]:
        """Validate that there are no empty strings (should use null instead)"""
        errors = []
        
        def check_empty_strings(obj, path=""):
            if isinstance(obj, dict):
                for key, value in obj.items():
                    new_path = f"{path}.{key}" if path else key
                    if value == "":
                        errors.append(f"Empty string at {new_path} - should be null")
                    elif isinstance(value, (dict, list)):
                        check_empty_strings(value, new_path)
            elif isinstance(obj, list):
                for i, item in enumerate(obj):
                    new_path = f"{path}[{i}]"
                    if item == "":
                        errors.append(f"Empty string at {new_path} - should be null")
                    elif isinstance(item, (dict, list)):
                        check_empty_strings(item, new_path)
        
        check_empty_strings(data)
        return errors
    
    def validate_verbatim_content(self, data: Dict, original_content: str = "") -> List[str]:
        """Validate that content is verbatim (no paraphrasing)"""
        warnings = []
        
        # This would require comparing with original content
        # For now, we'll check for signs of paraphrasing
        for competence in data.get("competences", []):
            competency_text = competence.get("text", "")
            
            # Check for modern AI-like phrases
            ai_phrases = ["furthermore", "moreover", "in essence", "essentially", "basically"]
            for phrase in ai_phrases:
                if phrase in competency_text.lower():
                    warnings.append(f"Possible paraphrasing detected in competency: '{phrase}' found")
            
            for learning_outcome in competence.get("learning_outcomes", []):
                lo_text = learning_outcome.get("text", "")
                for phrase in ai_phrases:
                    if phrase in lo_text.lower():
                        warnings.append(f"Possible paraphrasing detected in learning outcome: '{phrase}' found")
        
        return warnings
    
    def calculate_statistics(self, data_list: List[Dict]) -> Dict[str, Any]:
        """Calculate statistics for the dataset"""
        stats = {
            "total_entries": len(data_list),
            "subjects": set(),
            "levels": set(),
            "classes": set(),
            "total_competences": 0,
            "total_learning_outcomes": 0,
            "outcome_types": {"knowledge": 0, "skill": 0, "value": 0},
            "assessment_modes": {"formative": 0, "summative": 0, "both": 0, "unset": 0},
            "exam_eligibility": {"yes": 0, "no": 0, "unset": 0}
        }
        
        for data in data_list:
            stats["subjects"].add(data.get("subject", ""))
            stats["levels"].add(data.get("level", ""))
            stats["classes"].add(data.get("class", ""))
            
            competences = data.get("competences", [])
            stats["total_competences"] += len(competences)
            
            for competence in competences:
                learning_outcomes = competence.get("learning_outcomes", [])
                stats["total_learning_outcomes"] += len(learning_outcomes)
                
                for lo in learning_outcomes:
                    # Count outcome types
                    outcome_type = lo.get("outcome_type", "")
                    if outcome_type in stats["outcome_types"]:
                        stats["outcome_types"][outcome_type] += 1
                    
                    # Count assessment modes
                    assessment = lo.get("assessment", {})
                    mode = assessment.get("mode", "")
                    if mode in stats["assessment_modes"]:
                        stats["assessment_modes"][mode] += 1
                    
                    # Count exam eligibility
                    exam_eligibility = assessment.get("exam_eligibility", "")
                    if exam_eligibility in stats["exam_eligibility"]:
                        stats["exam_eligibility"][exam_eligibility] += 1
        
        # Convert sets to lists for JSON serialization
        stats["subjects"] = list(stats["subjects"])
        stats["levels"] = list(stats["levels"])
        stats["classes"] = list(stats["classes"])
        
        return stats
    
    def validate_single_entry(self, data: Dict) -> ValidationResult:
        """Validate a single syllabus entry"""
        errors = []
        warnings = []
        
        # Run all validation checks
        errors.extend(self.validate_required_fields(data))
        errors.extend(self.validate_enum_values(data))
        errors.extend(self.validate_exam_eligibility_logic(data))
        errors.extend(self.validate_no_empty_strings(data))
        
        warnings.extend(self.validate_verbatim_content(data))
        
        # Calculate stats for this entry
        stats = {
            "competences_count": len(data.get("competences", [])),
            "learning_outcomes_count": sum(len(c.get("learning_outcomes", [])) for c in data.get("competences", []))
        }
        
        is_valid = len(errors) == 0
        
        return ValidationResult(is_valid=is_valid, errors=errors, warnings=warnings, stats=stats)
    
    def validate_dataset(self, file_path: str) -> ValidationResult:
        """Validate entire dataset"""
        data_list = self.load_data(file_path)
        
        if not data_list:
            return ValidationResult(
                is_valid=False,
                errors=["No data found"],
                warnings=[],
                stats={}
            )
        
        all_errors = []
        all_warnings = []
        valid_entries = 0
        
        for i, data in enumerate(data_list):
            result = self.validate_single_entry(data)
            
            if result.is_valid:
                valid_entries += 1
            else:
                all_errors.extend([f"Entry {i}: {error}" for error in result.errors])
            
            all_warnings.extend([f"Entry {i}: {warning}" for warning in result.warnings])
        
        # Calculate overall statistics
        stats = self.calculate_statistics(data_list)
        stats["valid_entries"] = valid_entries
        stats["invalid_entries"] = len(data_list) - valid_entries
        
        is_valid = len(all_errors) == 0
        
        return ValidationResult(
            is_valid=is_valid,
            errors=all_errors,
            warnings=all_warnings,
            stats=stats
        )
    
    def generate_report(self, results: Dict[str, ValidationResult]) -> str:
        """Generate validation report"""
        report = []
        report.append("# NCDC Syllabus Data Validation Report")
        report.append("=" * 50)
        
        for dataset_name, result in results.items():
            report.append(f"\n## {dataset_name.upper()} Dataset")
            report.append(f"Valid: {'✅ YES' if result.is_valid else '❌ NO'}")
            report.append(f"Total Entries: {result.stats.get('total_entries', 0)}")
            report.append(f"Valid Entries: {result.stats.get('valid_entries', 0)}")
            report.append(f"Invalid Entries: {result.stats.get('invalid_entries', 0)}")
            
            if result.errors:
                report.append(f"\n### Errors ({len(result.errors)})")
                for error in result.errors[:10]:  # Show first 10 errors
                    report.append(f"- {error}")
                if len(result.errors) > 10:
                    report.append(f"- ... and {len(result.errors) - 10} more errors")
            
            if result.warnings:
                report.append(f"\n### Warnings ({len(result.warnings)})")
                for warning in result.warnings[:10]:  # Show first 10 warnings
                    report.append(f"- {warning}")
                if len(result.warnings) > 10:
                    report.append(f"- ... and {len(result.warnings) - 10} more warnings")
        
        return "\n".join(report)
    
    def run_validation(self) -> Dict[str, ValidationResult]:
        """Run validation on all datasets"""
        results = {}
        
        # Validate A-Level data
        print("Validating A-Level data...")
        results["alevel"] = self.validate_dataset("alevel_syllabus_data.json")
        
        # Validate O-Level data
        print("Validating O-Level data...")
        results["olevel"] = self.validate_dataset("olevel_syllabus_data.json")
        
        # Generate and save report
        report = self.generate_report(results)
        report_file = self.data_dir / "validation_report.md"
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report)
        
        print(f"Validation report saved to: {report_file}")
        
        return results

def main():
    """Main execution function"""
    validator = NCDCSyllabusValidator()
    results = validator.run_validation()
    
    print("\nValidation completed!")
    for dataset_name, result in results.items():
        print(f"{dataset_name.upper()}: {'✅ Valid' if result.is_valid else '❌ Invalid'}")
        print(f"  Entries: {result.stats.get('total_entries', 0)}")
        print(f"  Errors: {len(result.errors)}")
        print(f"  Warnings: {len(result.warnings)}")
    
    return results

if __name__ == "__main__":
    main()
