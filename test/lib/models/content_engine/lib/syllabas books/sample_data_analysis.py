#!/usr/bin/env python3
"""
Analysis of sample extracted Agriculture syllabus data
"""

import json
from typing import Dict, List, Any

def analyze_sample_data(sample_data: List[Dict]) -> Dict[str, Any]:
    """Analyze the quality and structure of sample data"""
    
    analysis = {
        "total_entries": len(sample_data),
        "subjects": set(),
        "classes": set(),
        "topics": [],
        "outcome_types": {"knowledge": 0, "skill": 0, "value": 0},
        "exam_eligibility": {"yes": 0, "no": 0, "unset": 0},
        "assessment_modes": {"formative": 0, "summative": 0, "both": 0, "unset": 0},
        "competencies_quality": [],
        "learning_outcomes_analysis": []
    }
    
    for entry in sample_data:
        # Basic metadata
        analysis["subjects"].add(entry.get("subject", ""))
        analysis["classes"].add(entry.get("class", ""))
        analysis["topics"].append(entry.get("topic", ""))
        
        # Analyze competencies
        competences = entry.get("competences", [])
        for comp in competences:
            comp_text = comp.get("text", "")
            analysis["competencies_quality"].append({
                "text": comp_text,
                "length": len(comp_text),
                "has_meaningful_content": len(comp_text) > 20
            })
            
            # Analyze learning outcomes
            learning_outcomes = comp.get("learning_outcomes", [])
            for lo in learning_outcomes:
                lo_text = lo.get("text", "")
                analysis["learning_outcomes_analysis"].append({
                    "text": lo_text,
                    "length": len(lo_text),
                    "outcome_type": lo.get("outcome_type", ""),
                    "exam_eligibility": lo.get("assessment", {}).get("exam_eligibility", "")
                })
                
                # Count outcome types
                outcome_type = lo.get("outcome_type", "")
                if outcome_type in analysis["outcome_types"]:
                    analysis["outcome_types"][outcome_type] += 1
                
                # Count exam eligibility
                exam_elig = lo.get("assessment", {}).get("exam_eligibility", "")
                if exam_elig in analysis["exam_eligibility"]:
                    analysis["exam_eligibility"][exam_elig] += 1
                
                # Count assessment modes
                mode = lo.get("assessment", {}).get("mode", "")
                if mode in analysis["assessment_modes"]:
                    analysis["assessment_modes"][mode] += 1
    
    # Convert sets to lists
    analysis["subjects"] = list(analysis["subjects"])
    analysis["classes"] = list(analysis["classes"])
    
    return analysis

def print_analysis_report(analysis: Dict[str, Any]):
    """Print detailed analysis report"""
    
    print("📊 SAMPLE DATA ANALYSIS REPORT")
    print("=" * 50)
    
    print(f"\n📈 BASIC STATISTICS:")
    print(f"  Total Entries: {analysis['total_entries']}")
    print(f"  Subjects: {', '.join(analysis['subjects'])}")
    print(f"  Classes: {', '.join(analysis['classes'])}")
    print(f"  Topics: {len(analysis['topics'])}")
    
    print(f"\n🎯 OUTCOME TYPE DISTRIBUTION:")
    total_outcomes = sum(analysis['outcome_types'].values())
    for outcome_type, count in analysis['outcome_types'].items():
        percentage = (count / total_outcomes * 100) if total_outcomes > 0 else 0
        print(f"  {outcome_type}: {count} ({percentage:.1f}%)")
    
    print(f"\n📝 EXAM ELIGIBILITY DISTRIBUTION:")
    total_exam = sum(analysis['exam_eligibility'].values())
    for exam_type, count in analysis['exam_eligibility'].items():
        percentage = (count / total_exam * 100) if total_exam > 0 else 0
        print(f"  {exam_type}: {count} ({percentage:.1f}%)")
    
    print(f"\n🔍 COMPETENCY QUALITY ANALYSIS:")
    comp_lengths = [comp['length'] for comp in analysis['competencies_quality']]
    meaningful_comps = [comp for comp in analysis['competencies_quality'] if comp['has_meaningful_content']]
    
    print(f"  Total Competencies: {len(analysis['competencies_quality'])}")
    print(f"  Average Length: {sum(comp_lengths)/len(comp_lengths):.1f} characters")
    print(f"  Meaningful Competencies: {len(meaningful_comps)}/{len(analysis['competencies_quality'])}")
    print(f"  Quality Rate: {(len(meaningful_comps)/len(analysis['competencies_quality'])*100):.1f}%")
    
    print(f"\n📚 LEARNING OUTCOMES ANALYSIS:")
    lo_lengths = [lo['length'] for lo in analysis['learning_outcomes_analysis']]
    print(f"  Total Learning Outcomes: {len(analysis['learning_outcomes_analysis'])}")
    print(f"  Average Length: {sum(lo_lengths)/len(lo_lengths):.1f} characters")
    
    # Sample learning outcomes by type
    print(f"\n📋 SAMPLE LEARNING OUTCOMES BY TYPE:")
    outcomes_by_type = {}
    for lo in analysis['learning_outcomes_analysis']:
        outcome_type = lo['outcome_type']
        if outcome_type not in outcomes_by_type:
            outcomes_by_type[outcome_type] = []
        outcomes_by_type[outcome_type].append(lo)
    
    for outcome_type, outcomes in outcomes_by_type.items():
        print(f"  \n{outcome_type.upper()} Examples:")
        for i, lo in enumerate(outcomes[:2]):  # Show first 2 examples
            print(f"    {i+1}. {lo['text'][:80]}...")
            print(f"       Exam Eligibility: {lo['exam_eligibility']}")

def main():
    # Sample data from the user's input
    sample_data = [
        {
            "subject": "AGRIC",
            "level": "Lower Secondary",
            "class": "SENIOR 1",
            "strand": "General",
            "sub_strand": None,
            "topic": "Term 1: Introduction to Agriculture",
            "suggested_periods": None,
            "competences": [
                {
                    "text": "The learner understands the sector and opportunities in agriculture for making a living in Uganda.",
                    "learning_outcomes": [
                        {
                            "text": "Understand the historical background of agriculture in terms of animal herding, nomadic way of life, food gathering, hunting, and nomadism",
                            "outcome_type": "knowledge",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "unset"
                            },
                            "cross_cutting_issues": []
                        },
                        {
                            "text": "Understand the value of agriculture to human beings and society, and the importance of the farm as a production unit",
                            "outcome_type": "knowledge",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "unset"
                            },
                            "cross_cutting_issues": []
                        },
                        {
                            "text": "Understand the value of various farming systems and their socioeconomic impact in Uganda",
                            "outcome_type": "knowledge",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "unset"
                            },
                            "cross_cutting_issues": []
                        },
                        {
                            "text": "Understand the importance of keeping records in agriculture",
                            "outcome_type": "knowledge",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "no"
                            },
                            "cross_cutting_issues": []
                        },
                        {
                            "text": "Understand the requirements of a career in agriculture and key principles of the Labour Act on living conditions of farmworkers",
                            "outcome_type": "knowledge",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "unset"
                            },
                            "cross_cutting_issues": []
                        }
                    ]
                }
            ]
        },
        {
            "subject": "AGRIC",
            "level": "Lower Secondary",
            "class": "SENIOR 1",
            "strand": "General",
            "sub_strand": None,
            "topic": "Term 2: Farm Tools, Equipment and Implements",
            "suggested_periods": None,
            "competences": [
                {
                    "text": "The learner uses measurement tools, farm tools, equipment, and implements properly and safely in agricultural activities.",
                    "learning_outcomes": [
                        {
                            "text": "Identify tools used on the farm, including garden tools, wood working tools, metal tools, and basic tools used for fencing, mechanics and other farming activities",
                            "outcome_type": "knowledge",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "yes"
                            },
                            "cross_cutting_issues": []
                        },
                        {
                            "text": "Demonstrate skills of using farm tools and implements correctly for better production",
                            "outcome_type": "skill",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "yes"
                            },
                            "cross_cutting_issues": []
                        },
                        {
                            "text": "Show skill in using common measurement tools for length, volume, time and mass/weight",
                            "outcome_type": "skill",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "no"
                            },
                            "cross_cutting_issues": []
                        },
                        {
                            "text": "Show skills in handling conversion of agricultural measurements into SI units",
                            "outcome_type": "skill",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "no"
                            },
                            "cross_cutting_issues": []
                        },
                        {
                            "text": "Demonstrate basic occupational safety and health standards in agriculture",
                            "outcome_type": "skill",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "yes"
                            },
                            "cross_cutting_issues": []
                        },
                        {
                            "text": "Show skills in applying the steps in giving first aid on the farm and during agricultural activities",
                            "outcome_type": "skill",
                            "lesson_unit": "single_outcome",
                            "activities": [],
                            "materials": [],
                            "assessment": {
                                "guidance": None,
                                "mode": "formative",
                                "exam_eligibility": "yes"
                            },
                            "cross_cutting_issues": []
                        }
                    ]
                }
            ]
        }
    ]
    
    # Analyze the sample data
    analysis = analyze_sample_data(sample_data)
    
    # Print the report
    print_analysis_report(analysis)
    
    return analysis

if __name__ == "__main__":
    main()
