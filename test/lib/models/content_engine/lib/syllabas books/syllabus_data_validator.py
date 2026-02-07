#!/usr/bin/env python3
"""
NCDC SYLLABUS DATA VALIDATOR
Comprehensive data quality validation for extracted syllabus data
Ensures completeness, accuracy, and consistency before UI integration
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
from collections import defaultdict, Counter
import statistics

@dataclass
class ValidationResult:
    """Individual validation result"""
    test_name: str
    status: str  # "PASS", "FAIL", "WARNING"
    message: str
    details: Dict[str, Any]
    severity: str  # "HIGH", "MEDIUM", "LOW"

@dataclass
class ValidationReport:
    """Comprehensive validation report"""
    total_tests: int
    passed_tests: int
    failed_tests: int
    warnings: int
    overall_status: str
    execution_time: float
    results: List[ValidationResult]
    summary: Dict[str, Any]

class SyllabusDataValidator:
    def __init__(self, base_dir: str = "C:/Users/user/SSU"):
        self.base_dir = Path(base_dir)
        self.data_dir = self.base_dir / "syllabus_data_structure"
        self.alevel_file = self.data_dir / "alevel_data.json"
        self.olevel_file = self.data_dir / "olevel_data.json"
        
        # Validation thresholds
        self.min_entries_per_subject = 5
        self.max_empty_fields_ratio = 0.1  # 10% max empty fields
        self.min_learning_outcomes_per_topic = 1
        self.max_topics_per_subject = 100
        
        # Required fields
        self.required_entry_fields = {
            "subject", "level", "class", "strand", "topic", "competences"
        }
        
        self.required_competence_fields = {
            "text", "learning_outcomes"
        }
        
        self.required_outcome_fields = {
            "text", "outcome_type"
        }
    
    def load_data(self) -> Tuple[List[Dict], List[Dict]]:
        """Load A-Level and O-Level data"""
        alevel_data = []
        olevel_data = []
        
        try:
            if self.alevel_file.exists():
                with open(self.alevel_file, 'r', encoding='utf-8') as f:
                    alevel_data = json.load(f)
        except Exception as e:
            print(f"❌ Error loading A-Level data: {e}")
        
        try:
            if self.olevel_file.exists():
                with open(self.olevel_file, 'r', encoding='utf-8') as f:
                    olevel_data = json.load(f)
        except Exception as e:
            print(f"❌ Error loading O-Level data: {e}")
        
        return alevel_data, olevel_data
    
    def validate_file_structure(self, data: List[Dict], level: str) -> ValidationResult:
        """Validate basic file structure and required fields"""
        print(f"  🔍 Validating {level} file structure...")
        
        issues = []
        total_entries = len(data)
        
        if total_entries == 0:
            return ValidationResult(
                test_name=f"File Structure - {level}",
                status="FAIL",
                message=f"No entries found in {level} data",
                details={"total_entries": 0},
                severity="HIGH"
            )
        
        # Check required fields in each entry
        missing_fields_count = 0
        for i, entry in enumerate(data):
            if not isinstance(entry, dict):
                issues.append(f"Entry {i} is not a dictionary")
                continue
            
            missing_fields = self.required_entry_fields - set(entry.keys())
            if missing_fields:
                missing_fields_count += 1
                if missing_fields_count <= 5:  # Limit examples
                    issues.append(f"Entry {i} missing fields: {missing_fields}")
        
        status = "PASS" if missing_fields_count == 0 else "FAIL"
        severity = "HIGH" if missing_fields_count > total_entries * 0.1 else "MEDIUM"
        
        return ValidationResult(
            test_name=f"File Structure - {level}",
            status=status,
            message=f"Found {total_entries} entries, {missing_fields_count} with missing fields",
            details={
                "total_entries": total_entries,
                "entries_with_missing_fields": missing_fields_count,
                "missing_fields_ratio": missing_fields_count / total_entries if total_entries > 0 else 0,
                "sample_issues": issues[:5]
            },
            severity=severity
        )
    
    def validate_subject_coverage(self, data: List[Dict], level: str) -> ValidationResult:
        """Validate subject coverage and distribution"""
        print(f"  📚 Validating {level} subject coverage...")
        
        subjects = [entry.get("subject", "Unknown") for entry in data]
        subject_counts = Counter(subjects)
        
        issues = []
        low_count_subjects = []
        
        for subject, count in subject_counts.items():
            if count < self.min_entries_per_subject:
                low_count_subjects.append(f"{subject}: {count} entries")
        
        if low_count_subjects:
            issues.extend(low_count_subjects)
        
        status = "PASS" if not low_count_subjects else "WARNING"
        severity = "MEDIUM" if len(low_count_subjects) > 3 else "LOW"
        
        return ValidationResult(
            test_name=f"Subject Coverage - {level}",
            status=status,
            message=f"Found {len(subject_counts)} subjects, {len(low_count_subjects)} with low coverage",
            details={
                "total_subjects": len(subject_counts),
                "subjects": dict(subject_counts),
                "low_coverage_subjects": low_count_subjects,
                "min_entries_threshold": self.min_entries_per_subject
            },
            severity=severity
        )
    
    def validate_class_distribution(self, data: List[Dict], level: str) -> ValidationResult:
        """Validate class/grade distribution"""
        print(f"  🏫 Validating {level} class distribution...")
        
        classes = [entry.get("class", "Unknown") for entry in data]
        class_counts = Counter(classes)
        
        # Check for expected classes based on level
        if level.lower() == "advanced secondary":
            expected_classes = {"SENIOR FIVE", "SENIOR SIX"}
        else:
            expected_classes = {"SENIOR 1", "SENIOR 2", "SENIOR 3", "SENIOR 4"}
        
        missing_classes = expected_classes - set(class_counts.keys())
        unexpected_classes = set(class_counts.keys()) - expected_classes
        
        issues = []
        if missing_classes:
            issues.append(f"Missing expected classes: {missing_classes}")
        if unexpected_classes:
            issues.append(f"Unexpected classes found: {unexpected_classes}")
        
        status = "PASS" if not issues else "WARNING"
        severity = "MEDIUM" if len(missing_classes) > 0 else "LOW"
        
        return ValidationResult(
            test_name=f"Class Distribution - {level}",
            status=status,
            message=f"Class distribution: {len(class_counts)} classes found",
            details={
                "class_distribution": dict(class_counts),
                "expected_classes": list(expected_classes),
                "missing_classes": list(missing_classes),
                "unexpected_classes": list(unexpected_classes),
                "issues": issues
            },
            severity=severity
        )
    
    def validate_competency_structure(self, data: List[Dict], level: str) -> ValidationResult:
        """Validate competency structure and content"""
        print(f"  🎯 Validating {level} competency structure...")
        
        total_competencies = 0
        empty_competencies = 0
        missing_outcomes = 0
        competency_issues = []
        
        for i, entry in enumerate(data):
            competencies = entry.get("competences", [])
            total_competencies += len(competencies)
            
            for j, competence in enumerate(competencies):
                if not isinstance(competence, dict):
                    competency_issues.append(f"Entry {i}, competence {j}: Not a dictionary")
                    continue
                
                # Check required competence fields
                missing_fields = self.required_competence_fields - set(competence.keys())
                if missing_fields:
                    competency_issues.append(f"Entry {i}, competence {j}: Missing {missing_fields}")
                
                # Check competency text
                comp_text = competence.get("text", "").strip()
                if not comp_text or len(comp_text) < 10:
                    empty_competencies += 1
                
                # Check learning outcomes
                outcomes = competence.get("learning_outcomes", [])
                if not outcomes:
                    missing_outcomes += 1
        
        empty_ratio = empty_competencies / total_competencies if total_competencies > 0 else 0
        status = "PASS" if empty_ratio < self.max_empty_fields_ratio and not competency_issues else "FAIL"
        severity = "HIGH" if empty_ratio > 0.2 or len(competency_issues) > 10 else "MEDIUM"
        
        return ValidationResult(
            test_name=f"Competency Structure - {level}",
            status=status,
            message=f"Found {total_competencies} competencies, {empty_competencies} empty",
            details={
                "total_competencies": total_competencies,
                "empty_competencies": empty_competencies,
                "missing_outcomes": missing_outcomes,
                "empty_ratio": empty_ratio,
                "competency_issues": competency_issues[:10],
                "max_empty_ratio": self.max_empty_fields_ratio
            },
            severity=severity
        )
    
    def validate_learning_outcomes(self, data: List[Dict], level: str) -> ValidationResult:
        """Validate learning outcomes quality and structure"""
        print(f"  📝 Validating {level} learning outcomes...")
        
        total_outcomes = 0
        empty_outcomes = 0
        invalid_types = []
        outcome_types = []
        
        for i, entry in enumerate(data):
            competencies = entry.get("competences", [])
            
            for competence in competencies:
                outcomes = competence.get("learning_outcomes", [])
                total_outcomes += len(outcomes)
                
                for outcome in outcomes:
                    if not isinstance(outcome, dict):
                        continue
                    
                    # Check required outcome fields
                    missing_fields = self.required_outcome_fields - set(outcome.keys())
                    if missing_fields:
                        invalid_types.append(f"Missing fields: {missing_fields}")
                        continue
                    
                    # Check outcome text
                    outcome_text = outcome.get("text", "").strip()
                    if not outcome_text or len(outcome_text) < 10:
                        empty_outcomes += 1
                    
                    # Check outcome type
                    outcome_type = outcome.get("outcome_type", "")
                    if outcome_type:
                        outcome_types.append(outcome_type)
                    else:
                        invalid_types.append("Missing outcome_type")
        
        outcome_type_counts = Counter(outcome_types)
        empty_ratio = empty_outcomes / total_outcomes if total_outcomes > 0 else 0
        
        status = "PASS" if empty_ratio < self.max_empty_fields_ratio else "FAIL"
        severity = "HIGH" if empty_ratio > 0.15 else "MEDIUM"
        
        return ValidationResult(
            test_name=f"Learning Outcomes - {level}",
            status=status,
            message=f"Found {total_outcomes} outcomes, {empty_outcomes} empty",
            details={
                "total_outcomes": total_outcomes,
                "empty_outcomes": empty_outcomes,
                "empty_ratio": empty_ratio,
                "outcome_types": dict(outcome_type_counts),
                "invalid_types": len(invalid_types),
                "min_outcomes_per_topic": self.min_learning_outcomes_per_topic
            },
            severity=severity
        )
    
    def validate_topic_quality(self, data: List[Dict], level: str) -> ValidationResult:
        """Validate topic names and quality"""
        print(f"  📋 Validating {level} topic quality...")
        
        topics = [entry.get("topic", "").strip() for entry in data]
        empty_topics = [i for i, topic in enumerate(topics) if not topic or len(topic) < 3]
        duplicate_topics = [topic for topic, count in Counter(topics).items() if count > 1]
        
        # Check for topic patterns
        very_short_topics = [topic for topic in topics if 0 < len(topic) < 5]
        very_long_topics = [topic for topic in topics if len(topic) > 100]
        
        status = "PASS" if len(empty_topics) == 0 and len(duplicate_topics) == 0 else "WARNING"
        severity = "MEDIUM" if len(empty_topics) > 5 else "LOW"
        
        return ValidationResult(
            test_name=f"Topic Quality - {level}",
            status=status,
            message=f"Found {len(empty_topics)} empty topics, {len(duplicate_topics)} duplicates",
            details={
                "total_topics": len(topics),
                "empty_topics": len(empty_topics),
                "duplicate_topics": duplicate_topics[:10],
                "very_short_topics": len(very_short_topics),
                "very_long_topics": len(very_long_topics),
                "empty_topic_indices": empty_topics[:10]
            },
            severity=severity
        )
    
    def validate_data_consistency(self, alevel_data: List[Dict], olevel_data: List[Dict]) -> ValidationResult:
        """Validate cross-level data consistency"""
        print("  🔗 Validating cross-level data consistency...")
        
        # Check for overlapping subjects between levels
        alevel_subjects = set(entry.get("subject", "") for entry in alevel_data)
        olevel_subjects = set(entry.get("subject", "") for entry in olevel_data)
        overlapping_subjects = alevel_subjects.intersection(olevel_subjects)
        
        # Check for data structure consistency
        alevel_structure = set()
        olevel_structure = set()
        
        if alevel_data:
            alevel_structure = set(alevel_data[0].keys())
        if olevel_data:
            olevel_structure = set(olevel_data[0].keys())
        
        structure_diff = alevel_structure.symmetric_difference(olevel_structure)
        
        issues = []
        if overlapping_subjects:
            issues.append(f"Overlapping subjects: {overlapping_subjects}")
        if structure_diff:
            issues.append(f"Structure differences: {structure_diff}")
        
        status = "PASS" if not issues else "WARNING"
        severity = "LOW"
        
        return ValidationResult(
            test_name="Cross-Level Consistency",
            status=status,
            message=f"Found {len(overlapping_subjects)} overlapping subjects",
            details={
                "alevel_subjects": len(alevel_subjects),
                "olevel_subjects": len(olevel_subjects),
                "overlapping_subjects": list(overlapping_subjects),
                "structure_differences": list(structure_diff),
                "issues": issues
            },
            severity=severity
        )
    
    def generate_summary_stats(self, alevel_data: List[Dict], olevel_data: List[Dict]) -> Dict[str, Any]:
        """Generate comprehensive summary statistics"""
        print("  📊 Generating summary statistics...")
        
        total_entries = len(alevel_data) + len(olevel_data)
        
        # Subject statistics
        alevel_subjects = len(set(entry.get("subject", "") for entry in alevel_data))
        olevel_subjects = len(set(entry.get("subject", "") for entry in olevel_data))
        
        # Competency statistics
        alevel_competencies = sum(len(entry.get("competences", [])) for entry in alevel_data)
        olevel_competencies = sum(len(entry.get("competences", [])) for entry in olevel_data)
        
        # Learning outcome statistics
        alevel_outcomes = 0
        for entry in alevel_data:
            for competence in entry.get("competences", []):
                alevel_outcomes += len(competence.get("learning_outcomes", []))
        
        olevel_outcomes = 0
        for entry in olevel_data:
            for competence in entry.get("competences", []):
                olevel_outcomes += len(competence.get("learning_outcomes", []))
        
        return {
            "total_entries": total_entries,
            "alevel_entries": len(alevel_data),
            "olevel_entries": len(olevel_data),
            "total_subjects": alevel_subjects + olevel_subjects,
            "alevel_subjects": alevel_subjects,
            "olevel_subjects": olevel_subjects,
            "total_competencies": alevel_competencies + olevel_competencies,
            "alevel_competencies": alevel_competencies,
            "olevel_competencies": olevel_competencies,
            "total_learning_outcomes": alevel_outcomes + olevel_outcomes,
            "alevel_learning_outcomes": alevel_outcomes,
            "olevel_learning_outcomes": olevel_outcomes,
            "avg_competencies_per_entry": (alevel_competencies + olevel_competencies) / total_entries if total_entries > 0 else 0,
            "avg_outcomes_per_competency": (alevel_outcomes + olevel_outcomes) / (alevel_competencies + olevel_competencies) if (alevel_competencies + olevel_competencies) > 0 else 0
        }
    
    def run_comprehensive_validation(self) -> ValidationReport:
        """Run comprehensive validation suite"""
        print("🔍 NCDC SYLLABUS DATA VALIDATION")
        print("=" * 50)
        print("Running comprehensive data quality checks...")
        
        start_time = datetime.now()
        
        # Load data
        alevel_data, olevel_data = self.load_data()
        
        results = []
        
        # A-Level validations
        if alevel_data:
            print(f"\n📚 A-Level Validation ({len(alevel_data)} entries)")
            results.append(self.validate_file_structure(alevel_data, "A-Level"))
            results.append(self.validate_subject_coverage(alevel_data, "A-Level"))
            results.append(self.validate_class_distribution(alevel_data, "A-Level"))
            results.append(self.validate_competency_structure(alevel_data, "A-Level"))
            results.append(self.validate_learning_outcomes(alevel_data, "A-Level"))
            results.append(self.validate_topic_quality(alevel_data, "A-Level"))
        else:
            results.append(ValidationResult(
                test_name="A-Level Data Loading",
                status="FAIL",
                message="No A-Level data found",
                details={},
                severity="HIGH"
            ))
        
        # O-Level validations
        if olevel_data:
            print(f"\n📚 O-Level Validation ({len(olevel_data)} entries)")
            results.append(self.validate_file_structure(olevel_data, "O-Level"))
            results.append(self.validate_subject_coverage(olevel_data, "O-Level"))
            results.append(self.validate_class_distribution(olevel_data, "O-Level"))
            results.append(self.validate_competency_structure(olevel_data, "O-Level"))
            results.append(self.validate_learning_outcomes(olevel_data, "O-Level"))
            results.append(self.validate_topic_quality(olevel_data, "O-Level"))
        else:
            results.append(ValidationResult(
                test_name="O-Level Data Loading",
                status="FAIL",
                message="No O-Level data found",
                details={},
                severity="HIGH"
            ))
        
        # Cross-level validation
        if alevel_data and olevel_data:
            print(f"\n🔗 Cross-Level Validation")
            results.append(self.validate_data_consistency(alevel_data, olevel_data))
        
        # Generate summary
        summary = self.generate_summary_stats(alevel_data, olevel_data)
        
        # Calculate metrics
        end_time = datetime.now()
        execution_time = (end_time - start_time).total_seconds()
        
        passed_tests = len([r for r in results if r.status == "PASS"])
        failed_tests = len([r for r in results if r.status == "FAIL"])
        warnings = len([r for r in results if r.status == "WARNING"])
        
        overall_status = "PASS" if failed_tests == 0 else "FAIL" if failed_tests > 3 else "WARNING"
        
        report = ValidationReport(
            total_tests=len(results),
            passed_tests=passed_tests,
            failed_tests=failed_tests,
            warnings=warnings,
            overall_status=overall_status,
            execution_time=execution_time,
            results=results,
            summary=summary
        )
        
        return report
    
    def save_validation_report(self, report: ValidationReport):
        """Save validation report to file"""
        report_file = self.data_dir / "validation_report.json"
        
        try:
            # Convert dataclasses to dicts for JSON serialization
            report_dict = asdict(report)
            
            with open(report_file, 'w', encoding='utf-8') as f:
                json.dump(report_dict, f, indent=2, ensure_ascii=False)
            
            print(f"\n💾 Validation report saved to: {report_file}")
        except Exception as e:
            print(f"❌ Error saving validation report: {e}")
    
    def print_summary_report(self, report: ValidationReport):
        """Print comprehensive validation summary"""
        print(f"\n📊 VALIDATION SUMMARY REPORT")
        print("=" * 60)
        
        # Overall status
        status_icon = "✅" if report.overall_status == "PASS" else "⚠️" if report.overall_status == "WARNING" else "❌"
        print(f"{status_icon} Overall Status: {report.overall_status}")
        print(f"⏱️  Execution Time: {report.execution_time:.2f}s")
        print(f"📋 Total Tests: {report.total_tests}")
        print(f"✅ Passed: {report.passed_tests}")
        print(f"❌ Failed: {report.failed_tests}")
        print(f"⚠️  Warnings: {report.warnings}")
        
        # Data summary
        print(f"\n📈 DATA SUMMARY:")
        print(f"  Total Entries: {report.summary['total_entries']}")
        print(f"  A-Level: {report.summary['alevel_entries']} entries, {report.summary['alevel_subjects']} subjects")
        print(f"  O-Level: {report.summary['olevel_entries']} entries, {report.summary['olevel_subjects']} subjects")
        print(f"  Total Competencies: {report.summary['total_competencies']}")
        print(f"  Total Learning Outcomes: {report.summary['total_learning_outcomes']}")
        print(f"  Avg Competencies/Entry: {report.summary['avg_competencies_per_entry']:.1f}")
        print(f"  Avg Outcomes/Competency: {report.summary['avg_outcomes_per_competency']:.1f}")
        
        # Failed tests
        failed_results = [r for r in report.results if r.status == "FAIL"]
        if failed_results:
            print(f"\n❌ FAILED TESTS:")
            for result in failed_results:
                print(f"  • {result.test_name}: {result.message}")
        
        # Warnings
        warning_results = [r for r in report.results if r.status == "WARNING"]
        if warning_results:
            print(f"\n⚠️  WARNINGS:")
            for result in warning_results:
                print(f"  • {result.test_name}: {result.message}")

def main():
    """Main validation runner"""
    validator = SyllabusDataValidator()
    
    print("🔍 Starting comprehensive data validation...")
    
    # Run validation
    report = validator.run_comprehensive_validation()
    
    # Print summary
    validator.print_summary_report(report)
    
    # Save report
    validator.save_validation_report(report)
    
    print(f"\n🎉 Validation completed!")
    print(f"Status: {report.overall_status}")
    
    return report

if __name__ == "__main__":
    main()
