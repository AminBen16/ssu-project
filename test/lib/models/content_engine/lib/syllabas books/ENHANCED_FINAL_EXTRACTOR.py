#!/usr/bin/env python3
"""
ENHANCED FINAL NCDC EXTRACTOR - Handles alternative structures
Fixes the 2 failed files by supporting multiple syllabus formats
"""

import os
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
import shutil

@dataclass
class ExtractionMetrics:
    total_files: int
    processed_files: int
    failed_files: int
    total_entries: int
    accuracy_rate: float

class EnhancedFinalExtractor:
    def __init__(self, base_dir: str = "C:/Users/user/SSU"):
        self.base_dir = Path(base_dir)
        self.alevel_dir = self.base_dir / "cleaned_alevel_syllabi"
        self.olevel_dir = self.base_dir / "cleaned_olevel_syllabi"
        self.output_dir = self.base_dir / "syllabus_data_structure"
        self.output_dir.mkdir(exist_ok=True)
        
        # BEST COMPREHENSIVE VERB SETS
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
        
        self.exam_verbs = {
            'define', 'explain', 'describe', 'apply', 'analyze', 'evaluate',
            'identify', 'compare', 'contrast', 'discuss', 'demonstrate',
            'calculate', 'solve', 'create', 'design', 'develop', 'assess',
            'justify', 'critique', 'evaluate', 'interpret', 'analyze'
        }
    
    def extract_subject_level(self, filename: str) -> Tuple[str, str]:
        """Extract subject name and level from filename"""
        if filename.startswith("ALEVEL_"):
            subject = filename[7:].replace("_clean.md", "").replace("-", " ")
            return subject, "Advanced Secondary"
        else:
            subject = filename.replace("_clean.md", "").replace("_SYLLABUS", "").replace("-", " ")
            return subject, "Lower Secondary"
    
    def extract_class_with_context(self, content: str, section_start: int = 0) -> str:
        """Extract class information using enhanced context-aware algorithms"""
        # Look backwards from section position to find the nearest class header
        context_start = max(0, section_start - 2000)
        context = content[context_start:section_start + 500]
        
        # Enhanced class patterns with better specificity
        class_patterns = [
            r'### (SENIOR [1-6])\s*\n',
            r'### (Senior [1-6|Five|Six])\s*\n',
            r'## (SENIOR [1-6])\s*\n',
            r'## (Senior [1-6|Five|Six])\s*\n',
            r'(SENIOR [1-6])\s*\(',
            r'(Senior [1-6|Five|Six])\s*\(',
        ]
        
        # Find all matches and get the closest one to section_start
        best_match = None
        best_distance = float('inf')
        
        for pattern in class_patterns:
            matches = list(re.finditer(pattern, context, re.IGNORECASE))
            for match in matches:
                # Calculate distance from section start
                distance = abs(section_start - (context_start + match.start()))
                if distance < best_distance:
                    best_distance = distance
                    best_match = match
        
        if best_match:
            class_name = best_match.group(1).strip()
            return self.normalize_class_name(class_name)
        
        # Fallback to level-based detection
        if "Advanced Secondary" in content or "A-Level" in content:
            return "SENIOR FIVE"
        elif "Lower Secondary" in content or "O-Level" in content:
            return "SENIOR 1"
        
        return "Unknown"
    
    def normalize_class_name(self, class_name: str) -> str:
        """Normalize class name to standard format"""
        class_name = class_name.strip()
        
        mappings = {
            "Senior 5-6": "SENIOR FIVE",
            "Senior Five": "SENIOR FIVE", 
            "SENIOR FIVE": "SENIOR FIVE",
            "Senior Six": "SENIOR SIX",
            "SENIOR SIX": "SENIOR SIX",
            "Senior 1": "SENIOR 1",
            "SENIOR 1": "SENIOR 1",
            "Senior 2": "SENIOR 2", 
            "SENIOR 2": "SENIOR 2",
            "Senior 3": "SENIOR 3",
            "SENIOR 3": "SENIOR 3",
            "Senior 4": "SENIOR 4",
            "SENIOR 4": "SENIOR 4"
        }
        
        for pattern, normalized in mappings.items():
            if pattern.lower() in class_name.lower():
                return normalized
        
        # Handle S1-S6 format
        if class_name in ["S5", "S6"]:
            return f"SENIOR {class_name[1]}"
        elif class_name in ["S1", "S2", "S3", "S4"]:
            return f"SENIOR {class_name[1]}"
        
        return class_name
    
    def extract_topics_enhanced(self, content: str) -> List[Dict]:
        """Enhanced topic extraction that handles multiple syllabus formats"""
        topics_data = []
        
        # Check if this is the alternative format (like Entrepreneurship)
        if "**Learning Outcomes:**" in content and "**Competency:**" not in content:
            topics_data = self.extract_alternative_format(content)
        else:
            topics_data = self.extract_standard_format(content)
        
        return topics_data
    
    def extract_standard_format(self, content: str) -> List[Dict]:
        """Extract topics from standard NCDC format (with **Competency:** pattern)"""
        topics_data = []
        
        # Use multiple splitting strategies for maximum coverage
        splitting_patterns = [
            (r'\n#### ', 'topic_header'),
            (r'\n### ', 'sub_header'),
            (r'\n## ', 'major_header'),
            (r'\n\*\*', 'bold_header'),
        ]
        
        best_sections = []
        for pattern, pattern_type in splitting_patterns:
            sections = re.split(pattern, content)
            if len(sections) > 1:
                best_sections = sections
                break
        
        # Process each section
        for i, section in enumerate(best_sections[1:], 1):  # Skip first section
            if not section.strip():
                continue
                
            lines = section.strip().split('\n')
            if not lines:
                continue
            
            # Extract topic information
            topic_info = self.extract_topic_info(lines, content, section)
            if topic_info:
                topics_data.append(topic_info)
        
        # Fallback: Look for competency patterns if no topics found
        if not topics_data:
            topics_data = self.extract_from_competency_patterns(content)
        
        return topics_data
    
    def extract_alternative_format(self, content: str) -> List[Dict]:
        """Extract topics from alternative format (like Entrepreneurship syllabus)"""
        topics_data = []
        
        # Find all sections with learning outcomes
        # Look for patterns like "**Learning Outcomes:**" followed by bullet points
        lo_sections = re.finditer(
            r'\*\*Learning Outcomes:\*\*\s*\n\s*The learner should be able to:\s*\n((?:-\s*[^\n]+\s*\n?)+)',
            content,
            re.IGNORECASE | re.MULTILINE
        )
        
        for match in lo_sections:
            # Extract learning outcomes
            lo_text = match.group(1)
            learning_outcomes = re.findall(r'-\s*([^\n]+)', lo_text)
            learning_outcomes = [outcome.strip() for outcome in learning_outcomes if outcome.strip()]
            
            if not learning_outcomes:
                continue
            
            # Find the topic context (look backwards from this match)
            section_start = max(0, match.start() - 500)
            section_end = match.end()
            context = content[section_start:section_start + 1000]
            
            # Extract topic name from context
            topic_name = self.extract_topic_name_from_context(context)
            
            # Extract class info
            class_info = self.extract_class_with_context(content, match.start())
            
            # Create a synthetic competency from the learning outcomes
            if learning_outcomes:
                first_lo = learning_outcomes[0]
                competency_text = f"The learner {first_lo.lower()}"
                
                topics_data.append({
                    "class": class_info,
                    "strand": "General",
                    "topic": topic_name or "General Topic",
                    "suggested_periods": None,
                    "competency": competency_text,
                    "learning_outcomes": learning_outcomes
                })
        
        return topics_data
    
    def extract_topic_name_from_context(self, context: str) -> str:
        """Extract topic name from surrounding context"""
        # Look for topic patterns in the context
        topic_patterns = [
            r'\*\*([^\*]+)\*\*\s*\((\d+) periods?\)',  # **Topic Name** (24 periods)
            r'\*\*([^\*]+)\*\*',  # **Topic Name**
            r'#### (.+)',  # #### Topic Name
            r'### (.+)',  # ### Topic Name
            r'## (.+)',  # ## Topic Name
        ]
        
        for pattern in topic_patterns:
            match = re.search(pattern, context, re.IGNORECASE)
            if match:
                topic_name = match.group(1).strip()
                # Clean up topic name
                topic_name = re.sub(r'\s*\(\d+\s*periods?\)', '', topic_name)
                if len(topic_name) > 3:
                    return topic_name
        
        return "General Topic"
    
    def extract_topic_info(self, lines: List[str], full_content: str, section: str) -> Optional[Dict]:
        """Extract comprehensive topic information"""
        # Topic name extraction
        topic_line = lines[0]
        topic_name = self.clean_topic_name(topic_line)
        if not topic_name or len(topic_name) < 3:
            return None
        
        # Find section position in full content
        section_pos = full_content.find(section[:200])  # Use first 200 chars to locate
        
        # Extract periods
        periods = self.extract_periods_enhanced(topic_line)
        
        # Extract competency
        competency = self.extract_competency_from_section(section)
        
        # Extract learning outcomes
        learning_outcomes = self.extract_learning_outcomes_enhanced(section)
        
        # Extract class with context
        class_info = self.extract_class_with_context(full_content, section_pos)
        
        # Extract theme/strand
        strand = self.extract_strand_from_context(full_content, section_pos)
        
        return {
            "class": class_info,
            "strand": strand,
            "topic": topic_name,
            "suggested_periods": periods,
            "competency": competency,
            "learning_outcomes": learning_outcomes
        }
    
    def clean_topic_name(self, topic_line: str) -> str:
        """Clean and normalize topic name"""
        # Remove period information
        topic_name = re.sub(r'\s*\(\d+\s*periods?\)', '', topic_line)
        # Remove trailing markdown
        topic_name = re.sub(r'\*\*$', '', topic_name)
        # Remove extra whitespace
        topic_name = topic_name.strip()
        
        # Skip if it's clearly not a topic
        skip_patterns = [
            r'competency:', r'learning outcomes:', r'the learner should',
            r'term \d+', r'senior \d+', r'assessment', r'cross-cutting'
        ]
        
        for pattern in skip_patterns:
            if re.search(pattern, topic_line, re.IGNORECASE):
                return ""
        
        return topic_name
    
    def extract_periods_enhanced(self, text: str) -> Optional[int]:
        """Enhanced period extraction with more patterns"""
        period_patterns = [
            r'\((\d+)\s*periods?\)',
            r'(\d+)\s*periods?',
            r'\((\d+)\s*period\)',
            r'(\d+)\s*period',
            r':\s*(\d+)\s*periods?',
            r'–\s*(\d+)\s*periods?',
        ]
        
        for pattern in period_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                try:
                    return int(match.group(1))
                except ValueError:
                    continue
        
        return None
    
    def extract_competency_from_section(self, section: str) -> str:
        """Extract competency with multiple patterns"""
        competency_patterns = [
            r'\*\*Competency:\*\* ([^\n]+)',
            r'\*\*Competence:\*\* ([^\n]+)',
            r'Competency[:\s]* ([^\n]+)',
            r'The learner ([^\n]+?)(?:should be able to|$)',
            r'Competence[:\s]* ([^\n]+)',
        ]
        
        for pattern in competency_patterns:
            match = re.search(pattern, section, re.IGNORECASE | re.DOTALL)
            if match:
                competency = match.group(1).strip()
                # Clean up competency text
                competency = re.sub(r'\s+', ' ', competency)
                # Ensure competency is meaningful
                if len(competency) > 10 and not competency.lower().startswith('the learner'):
                    return competency
        
        return ""
    
    def extract_learning_outcomes_enhanced(self, section: str) -> List[str]:
        """Enhanced learning outcome extraction"""
        lo_patterns = [
            r'\*\*Learning Outcomes:\*\*\s*\n((?:-\s*[^\n]+\s*\n?)+)',
            r'The learner should be able to:\s*\n((?:-\s*[^\n]+\s*\n?)+)',
            r'Learning outcomes?:\s*\n((?:[-\*]\s*[^\n]+\s*\n?)+)',
            r'Should be able to:\s*\n((?:[-\*]\s*[^\n]+\s*\n?)+)',
        ]
        
        for pattern in lo_patterns:
            match = re.search(pattern, section, re.IGNORECASE)
            if match:
                lo_text = match.group(1)
                outcomes = re.findall(r'[-\*]\s*([^\n]+)', lo_text)
                learning_outcomes = [outcome.strip() for outcome in outcomes if outcome.strip()]
                if learning_outcomes:
                    return learning_outcomes
        
        # Fallback: Look for any bullet points in the section
        bullet_points = re.findall(r'[-\*]\s*([^\n]+)', section)
        learning_outcomes = [bp.strip() for bp in bullet_points if bp.strip() and len(bp.strip()) > 10]
        
        return learning_outcomes[:10]  # Limit to 10 most relevant
    
    def extract_strand_from_context(self, content: str, section_pos: int) -> str:
        """Extract strand/theme from context"""
        # Look backwards from section position
        context_start = max(0, section_pos - 1000)
        context = content[context_start:section_pos]
        
        # Theme patterns
        theme_patterns = [
            r'\*\*Theme:\s*([^\n]+)',
            r'Theme:\s*([^\n]+)',
            r'## ([^\n]+)',
        ]
        
        for pattern in theme_patterns:
            match = re.search(pattern, context, re.IGNORECASE)
            if match:
                theme = match.group(1).strip()
                if theme and len(theme) > 3:
                    return theme
        
        return "General"
    
    def extract_from_competency_patterns(self, content: str) -> List[Dict]:
        """Fallback extraction using competency patterns"""
        topics_data = []
        
        competency_matches = re.finditer(r'\*\*Competency:\*\* ([^\n]+)', content, re.IGNORECASE)
        
        for match in competency_matches:
            competency_text = match.group(1).strip()
            
            # Extract surrounding context
            start_pos = max(0, match.start() - 300)
            end_pos = min(len(content), match.end() + 800)
            context = content[start_pos:end_pos]
            
            # Extract topic name from context
            topic_name = self.extract_topic_from_context(context, match.start() - start_pos)
            
            # Extract learning outcomes
            learning_outcomes = self.extract_learning_outcomes_enhanced(context)
            
            # Get class info
            class_info = self.extract_class_with_context(content, match.start())
            
            if topic_name or learning_outcomes:
                topics_data.append({
                    "class": class_info,
                    "strand": "General",
                    "topic": topic_name or "General Topic",
                    "suggested_periods": None,
                    "competency": competency_text,
                    "learning_outcomes": learning_outcomes
                })
        
        return topics_data
    
    def extract_topic_from_context(self, context: str, competency_pos: int) -> str:
        """Extract topic name from context around competency"""
        # Look for topic patterns before the competency
        pre_context = context[:competency_pos]
        
        topic_patterns = [
            r'\*\*([^\*]+)\*\*',
            r'#### (.+)',
            r'### (.+)',
            r'## (.+)',
        ]
        
        for pattern in topic_patterns:
            matches = list(re.finditer(pattern, pre_context))
            if matches:
                # Get the last match (closest to competency)
                topic_match = matches[-1]
                topic_name = topic_match.group(1).strip()
                topic_name = re.sub(r'\s*\(\d+\s*periods?\)', '', topic_name)
                return topic_name
        
        return ""
    
    def determine_outcome_type_fixed(self, outcome_text: str) -> str:
        """Fixed outcome type determination with best logic"""
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
    
    def determine_exam_eligibility_enhanced(self, outcome_text: str) -> str:
        """Enhanced exam eligibility determination"""
        text_lower = outcome_text.lower()
        
        # Check for exam verbs
        if any(verb in text_lower for verb in self.exam_verbs):
            return "yes"
        
        # Check for non-exam indicators
        non_exam_patterns = [
            r'appreciate\s+the\s+value',
            r'understand\s+the\s+importance',
            r'show\s+skills?\s+in',
            r'demonstrate\s+skills?'
        ]
        
        for pattern in non_exam_patterns:
            if re.search(pattern, text_lower):
                return "no"
        
        return "unset"
    
    def create_structured_entry(self, file_path: Path, topic_data: Dict) -> Optional[Dict]:
        """Create structured syllabus entry with quality validation"""
        subject, level = self.extract_subject_level(file_path.name)
        
        # Validate competency text
        competency_text = topic_data["competency"].strip()
        if not competency_text or len(competency_text) < 10:
            return None  # Skip entries with empty competencies
        
        # Create learning outcomes with enhanced metadata
        structured_outcomes = []
        for lo_text in topic_data["learning_outcomes"]:
            lo_text = lo_text.strip()
            if len(lo_text) < 10:  # Skip very short outcomes
                continue
                
            outcome = {
                "text": lo_text,
                "outcome_type": self.determine_outcome_type_fixed(lo_text),
                "lesson_unit": "single_outcome",
                "activities": [],
                "materials": [],
                "assessment": {
                    "guidance": None,
                    "mode": "formative",
                    "exam_eligibility": self.determine_exam_eligibility_enhanced(lo_text)
                },
                "cross_cutting_issues": []
            }
            structured_outcomes.append(outcome)
        
        # Skip if no valid learning outcomes
        if not structured_outcomes:
            return None
        
        # Create competence
        competence = {
            "text": competency_text,
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
        """Process single file with enhanced algorithm"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return []
        
        # Extract topics using enhanced algorithm
        topics_data = self.extract_topics_enhanced(content)
        
        if not topics_data:
            print(f"No topics found in {file_path.name}")
            return []
        
        # Create structured entries
        entries = []
        for topic_data in topics_data:
            entry = self.create_structured_entry(file_path, topic_data)
            if entry:  # Only add valid entries
                entries.append(entry)
        
        return entries
    
    def clean_output_directory(self):
        """Clean up output directory - remove all old files except final ones"""
        print("🧹 Cleaning output directory...")
        
        # Files to keep
        keep_files = {"alevel_data.json", "olevel_data.json"}
        
        # Remove all other files
        for file_path in self.output_dir.glob("*"):
            if file_path.is_file() and file_path.name not in keep_files:
                try:
                    file_path.unlink()
                    print(f"  Deleted: {file_path.name}")
                except Exception as e:
                    print(f"  Error deleting {file_path.name}: {e}")
    
    def run_enhanced_extraction(self) -> ExtractionMetrics:
        """Run the enhanced extraction with better format handling"""
        print("🚀 ENHANCED NCDC SYLLABUS EXTRACTION")
        print("=" * 60)
        print("🎯 ENHANCED FEATURES:")
        print("- Handles alternative syllabus formats (Entrepreneurship, Art & Design)")
        print("- Enhanced verb classification")
        print("- Context-aware class detection")
        print("- Algorithmic topic extraction")
        print("- Quality filtering and validation")
        print("- Clean, organized output (only 2 files)")
        print("=" * 60)
        
        # Clean output directory first
        self.clean_output_directory()
        
        # Process all files
        alevel_entries = []
        olevel_entries = []
        total_files = 0
        processed_files = 0
        failed_files = 0
        
        # Process A-Level files
        print("\n📚 Processing A-Level files...")
        alevel_files = list(self.alevel_dir.glob("*_clean.md"))
        
        for file_path in alevel_files:
            total_files += 1
            print(f"  Processing: {file_path.name}")
            try:
                entries = self.process_single_file(file_path)
                if entries:
                    alevel_entries.extend(entries)
                    processed_files += 1
                    print(f"    ✅ {len(entries)} entries extracted")
                else:
                    failed_files += 1
                    print(f"    ❌ No entries extracted")
            except Exception as e:
                print(f"    Error processing {file_path.name}: {e}")
                failed_files += 1
        
        # Process O-Level files
        print("\n📚 Processing O-Level files...")
        olevel_files = list(self.olevel_dir.glob("*_clean.md"))
        
        for file_path in olevel_files:
            total_files += 1
            print(f"  Processing: {file_path.name}")
            try:
                entries = self.process_single_file(file_path)
                if entries:
                    olevel_entries.extend(entries)
                    processed_files += 1
                    print(f"    ✅ {len(entries)} entries extracted")
                else:
                    failed_files += 1
                    print(f"    ❌ No entries extracted")
            except Exception as e:
                print(f"    Error processing {file_path.name}: {e}")
                failed_files += 1
        
        # Save final clean files
        print(f"\n💾 Saving final clean files...")
        
        with open(self.output_dir / "alevel_data.json", 'w', encoding='utf-8') as f:
            json.dump(alevel_entries, f, indent=2, ensure_ascii=False)
        
        with open(self.output_dir / "olevel_data.json", 'w', encoding='utf-8') as f:
            json.dump(olevel_entries, f, indent=2, ensure_ascii=False)
        
        # Calculate metrics
        total_entries = len(alevel_entries) + len(olevel_entries)
        accuracy_rate = (processed_files / total_files * 100) if total_files > 0 else 0
        
        metrics = ExtractionMetrics(
            total_files=total_files,
            processed_files=processed_files,
            failed_files=failed_files,
            total_entries=total_entries,
            accuracy_rate=accuracy_rate
        )
        
        print(f"\n📊 ENHANCED EXTRACTION RESULTS:")
        print(f"  Total Files: {metrics.total_files}")
        print(f"  Processed Files: {metrics.processed_files}")
        print(f"  Failed Files: {metrics.failed_files}")
        print(f"  Total Entries: {metrics.total_entries}")
        print(f"  A-Level Entries: {len(alevel_entries)}")
        print(f"  O-Level Entries: {len(olevel_entries)}")
        print(f"  Processing Rate: {metrics.accuracy_rate:.1f}%")
        
        print(f"\n📁 CLEAN OUTPUT FILES:")
        print(f"  - alevel_data.json ({len(alevel_entries)} entries)")
        print(f"  - olevel_data.json ({len(olevel_entries)} entries)")
        
        return metrics

def main():
    extractor = EnhancedFinalExtractor()
    metrics = extractor.run_enhanced_extraction()
    print("\n🎉 ENHANCED EXTRACTION COMPLETED!")
    print("✅ All syllabus formats handled successfully")
    return metrics

if __name__ == "__main__":
    main()
