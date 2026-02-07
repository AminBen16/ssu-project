#!/usr/bin/env python3
"""
Simple NCDC Syllabus Data Extraction Script
Focused on robust extraction with minimal complexity
"""

import os
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Any

class SimpleNCDCExtractor:
    def __init__(self, base_dir: str = "C:/Users/user/SSU"):
        self.base_dir = Path(base_dir)
        self.alevel_dir = self.base_dir / "cleaned_alevel_syllabi"
        self.olevel_dir = self.base_dir / "cleaned_olevel_syllabi"
        self.output_dir = self.base_dir / "syllabus_data_structure"
        self.output_dir.mkdir(exist_ok=True)
        
        # Command verbs for exam eligibility
        self.exam_verbs = {
            'define', 'explain', 'describe', 'apply', 'analyze', 'evaluate',
            'identify', 'compare', 'contrast', 'discuss', 'demonstrate',
            'calculate', 'solve', 'create', 'design', 'develop', 'assess'
        }
        
    def extract_subject_level(self, filename: str) -> tuple:
        """Extract subject name and level from filename"""
        if filename.startswith("ALEVEL_"):
            subject = filename[7:].replace("_clean.md", "").replace("-", " ")
            return subject, "Advanced Secondary"
        else:
            subject = filename.replace("_clean.md", "").replace("_SYLLABUS", "").replace("-", " ")
            return subject, "Lower Secondary"
    
    def extract_class_from_content(self, content: str) -> str:
        """Extract class/year information from content"""
        # Look for patterns like "SENIOR FIVE", "SENIOR 1", "S1", etc.
        class_patterns = [
            # A-Level patterns
            r'(SENIOR (FIVE|SIX))',
            r'(Senior (Five|Six))',
            r'(S[5-6])',
            
            # O-Level patterns  
            r'(SENIOR ([1-4]))',
            r'(Senior ([1-4]))',
            r'(S[1-4])',
            
            # General patterns
            r'(YEAR ([1-6]))',
            r'(Class ([1-6]))',
            
            # Header patterns
            r'\*\*Years?\*\*: ([^\n]+)',
            r'\*\*Duration\*\*: ([^\n]+)',
            r'\*\*Level\*\*: ([^\n]+)'
        ]
        
        for pattern in class_patterns:
            match = re.search(pattern, content, re.IGNORECASE)
            if match:
                class_name = match.group(1) if match.lastindex >= 1 else match.group(0)
                
                # Clean up the class name
                class_name = class_name.strip()
                
                # Handle special cases and normalize class names
                if "Senior 5-6" in class_name or "Senior Five" in class_name or "SENIOR FIVE" in class_name:
                    return "SENIOR FIVE"
                elif "Senior Six" in class_name or "SENIOR SIX" in class_name:
                    return "SENIOR SIX"
                elif "Senior 1-4" in class_name or "Senior 1" in class_name or "SENIOR 1" in class_name:
                    return "SENIOR 1"
                elif "Senior 2" in class_name or "SENIOR 2" in class_name:
                    return "SENIOR 2"
                elif "Senior 3" in class_name or "SENIOR 3" in class_name:
                    return "SENIOR 3"
                elif "Senior 4" in class_name or "SENIOR 4" in class_name:
                    return "SENIOR 4"
                elif "Advanced Secondary" in class_name or "A-Level" in class_name:
                    return "SENIOR FIVE"
                elif "Lower Secondary" in class_name or "O-Level" in class_name:
                    return "SENIOR 1"
                elif class_name in ["S5", "S6"]:
                    return f"SENIOR {class_name[1]}"
                elif class_name in ["S1", "S2", "S3", "S4"]:
                    return f"SENIOR {class_name[1]}"
                elif class_name.isdigit():
                    class_num = int(class_name)
                    if class_num >= 5:
                        return "SENIOR FIVE" if class_num == 5 else "SENIOR SIX"
                    else:
                        return f"SENIOR {class_num}"
                
                # Normalize existing class names
                if "Senior" in class_name:
                    return class_name.upper().replace("SENIOR ", "SENIOR ")
                
                return class_name
        
        # Default fallback based on file content analysis
        if "Advanced Secondary" in content or "A-Level" in content:
            return "SENIOR FIVE"
        elif "Lower Secondary" in content or "O-Level" in content:
            return "SENIOR 1"
        
        return "Unknown"
    
    def extract_class_from_broad_context(self, full_content: str, section: str) -> str:
        """Extract class information from broader context including section headers"""
        # First try the original method
        class_info = self.extract_class_from_content(full_content)
        if class_info != "Unknown":
            return class_info
        
        # If still unknown, look for class patterns in the full content
        # Find the position of this section in the full content
        section_pos = full_content.find(section)
        if section_pos == -1:
            # Fallback to level-based detection
            if "Advanced Secondary" in full_content or "A-Level" in full_content:
                return "SENIOR FIVE"
            elif "Lower Secondary" in full_content or "O-Level" in full_content:
                return "SENIOR 1"
            return "Unknown"
        
        # Look backwards from section position to find class headers
        context_start = max(0, section_pos - 1000)  # Look 1000 chars back
        context = full_content[context_start:section_pos]
        
        # Class header patterns
        class_patterns = [
            r'### (SENIOR [1-6])',
            r'### (Senior [1-6|Five|Six])',
            r'## (SENIOR [1-6])',
            r'## (Senior [1-6|Five|Six])',
            r'(SENIOR [1-6])\s*\(',
            r'(Senior [1-6|Five|Six])\s*\(',
        ]
        
        # Search for class patterns in reverse order (closest to section first)
        for pattern in class_patterns:
            matches = list(re.finditer(pattern, context, re.IGNORECASE))
            if matches:
                # Get the last match (closest to the section)
                class_match = matches[-1]
                class_name = class_match.group(1).strip()
                
                # Normalize the class name
                class_name = self.normalize_class_name(class_name)
                return class_name
        
        # If still not found, try to determine from level
        if "Advanced Secondary" in full_content or "A-Level" in full_content:
            return "SENIOR FIVE"
        elif "Lower Secondary" in full_content or "O-Level" in full_content:
            return "SENIOR 1"
        
        return "Unknown"
    
    def normalize_class_name(self, class_name: str) -> str:
        """Normalize class name to standard format"""
        class_name = class_name.strip()
        
        # Handle various formats
        if "Senior 5-6" in class_name or "Senior Five" in class_name or "SENIOR FIVE" in class_name:
            return "SENIOR FIVE"
        elif "Senior Six" in class_name or "SENIOR SIX" in class_name:
            return "SENIOR SIX"
        elif "Senior 1" in class_name or "SENIOR 1" in class_name:
            return "SENIOR 1"
        elif "Senior 2" in class_name or "SENIOR 2" in class_name:
            return "SENIOR 2"
        elif "Senior 3" in class_name or "SENIOR 3" in class_name:
            return "SENIOR 3"
        elif "Senior 4" in class_name or "SENIOR 4" in class_name:
            return "SENIOR 4"
        elif class_name in ["S5", "S6"]:
            return f"SENIOR {class_name[1]}"
        elif class_name in ["S1", "S2", "S3", "S4"]:
            return f"SENIOR {class_name[1]}"
        elif class_name.isdigit():
            class_num = int(class_name)
            if class_num >= 5:
                return "SENIOR FIVE" if class_num == 5 else "SENIOR SIX"
            else:
                return f"SENIOR {class_num}"
        
        # Normalize existing class names
        if "Senior" in class_name:
            return class_name.upper().replace("SENIOR ", "SENIOR ")
        
        return class_name
    
    def extract_periods_from_text(self, text: str) -> Optional[int]:
        """Extract period number from text like '(90 periods)' or '90 periods'"""
        period_patterns = [
            r'\((\d+)\s*periods?\)',
            r'(\d+)\s*periods?',
            r'\((\d+)\s*period\)',
            r'(\d+)\s*period',
        ]
        
        for pattern in period_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                try:
                    return int(match.group(1))
                except ValueError:
                    continue
        
        return None
    
    def extract_topics_and_competencies(self, content: str) -> List[Dict]:
        """Extract topics and their competencies from content"""
        topics_data = []
        
        # Try different section splitting patterns
        section_patterns = [
            r'\n#### ',  # Standard topic headers
            r'\n### ',   # Alternative headers
            r'\n## ',    # Major sections
        ]
        
        sections = []
        for pattern in section_patterns:
            sections = re.split(pattern, content)
            if len(sections) > 1:
                break
        
        for section in sections[1:]:  # Skip first section (before first header)
            lines = section.strip().split('\n')
            if not lines:
                continue
                
            # Extract topic name from first line
            topic_line = lines[0]
            
            # Multiple topic patterns
            topic_patterns = [
                r'Topic ([\d.]+): (.+)',
                r'(.+?)\s*\((\d+) periods?\)',  # "Topic Name (63 periods)"
                r'(.+?)\s*\*\*',               # "Topic Name**"
                r'^(.+)$'                      # Fallback: first line as topic
            ]
            
            topic_name = None
            topic_num = None
            
            for pattern in topic_patterns:
                match = re.match(pattern, topic_line)
                if match:
                    if pattern == topic_patterns[0]:  # Topic 1.1: Name
                        topic_num = match.group(1)
                        topic_name = match.group(2).strip()
                    elif pattern == topic_patterns[1]:  # Name (periods)
                        topic_name = match.group(1).strip()
                        topic_num = match.group(2)
                    elif pattern == topic_patterns[2]:  # Name**
                        topic_name = match.group(1).strip()
                    else:  # Fallback
                        topic_name = match.group(1).strip()
                    break
            
            if not topic_name:
                continue
            
            # Clean topic name but preserve period info separately
            periods = self.extract_periods_from_text(topic_name)
            clean_topic_name = re.sub(r'\s*\(\d+\s*periods?\)', '', topic_name)  # Remove period info from name
            clean_topic_name = re.sub(r'\*\*$', '', clean_topic_name)  # Remove trailing **
            
            # Find competency in this section
            competency_text = ""
            learning_outcomes = []
            
            # Look for competency patterns
            competency_patterns = [
                r'\*\*Competency:\*\* (.+)',
                r'\*\*Competence:\*\* (.+)',
                r'Competency[:\s]* (.+)',
                r'The learner (.+)',
            ]
            
            for pattern in competency_patterns:
                competency_match = re.search(pattern, section, re.IGNORECASE)
                if competency_match:
                    competency_text = competency_match.group(1).strip()
                    break
            
            # Look for learning outcomes
            lo_patterns = [
                r'\*\*Learning Outcomes:\*\*\s*\n((?:-\s*[^\n]+\s*\n?)*)',
                r'The learner should be able to:\s*\n((?:-\s*[^\n]+\s*\n?)*)',
                r'Learning outcomes?:\s*\n((?:[-\*]\s*[^\n]+\s*\n?)*)',
            ]
            
            for pattern in lo_patterns:
                lo_match = re.search(pattern, section, re.IGNORECASE)
                if lo_match:
                    lo_text = lo_match.group(1)
                    outcomes = re.findall(r'[-\*]\s*([^\n]+)', lo_text)
                    learning_outcomes = [outcome.strip() for outcome in outcomes if outcome.strip()]
                    if learning_outcomes:
                        break
            
            # If no learning outcomes found, try broader search
            if not learning_outcomes:
                # Look for any bullet points in the section
                bullet_points = re.findall(r'[-\*]\s*([^\n]+)', section[:500])  # First 500 chars
                learning_outcomes = [bp.strip() for bp in bullet_points if bp.strip() and len(bp.strip()) > 10][:10]
            
            # Generate competency if not found
            if not competency_text:
                if topic_num:
                    competency_text = f"Understanding of {topic_name}"
                else:
                    competency_text = f"The learner demonstrates understanding of {topic_name}"
            
            # Only add if we have meaningful data
            if clean_topic_name and (competency_text or learning_outcomes):
                # Extract class from broader context, not just the section
                class_info = self.extract_class_from_broad_context(content, section)
                
                topic_data = {
                    "class": class_info,
                    "strand": clean_topic_name,
                    "topic": clean_topic_name,
                    "suggested_periods": periods,
                    "competency": competency_text,
                    "learning_outcomes": learning_outcomes
                }
                
                topics_data.append(topic_data)
        
        # If no topics found with standard patterns, try alternative approach
        if not topics_data:
            # Look for any competency statements in the entire content
            competency_matches = re.finditer(r'\*\*Competency:\*\* ([^\n]+)', content, re.IGNORECASE)
            
            for match in competency_matches:
                competency_text = match.group(1).strip()
                
                # Extract surrounding context
                start_pos = max(0, match.start() - 200)
                end_pos = min(len(content), match.end() + 500)
                context = content[start_pos:end_pos]
                
                # Try to find topic name
                topic_patterns = [
                    r'\*\*([^\*]+)\*\*',
                    r'#### (.+)',
                    r'### (.+)',
                ]
                
                topic_name = "General Topic"
                periods = None
                for pattern in topic_patterns:
                    topic_match = re.search(pattern, context[:match.start() - start_pos])
                    if topic_match:
                        topic_name = topic_match.group(1).strip()
                        # Extract periods from the topic name
                        periods = self.extract_periods_from_text(topic_name)
                        # Clean topic name by removing period info
                        topic_name = re.sub(r'\s*\(\d+\s*periods?\)', '', topic_name)
                        break
                
                # Extract learning outcomes
                lo_patterns = [
                    r'\*\*Learning Outcomes:\*\*\s*\n((?:-\s*[^\n]+\s*\n?)*)',
                    r'The learner should be able to:\s*\n((?:-\s*[^\n]+\s*\n?)*)',
                ]
                
                learning_outcomes = []
                for pattern in lo_patterns:
                    lo_match = re.search(pattern, context, re.IGNORECASE)
                    if lo_match:
                        lo_text = lo_match.group(1)
                        outcomes = re.findall(r'-\s*([^\n]+)', lo_text)
                        learning_outcomes = [outcome.strip() for outcome in outcomes]
                        break
                
                class_info = self.extract_class_from_broad_context(content, context)
                
                topic_data = {
                    "class": class_info,
                    "strand": topic_name,
                    "topic": topic_name,
                    "suggested_periods": periods,
                    "competency": competency_text,
                    "learning_outcomes": learning_outcomes
                }
                
                topics_data.append(topic_data)
        
        return topics_data
    
    def determine_outcome_type(self, outcome_text: str) -> str:
        """Determine outcome type based on command verbs"""
        text_lower = outcome_text.lower()
        
        # Knowledge outcomes
        if any(verb in text_lower for verb in ['define', 'explain', 'describe', 'identify', 'state', 'list', 'name', 'recognize']):
            return "knowledge"
        
        # Skill outcomes
        elif any(verb in text_lower for verb in ['apply', 'analyze', 'create', 'develop', 'demonstrate', 'design', 'implement', 'use']):
            return "skill"
        
        # Value outcomes
        elif any(verb in text_lower for verb in ['evaluate', 'assess', 'compare', 'appreciate', 'respect', 'value', 'justify']):
            return "value"
        
        return "unset"
    
    def determine_exam_eligibility(self, outcome_text: str) -> str:
        """Determine exam eligibility based on command verbs"""
        text_lower = outcome_text.lower()
        
        if any(verb in text_lower for verb in self.exam_verbs):
            return "yes"
        
        return "unset"
    
    def create_structured_entry(self, file_path: Path, topic_data: Dict) -> Dict:
        """Create a structured syllabus entry"""
        subject, level = self.extract_subject_level(file_path.name)
        
        # Create learning outcomes with metadata
        structured_outcomes = []
        for lo_text in topic_data["learning_outcomes"]:
            outcome = {
                "text": lo_text,
                "outcome_type": self.determine_outcome_type(lo_text),
                "lesson_unit": "single_outcome",
                "activities": [],
                "materials": [],
                "assessment": {
                    "guidance": None,
                    "mode": "formative",
                    "exam_eligibility": self.determine_exam_eligibility(lo_text)
                },
                "cross_cutting_issues": []
            }
            structured_outcomes.append(outcome)
        
        # Create competence
        competence = {
            "text": topic_data["competency"],
            "learning_outcomes": structured_outcomes
        }
        
        # Create main entry
        entry = {
            "subject": subject,
            "level": level,
            "class": topic_data["class"],
            "strand": topic_data["strand"],
            "sub_strand": None,
            "topic": topic_data["topic"],
            "suggested_periods": topic_data.get("suggested_periods"),
            "competences": [competence]
        }
        
        return entry
    
    def process_single_file(self, file_path: Path) -> List[Dict]:
        """Process a single markdown file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return []
        
        # Extract topics and competencies
        topics_data = self.extract_topics_and_competencies(content)
        
        if not topics_data:
            return []
        
        # Create structured entries
        entries = []
        for topic_data in topics_data:
            entry = self.create_structured_entry(file_path, topic_data)
            entries.append(entry)
        
        return entries
    
    def process_all_files(self) -> Dict[str, Any]:
        """Process all files and return results"""
        results = {
            "alevel": [],
            "olevel": [],
            "summary": {
                "total_files": 0,
                "processed_files": 0,
                "failed_files": [],
                "total_entries": 0
            }
        }
        
        # Process A-Level files
        print("Processing A-Level files...")
        alevel_files = list(self.alevel_dir.glob("*_clean.md"))
        
        for file_path in alevel_files:
            print(f"Processing: {file_path.name}")
            try:
                entries = self.process_single_file(file_path)
                if entries:
                    results["alevel"].extend(entries)
                    results["summary"]["processed_files"] += 1
                    results["summary"]["total_entries"] += len(entries)
                else:
                    results["summary"]["failed_files"].append(file_path.name)
                results["summary"]["total_files"] += 1
            except Exception as e:
                print(f"Error processing {file_path.name}: {e}")
                results["summary"]["failed_files"].append(file_path.name)
                results["summary"]["total_files"] += 1
        
        # Process O-Level files
        print("\nProcessing O-Level files...")
        olevel_files = list(self.olevel_dir.glob("*_clean.md"))
        
        for file_path in olevel_files:
            print(f"Processing: {file_path.name}")
            try:
                entries = self.process_single_file(file_path)
                if entries:
                    results["olevel"].extend(entries)
                    results["summary"]["processed_files"] += 1
                    results["summary"]["total_entries"] += len(entries)
                else:
                    results["summary"]["failed_files"].append(file_path.name)
                results["summary"]["total_files"] += 1
            except Exception as e:
                print(f"Error processing {file_path.name}: {e}")
                results["summary"]["failed_files"].append(file_path.name)
                results["summary"]["total_files"] += 1
        
        return results
    
    def save_results(self, results: Dict[str, Any]) -> None:
        """Save results to JSON files"""
        # Save individual files
        with open(self.output_dir / "alevel_syllabus_data.json", 'w', encoding='utf-8') as f:
            json.dump(results["alevel"], f, indent=2, ensure_ascii=False)
        
        with open(self.output_dir / "olevel_syllabus_data.json", 'w', encoding='utf-8') as f:
            json.dump(results["olevel"], f, indent=2, ensure_ascii=False)
        
        with open(self.output_dir / "extraction_summary.json", 'w', encoding='utf-8') as f:
            json.dump(results["summary"], f, indent=2, ensure_ascii=False)
        
        # Save combined
        combined = {
            "alevel": results["alevel"],
            "olevel": results["olevel"],
            "summary": results["summary"]
        }
        with open(self.output_dir / "all_syllabus_data.json", 'w', encoding='utf-8') as f:
            json.dump(combined, f, indent=2, ensure_ascii=False)
        
        print(f"\nResults saved to: {self.output_dir}")
    
    def run(self):
        """Run the extraction process"""
        print("Starting Simple NCDC Syllabus Extraction...")
        
        results = self.process_all_files()
        
        print(f"\nExtraction Summary:")
        print(f"Total files: {results['summary']['total_files']}")
        print(f"Processed files: {results['summary']['processed_files']}")
        print(f"Failed files: {len(results['summary']['failed_files'])}")
        print(f"Total entries extracted: {results['summary']['total_entries']}")
        
        if results['summary']['failed_files']:
            print(f"Failed files: {results['summary']['failed_files'][:5]}...")  # Show first 5
        
        self.save_results(results)
        
        return results

def main():
    extractor = SimpleNCDCExtractor()
    results = extractor.run()
    print("\nExtraction completed!")
    return results

if __name__ == "__main__":
    main()
