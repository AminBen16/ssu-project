#!/usr/bin/env python3
"""
NCDC Syllabus Data Analysis and Validation Script
Analyzes extracted curriculum data for completeness and accuracy
"""

import json
from pathlib import Path
from collections import Counter, defaultdict
from typing import Dict, List, Any

class SyllabusAnalyzer:
    def __init__(self, data_dir: str = "C:/Users/user/SSU/syllabus_data_structure"):
        self.data_dir = Path(data_dir)
        
    def load_data(self) -> Dict[str, Any]:
        """Load all extracted data"""
        with open(self.data_dir / "all_syllabus_data.json", 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def analyze_subjects(self, data: List[Dict]) -> Dict[str, Any]:
        """Analyze subject distribution"""
        subjects = [entry["subject"] for entry in data]
        subject_counts = Counter(subjects)
        
        return {
            "total_subjects": len(subject_counts),
            "subjects": list(subject_counts.keys()),
            "entries_per_subject": dict(subject_counts),
            "avg_entries_per_subject": len(data) / len(subject_counts) if subject_counts else 0
        }
    
    def analyze_levels(self, data: List[Dict]) -> Dict[str, Any]:
        """Analyze level distribution"""
        levels = [entry["level"] for entry in data]
        level_counts = Counter(levels)
        
        return {
            "total_levels": len(level_counts),
            "levels": list(level_counts.keys()),
            "entries_per_level": dict(level_counts)
        }
    
    def analyze_classes(self, data: List[Dict]) -> Dict[str, Any]:
        """Analyze class/year distribution"""
        classes = [entry["class"] for entry in data]
        class_counts = Counter(classes)
        
        return {
            "total_classes": len(class_counts),
            "classes": list(class_counts.keys()),
            "entries_per_class": dict(class_counts)
        }
    
    def analyze_competencies(self, data: List[Dict]) -> Dict[str, Any]:
        """Analyze competency statements"""
        all_competencies = []
        competency_lengths = []
        
        for entry in data:
            for competence in entry["competences"]:
                comp_text = competence["text"]
                all_competencies.append(comp_text)
                competency_lengths.append(len(comp_text))
        
        return {
            "total_competencies": len(all_competencies),
            "avg_competency_length": sum(competency_lengths) / len(competency_lengths) if competency_lengths else 0,
            "min_competency_length": min(competency_lengths) if competency_lengths else 0,
            "max_competency_length": max(competency_lengths) if competency_lengths else 0,
            "sample_competencies": all_competencies[:5]
        }
    
    def analyze_learning_outcomes(self, data: List[Dict]) -> Dict[str, Any]:
        """Analyze learning outcomes"""
        all_outcomes = []
        outcome_types = []
        exam_eligibility = []
        outcome_lengths = []
        
        for entry in data:
            for competence in entry["competences"]:
                for lo in competence["learning_outcomes"]:
                    lo_text = lo["text"]
                    all_outcomes.append(lo_text)
                    outcome_types.append(lo["outcome_type"])
                    exam_eligibility.append(lo["assessment"]["exam_eligibility"])
                    outcome_lengths.append(len(lo_text))
        
        return {
            "total_outcomes": len(all_outcomes),
            "outcome_type_distribution": dict(Counter(outcome_types)),
            "exam_eligibility_distribution": dict(Counter(exam_eligibility)),
            "avg_outcome_length": sum(outcome_lengths) / len(outcome_lengths) if outcome_lengths else 0,
            "sample_outcomes": all_outcomes[:10]
        }
    
    def validate_data_quality(self, data: List[Dict]) -> Dict[str, Any]:
        """Validate data quality against NCDC specifications"""
        issues = []
        warnings = []
        
        required_fields = ["subject", "level", "class", "strand", "topic", "competences"]
        valid_outcome_types = {"knowledge", "skill", "value", "unset"}
        valid_exam_eligibility = {"yes", "no", "unset"}
        
        for i, entry in enumerate(data):
            # Check required fields
            for field in required_fields:
                if field not in entry or entry[field] in [None, "", []]:
                    issues.append(f"Entry {i}: Missing or empty field '{field}'")
            
            # Check competences
            if "competences" in entry and entry["competences"]:
                for j, competence in enumerate(entry["competences"]):
                    if "text" not in competence or not competence["text"]:
                        issues.append(f"Entry {i}, Competence {j}: Missing or empty text")
                    
                    if "learning_outcomes" not in competence or not competence["learning_outcomes"]:
                        warnings.append(f"Entry {i}, Competence {j}: No learning outcomes")
                    
                    # Check learning outcomes
                    for k, lo in enumerate(competence.get("learning_outcomes", [])):
                        if "text" not in lo or not lo["text"]:
                            issues.append(f"Entry {i}, LO {j}-{k}: Missing or empty text")
                        
                        # Check outcome type
                        outcome_type = lo.get("outcome_type", "")
                        if outcome_type not in valid_outcome_types:
                            issues.append(f"Entry {i}, LO {j}-{k}: Invalid outcome type '{outcome_type}'")
                        
                        # Check exam eligibility
                        exam_elig = lo.get("assessment", {}).get("exam_eligibility", "")
                        if exam_elig not in valid_exam_eligibility:
                            issues.append(f"Entry {i}, LO {j}-{k}: Invalid exam eligibility '{exam_elig}'")
        
        return {
            "total_issues": len(issues),
            "total_warnings": len(warnings),
            "issues": issues[:20],  # Show first 20 issues
            "warnings": warnings[:20],  # Show first 20 warnings
            "quality_score": (len(data) - len(issues)) / len(data) * 100 if data else 0
        }
    
    def generate_statistics(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Generate comprehensive statistics"""
        alevel_data = data.get("alevel", [])
        olevel_data = data.get("olevel", [])
        all_data = alevel_data + olevel_data
        
        return {
            "overall": {
                "total_entries": len(all_data),
                "alevel_entries": len(alevel_data),
                "olevel_entries": len(olevel_data),
                "subjects_analysis": self.analyze_subjects(all_data),
                "levels_analysis": self.analyze_levels(all_data),
                "classes_analysis": self.analyze_classes(all_data),
                "competencies_analysis": self.analyze_competencies(all_data),
                "learning_outcomes_analysis": self.analyze_learning_outcomes(all_data),
                "data_quality": self.validate_data_quality(all_data)
            },
            "alevel_specific": {
                "total_entries": len(alevel_data),
                "subjects_analysis": self.analyze_subjects(alevel_data),
                "competencies_analysis": self.analyze_competencies(alevel_data),
                "learning_outcomes_analysis": self.analyze_learning_outcomes(alevel_data),
                "data_quality": self.validate_data_quality(alevel_data)
            },
            "olevel_specific": {
                "total_entries": len(olevel_data),
                "subjects_analysis": self.analyze_subjects(olevel_data),
                "competencies_analysis": self.analyze_competencies(olevel_data),
                "learning_outcomes_analysis": self.analyze_learning_outcomes(olevel_data),
                "data_quality": self.validate_data_quality(olevel_data)
            }
        }
    
    def generate_report(self, stats: Dict[str, Any]) -> str:
        """Generate analysis report"""
        report = []
        report.append("# NCDC Syllabus Data Analysis Report")
        report.append("=" * 50)
        
        overall = stats["overall"]
        report.append(f"\n## OVERALL STATISTICS")
        report.append(f"Total Entries: {overall['total_entries']}")
        report.append(f"A-Level Entries: {overall['alevel_entries']}")
        report.append(f"O-Level Entries: {overall['olevel_entries']}")
        report.append(f"Total Subjects: {overall['subjects_analysis']['total_subjects']}")
        report.append(f"Data Quality Score: {overall['data_quality']['quality_score']:.1f}%")
        
        # Subjects
        subjects = overall['subjects_analysis']
        report.append(f"\n## SUBJECTS DISTRIBUTION")
        report.append(f"Total Subjects: {subjects['total_subjects']}")
        report.append(f"Average Entries per Subject: {subjects['avg_entries_per_subject']:.1f}")
        report.append("\nTop 10 Subjects by Entries:")
        for subject, count in list(subjects['entries_per_subject'].items())[:10]:
            report.append(f"- {subject}: {count} entries")
        
        # Learning Outcomes
        lo_analysis = overall['learning_outcomes_analysis']
        report.append(f"\n## LEARNING OUTCOMES ANALYSIS")
        report.append(f"Total Learning Outcomes: {lo_analysis['total_outcomes']}")
        report.append(f"Average Length: {lo_analysis['avg_outcome_length']:.1f} characters")
        report.append("\nOutcome Type Distribution:")
        for outcome_type, count in lo_analysis['outcome_type_distribution'].items():
            report.append(f"- {outcome_type}: {count}")
        
        report.append("\nExam Eligibility Distribution:")
        for eligibility, count in lo_analysis['exam_eligibility_distribution'].items():
            report.append(f"- {eligibility}: {count}")
        
        # Data Quality
        quality = overall['data_quality']
        report.append(f"\n## DATA QUALITY")
        report.append(f"Quality Score: {quality['quality_score']:.1f}%")
        report.append(f"Issues Found: {quality['total_issues']}")
        report.append(f"Warnings: {quality['total_warnings']}")
        
        if quality['issues']:
            report.append("\nSample Issues:")
            for issue in quality['issues'][:5]:
                report.append(f"- {issue}")
        
        if quality['warnings']:
            report.append("\nSample Warnings:")
            for warning in quality['warnings'][:5]:
                report.append(f"- {warning}")
        
        # Sample Data
        report.append(f"\n## SAMPLE DATA")
        report.append("Sample Learning Outcomes:")
        for i, outcome in enumerate(lo_analysis['sample_outcomes'][:5]):
            report.append(f"{i+1}. {outcome}")
        
        return "\n".join(report)
    
    def run_analysis(self) -> Dict[str, Any]:
        """Run complete analysis"""
        print("Loading extracted data...")
        data = self.load_data()
        
        print("Generating statistics...")
        stats = self.generate_statistics(data)
        
        print("Generating report...")
        report = self.generate_report(stats)
        
        # Save report
        report_file = self.data_dir / "analysis_report.md"
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report)
        
        # Save statistics
        stats_file = self.data_dir / "analysis_statistics.json"
        with open(stats_file, 'w', encoding='utf-8') as f:
            json.dump(stats, f, indent=2, ensure_ascii=False)
        
        print(f"Analysis completed!")
        print(f"Report saved to: {report_file}")
        print(f"Statistics saved to: {stats_file}")
        
        # Print summary
        overall = stats["overall"]
        print(f"\n📊 SUMMARY:")
        print(f"Total Entries: {overall['total_entries']}")
        print(f"Total Subjects: {overall['subjects_analysis']['total_subjects']}")
        print(f"Total Learning Outcomes: {overall['learning_outcomes_analysis']['total_outcomes']}")
        print(f"Data Quality Score: {overall['data_quality']['quality_score']:.1f}%")
        print(f"Issues: {overall['data_quality']['total_issues']}")
        print(f"Warnings: {overall['data_quality']['total_warnings']}")
        
        return stats

def main():
    analyzer = SyllabusAnalyzer()
    stats = analyzer.run_analysis()
    return stats

if __name__ == "__main__":
    main()
