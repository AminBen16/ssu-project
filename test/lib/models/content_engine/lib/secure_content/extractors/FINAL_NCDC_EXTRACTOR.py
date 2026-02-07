#!/usr/bin/env python3
"""
FINAL NCDC SYLLABUS EXTRACTOR - Incremental Processing Edition
Optimized for incremental content generation while maintaining comprehensive data collection
Single source of truth with complete learning outcomes, competencies, and all data types
"""

import os
import json
import re
import hashlib
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple, Set
from dataclasses import dataclass, asdict
import shutil
from datetime import datetime

@dataclass
class ExtractionMetrics:
    total_files: int
    processed_files: int
    failed_files: int
    total_entries: int
    accuracy_rate: float
    incremental_updates: int
    processing_time: float

@dataclass
class FileMetadata:
    file_path: str
    file_hash: str
    last_modified: datetime
    processed: bool
    entry_count: int

@dataclass
class ProcessingCache:
    processed_files: Dict[str, FileMetadata]
    total_entries: int
    last_run: datetime

class FinalNCDCExtractor:
    def __init__(self, base_dir: str = "C:/Users/user/SSU"):
        self.base_dir = Path(base_dir)
        self.alevel_dir = self.base_dir / "cleaned_alevel_syllabi"
        self.olevel_dir = self.base_dir / "cleaned_olevel_syllabi"
        self.output_dir = self.base_dir / "syllabus_data_structure"
        self.cache_file = self.output_dir / ".processing_cache.json"
        self.output_dir.mkdir(exist_ok=True)
        
        # Load processing cache for incremental updates
        self.cache = self.load_cache()
        
        # COMPREHENSIVE VERB SETS for complete classification
        self.knowledge_verbs = {
            'understand', 'know', 'explain', 'describe', 'identify', 'state', 'list', 'name', 
            'recognize', 'recall', 'outline', 'summarize', 'classify', 'distinguish',
            'appreciate', 'comprehend', 'remember', 'select', 'indicate', 'specify', 
            'label', 'locate', 'match', 'define', 'explain', 'describe', 'enumerate',
            'mention', 'cite', 'quote', 'paraphrase', 'restate', 'clarify', 'interpret'
        }
        
        self.skill_verbs = {
            'apply', 'analyze', 'create', 'develop', 'demonstrate', 'design', 
            'implement', 'use', 'perform', 'show', 'carry out', 'conduct',
            'measure', 'calculate', 'solve', 'construct', 'produce', 'handle',
            'prepare', 'establish', 'grow', 'maintain', 'process', 'extract', 
            'interpret', 'organize', 'plan', 'practice', 'record', 'show',
            'demonstrate', 'identify', 'establish', 'grow', 'maintain', 'operate',
            'manipulate', 'assemble', 'disassemble', 'troubleshoot', 'repair',
            'install', 'configure', 'program', 'debug', 'test', 'evaluate'
        }
        
        self.value_verbs = {
            'evaluate', 'assess', 'compare', 'appreciate', 'respect', 'value', 
            'justify', 'critique', 'judge', 'recommend', 'prefer', 'choose',
            'accept', 'acknowledge', 'believe', 'commit', 'contribute', 'cooperate',
            'empathize', 'support', 'defend', 'advocate', 'endorse', 'reject'
        }
        
        self.exam_verbs = {
            'define', 'explain', 'describe', 'apply', 'analyze', 'evaluate',
            'identify', 'compare', 'contrast', 'discuss', 'demonstrate',
            'calculate', 'solve', 'create', 'design', 'develop', 'assess',
            'justify', 'critique', 'interpret', 'examine', 'illustrate'
        }
    
    def load_cache(self) -> ProcessingCache:
        """Load processing cache for incremental updates"""
        try:
            if self.cache_file.exists():
                with open(self.cache_file, 'r', encoding='utf-8') as f:
                    cache_data = json.load(f)
                
                # Convert string timestamps back to datetime objects
                processed_files = {}
                for file_path, metadata in cache_data.get('processed_files', {}).items():
                    processed_files[file_path] = FileMetadata(
                        file_path=metadata['file_path'],
                        file_hash=metadata['file_hash'],
                        last_modified=datetime.fromisoformat(metadata['last_modified']),
                        processed=metadata['processed'],
                        entry_count=metadata['entry_count']
                    )
                
                return ProcessingCache(
                    processed_files=processed_files,
                    total_entries=cache_data.get('total_entries', 0),
                    last_run=datetime.fromisoformat(cache_data.get('last_run', datetime.now().isoformat()))
                )
        except Exception as e:
            print(f"⚠️  Could not load cache: {e}")
        
        # Return empty cache if loading fails
        return ProcessingCache(
            processed_files={},
            total_entries=0,
            last_run=datetime.now()
        )
    
    def save_cache(self):
        """Save processing cache for future incremental updates"""
        try:
            cache_data = {
                'processed_files': {},
                'total_entries': self.cache.total_entries,
                'last_run': self.cache.last_run.isoformat()
            }
            
            # Convert datetime objects to strings for JSON serialization
            for file_path, metadata in self.cache.processed_files.items():
                cache_data['processed_files'][file_path] = {
                    'file_path': metadata.file_path,
                    'file_hash': metadata.file_hash,
                    'last_modified': metadata.last_modified.isoformat(),
                    'processed': metadata.processed,
                    'entry_count': metadata.entry_count
                }
            
            with open(self.cache_file, 'w', encoding='utf-8') as f:
                json.dump(cache_data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"⚠️  Could not save cache: {e}")
    
    def get_file_hash(self, file_path: Path) -> str:
        """Calculate MD5 hash of file content for change detection"""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except Exception:
            return ""
    
    def should_process_file(self, file_path: Path) -> bool:
        """Determine if file needs processing (incremental logic)"""
        file_key = str(file_path)
        
        # Check if file exists in cache
        if file_key not in self.cache.processed_files:
            return True  # New file
        
        cached_metadata = self.cache.processed_files[file_key]
        
        # Check if file was modified
        try:
            current_mtime = datetime.fromtimestamp(file_path.stat().st_mtime)
            if current_mtime > cached_metadata.last_modified:
                return True  # File was modified
        except Exception:
            return True  # Safety: process if we can't check
        
        # Check if file content changed (hash comparison)
        current_hash = self.get_file_hash(file_path)
        if current_hash != cached_metadata.file_hash:
            return True  # Content changed
        
        return False  # No changes detected
    
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
    
    def extract_topics_algorithmic(self, content: str) -> List[Dict]:
        """Algorithmic topic extraction with maximum recall"""
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
    
    def extract_competency_from_section(self, section: str) -> str:
        """Extract competency with comprehensive patterns - SINGLE SOURCE OF TRUTH"""
        competency_patterns = [
            r'\*\*Competency:\*\* ([^\n]+)',
            r'\*\*Competence:\*\* ([^\n]+)',
            r'Competency[:\s]* ([^\n]+)',
            r'Competence[:\s]* ([^\n]+)',
            r'The learner ([^\n]+?)(?:should be able to|$)',
            r'Learners? (?:will be able to|should be able to) ([^\n]+)',
            r'By the end of this topic, learners? (?:will be able to|should be able to) ([^\n]+)',
        ]
        
        for pattern in competency_patterns:
            match = re.search(pattern, section, re.IGNORECASE | re.DOTALL)
            if match:
                competency = match.group(1).strip()
                # Clean up competency text but preserve full meaning
                competency = re.sub(r'\s+', ' ', competency)
                # Ensure competency is meaningful and complete
                if len(competency) > 10 and not competency.lower().startswith('the learner'):
                    return competency
        
        # Fallback: Extract from first meaningful sentence
        sentences = re.split(r'[.!?]+', section)
        for sentence in sentences:
            sentence = sentence.strip()
            if len(sentence) > 15 and any(verb in sentence.lower() for verb in ['able to', 'understand', 'apply', 'analyze']):
                return sentence
        
        return ""
    
    def extract_learning_outcomes_enhanced(self, section: str) -> List[str]:
        """Enhanced learning outcome extraction - COMPREHENSIVE COLLECTION"""
        lo_patterns = [
            r'\*\*Learning Outcomes?:\*\*\s*\n((?:[-\*•]\s*[^\n]+\s*\n?)+)',
            r'The learner should be able to:\s*\n((?:[-\*•]\s*[^\n]+\s*\n?)+)',
            r'Learning outcomes?:\s*\n((?:[-\*•]\s*[^\n]+\s*\n?)+)',
            r'Should be able to:\s*\n((?:[-\*•]\s*[^\n]+\s*\n?)+)',
            r'By the end of this (?:topic|lesson|unit), (?:the )?learner (?:will be|should be) able to:\s*\n((?:[-\*•]\s*[^\n]+\s*\n?)+)',
            r'(?:At the end|Upon completion) of this (?:topic|lesson|unit), (?:the )?learner (?:will be|should be) able to:\s*\n((?:[-\*•]\s*[^\n]+\s*\n?)+)',
        ]
        
        # Try structured patterns first
        for pattern in lo_patterns:
            match = re.search(pattern, section, re.IGNORECASE)
            if match:
                lo_text = match.group(1)
                outcomes = re.findall(r'[-\*•]\s*([^\n]+)', lo_text)
                learning_outcomes = [outcome.strip() for outcome in outcomes if outcome.strip() and len(outcome.strip()) > 10]
                if learning_outcomes:
                    return learning_outcomes
        
        # Fallback: Extract from numbered lists
        numbered_pattern = r'\d+\.\s*([^\n]+)'
        numbered_outcomes = re.findall(numbered_pattern, section)
        if numbered_outcomes:
            return [outcome.strip() for outcome in numbered_outcomes if len(outcome.strip()) > 10]
        
        # Fallback: Look for any bullet points with action verbs
        bullet_points = re.findall(r'[-\*•]\s*([^\n]+)', section)
        learning_outcomes = []
        for bp in bullet_points:
            bp_clean = bp.strip()
            if len(bp_clean) > 10 and any(verb in bp_clean.lower() for verb in self.skill_verbs | self.knowledge_verbs | self.value_verbs):
                learning_outcomes.append(bp_clean)
        
        return learning_outcomes[:15]  # Increased limit for comprehensive collection
    
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
        """Create comprehensive structured syllabus entry - SINGLE SOURCE OF TRUTH"""
        subject, level = self.extract_subject_level(file_path.name)
        
        # Validate and clean competency text
        competency_text = topic_data["competency"].strip()
        if not competency_text or len(competency_text) < 10:
            return None  # Skip entries with empty competencies
        
        # Create comprehensive learning outcomes with full metadata
        structured_outcomes = []
        for lo_text in topic_data["learning_outcomes"]:
            lo_text = lo_text.strip()
            if len(lo_text) < 10:  # Skip very short outcomes
                continue
                
            # Comprehensive outcome classification
            outcome_type = self.determine_outcome_type_fixed(lo_text)
            exam_eligibility = self.determine_exam_eligibility_enhanced(lo_text)
            
            # Extract additional metadata from outcome text
            suggested_activities = self.extract_activities_from_outcome(lo_text)
            teaching_materials = self.extract_materials_from_outcome(lo_text)
            cross_cutting = self.extract_cross_cutting_issues(lo_text)
            
            outcome = {
                "text": lo_text,
                "outcome_type": outcome_type,
                "lesson_unit": "single_outcome",
                "activities": suggested_activities,
                "materials": teaching_materials,
                "assessment": {
                    "guidance": self.extract_assessment_guidance(lo_text),
                    "mode": "formative" if exam_eligibility == "no" else "summative",
                    "exam_eligibility": exam_eligibility,
                    "weighting": None,
                    "method": self.extract_assessment_method(lo_text)
                },
                "cross_cutting_issues": cross_cutting,
                "generic_skills": self.extract_generic_skills(lo_text),
                "ict_integration": self.extract_ict_integration(lo_text),
                "teaching_strategies": self.extract_teaching_strategies(lo_text)
            }
            structured_outcomes.append(outcome)
        
        # Skip if no valid learning outcomes
        if not structured_outcomes:
            return None
        
        # Create comprehensive competence object
        competence = {
            "text": competency_text,
            "competency_type": self.determine_competency_type(competency_text),
            "learning_outcomes": structured_outcomes,
            "assessment_criteria": self.extract_assessment_criteria(competency_text),
            "key_concepts": self.extract_key_concepts(topic_data.get("topic", "")),
            "prerequisite_skills": self.extract_prerequisites(topic_data.get("topic", ""))
        }
        
        # Create comprehensive main entry
        entry = {
            "subject": subject,
            "level": level,
            "class": topic_data["class"],
            "strand": topic_data["strand"],
            "sub_strand": topic_data.get("sub_strand"),
            "topic": topic_data["topic"],
            "topic_code": self.generate_topic_code(subject, topic_data["topic"]),
            "suggested_periods": topic_data.get("suggested_periods"),
            "teaching_time": self.calculate_teaching_time(topic_data.get("suggested_periods")),
            "competences": [competence],
            "content_summary": self.extract_content_summary(topic_data),
            "learning_resources": self.extract_learning_resources(topic_data),
            "assessment_methods": self.extract_topic_assessment_methods(topic_data),
            "differentiation_strategies": self.extract_differentiation_strategies(topic_data),
            "integration_points": self.extract_integration_points(topic_data)
        }
        
        return entry
    
    def extract_activities_from_outcome(self, outcome_text: str) -> List[str]:
        """Extract suggested teaching/learning activities from outcome text"""
        activity_patterns = [
            r'(?:participate in|engage in|take part in|conduct|carry out|perform) ([^\n]+)',
            r'(?:discuss|debate|analyze|investigate|explore) ([^\n]+)',
            r'(?:create|design|develop|construct|build) ([^\n]+)'
        ]
        
        activities = []
        for pattern in activity_patterns:
            matches = re.findall(pattern, outcome_text, re.IGNORECASE)
            activities.extend(matches)
        
        return list(set(activities))  # Remove duplicates
    
    def extract_materials_from_outcome(self, outcome_text: str) -> List[str]:
        """Extract teaching materials mentioned in outcome text"""
        material_patterns = [
            r'(?:using|with|by means of) ([^\n]+)',
            r'(?:through|via) ([^\n]+)',
            r'([^\n]+ (?:materials|resources|tools|equipment))'
        ]
        
        materials = []
        for pattern in material_patterns:
            matches = re.findall(pattern, outcome_text, re.IGNORECASE)
            materials.extend(matches)
        
        return list(set(materials))
    
    def extract_cross_cutting_issues(self, outcome_text: str) -> List[str]:
        """Extract cross-cutting issues from outcome text"""
        cross_cutting_keywords = [
            'gender', 'environment', 'human rights', 'peace', 'conflict resolution',
            'health', 'nutrition', 'hiv/aids', 'disability', 'inclusion', 'sustainability',
            'climate change', 'cultural diversity', 'social justice', 'civic responsibility'
        ]
        
        found_issues = []
        text_lower = outcome_text.lower()
        
        for keyword in cross_cutting_keywords:
            if keyword in text_lower:
                found_issues.append(keyword.title())
        
        return found_issues
    
    def extract_generic_skills(self, outcome_text: str) -> List[str]:
        """Extract generic skills from outcome text"""
        generic_skills = [
            'critical thinking', 'problem solving', 'communication', 'collaboration',
            'creativity', 'innovation', 'digital literacy', 'information literacy',
            'self-management', 'leadership', 'teamwork', 'decision making'
        ]
        
        found_skills = []
        text_lower = outcome_text.lower()
        
        for skill in generic_skills:
            if skill in text_lower:
                found_skills.append(skill.title())
        
        return found_skills
    
    def extract_ict_integration(self, outcome_text: str) -> List[str]:
        """Extract ICT integration points from outcome text"""
        ict_keywords = [
            'computer', 'internet', 'software', 'digital', 'online', 'multimedia',
            'simulation', 'database', 'spreadsheet', 'presentation', 'website',
            'email', 'social media', 'mobile', 'tablet', 'app', 'technology'
        ]
        
        found_ict = []
        text_lower = outcome_text.lower()
        
        for keyword in ict_keywords:
            if keyword in text_lower:
                found_ict.append(keyword.title())
        
        return found_ict
    
    def extract_teaching_strategies(self, outcome_text: str) -> List[str]:
        """Extract teaching strategies from outcome text"""
        strategy_keywords = [
            'group work', 'pair work', 'discussion', 'demonstration', 'experiment',
            'project', 'presentation', 'research', 'investigation', 'role play',
            'debate', 'case study', 'problem-based learning', 'inquiry-based'
        ]
        
        found_strategies = []
        text_lower = outcome_text.lower()
        
        for strategy in strategy_keywords:
            if strategy in text_lower:
                found_strategies.append(strategy.title())
        
        return found_strategies
    
    def extract_assessment_guidance(self, outcome_text: str) -> Optional[str]:
        """Extract assessment guidance from outcome text"""
        guidance_patterns = [
            r'(?:assess|evaluate) (?:by|through|using) ([^\n]+)',
            r'(?:evidence|criteria) (?:of|for) ([^\n]+)',
            r'(?:measure|determine) ([^\n]+)'
        ]
        
        for pattern in guidance_patterns:
            match = re.search(pattern, outcome_text, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        
        return None
    
    def extract_assessment_method(self, outcome_text: str) -> Optional[str]:
        """Extract assessment method from outcome text"""
        method_keywords = {
            'written': ['test', 'exam', 'quiz', 'written', 'essay'],
            'oral': ['presentation', 'oral', 'speech', 'discussion'],
            'practical': ['demonstration', 'practical', 'performance', 'experiment'],
            'project': ['project', 'portfolio', 'assignment'],
            'observation': ['observation', 'monitoring', 'checklist']
        }
        
        text_lower = outcome_text.lower()
        
        for method, keywords in method_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                return method
        
        return None
    
    def determine_competency_type(self, competency_text: str) -> str:
        """Determine competency type (core, supplementary, etc.)"""
        text_lower = competency_text.lower()
        
        if any(word in text_lower for word in ['core', 'essential', 'fundamental', 'basic']):
            return "core"
        elif any(word in text_lower for word in ['supplementary', 'additional', 'extended']):
            return "supplementary"
        elif any(word in text_lower for word in ['advanced', 'higher', 'complex']):
            return "advanced"
        else:
            return "general"
    
    def extract_assessment_criteria(self, competency_text: str) -> List[str]:
        """Extract assessment criteria from competency text"""
        criteria_patterns = [
            r'(?:criteria|standard|benchmark) (?:of|for|is|are) ([^\n]+)',
            r'(?:measure|assess|evaluate) (?:by|through) ([^\n]+)'
        ]
        
        criteria = []
        for pattern in criteria_patterns:
            matches = re.findall(pattern, competency_text, re.IGNORECASE)
            criteria.extend(matches)
        
        return criteria
    
    def extract_key_concepts(self, topic: str) -> List[str]:
        """Extract key concepts from topic name"""
        # This is a simplified version - could be enhanced with concept mapping
        concepts = []
        
        # Extract technical terms (capitalized words, acronyms)
        technical_terms = re.findall(r'\b[A-Z]{2,}\b|\b[A-Z][a-z]+(?:[A-Z][a-z]+)*\b', topic)
        concepts.extend(technical_terms)
        
        return list(set(concepts))
    
    def extract_prerequisites(self, topic: str) -> List[str]:
        """Extract prerequisite skills from topic (simplified)"""
        # This could be enhanced with prerequisite mapping
        return []
    
    def generate_topic_code(self, subject: str, topic: str) -> str:
        """Generate unique topic code"""
        subject_code = re.sub(r'[^a-zA-Z0-9]', '', subject.upper())[:3]
        topic_code = re.sub(r'[^a-zA-Z0-9]', '', topic.upper())[:6]
        return f"{subject_code}{topic_code}"
    
    def calculate_teaching_time(self, periods: Optional[int]) -> Optional[Dict]:
        """Calculate teaching time details"""
        if not periods:
            return None
        
        return {
            "periods": periods,
            "minutes": periods * 40,  # Assuming 40-minute periods
            "hours": round(periods * 40 / 60, 1)
        }
    
    def extract_content_summary(self, topic_data: Dict) -> Optional[str]:
        """Extract content summary from topic data"""
        # This could be enhanced with content summarization
        return None
    
    def extract_learning_resources(self, topic_data: Dict) -> List[str]:
        """Extract learning resources from topic data"""
        # This could be enhanced with resource extraction
        return []
    
    def extract_topic_assessment_methods(self, topic_data: Dict) -> List[str]:
        """Extract assessment methods for the topic"""
        return ["formative", "summative"]
    
    def extract_differentiation_strategies(self, topic_data: Dict) -> List[str]:
        """Extract differentiation strategies"""
        return ["individualized instruction", "group work", "peer tutoring"]
    
    def extract_integration_points(self, topic_data: Dict) -> List[str]:
        """Extract integration points with other subjects"""
        return []
    
    def process_single_file(self, file_path: Path) -> List[Dict]:
        """Process single file with comprehensive extraction and caching"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return []
        
        # Extract topics using algorithmic approach
        topics_data = self.extract_topics_algorithmic(content)
        
        if not topics_data:
            print(f"No topics found in {file_path.name}")
            return []
        
        # Create structured entries
        entries = []
        for topic_data in topics_data:
            entry = self.create_structured_entry(file_path, topic_data)
            if entry:  # Only add valid entries
                entries.append(entry)
        
        # Update cache with file metadata
        file_hash = self.get_file_hash(file_path)
        file_mtime = datetime.fromtimestamp(file_path.stat().st_mtime)
        
        self.cache.processed_files[str(file_path)] = FileMetadata(
            file_path=str(file_path),
            file_hash=file_hash,
            last_modified=file_mtime,
            processed=True,
            entry_count=len(entries)
        )
        
        return entries
    
    def load_existing_data(self) -> Tuple[List[Dict], List[Dict]]:
        """Load existing data files for incremental updates"""
        alevel_entries = []
        olevel_entries = []
        
        try:
            # Load A-Level data
            alevel_file = self.output_dir / "alevel_data.json"
            if alevel_file.exists():
                with open(alevel_file, 'r', encoding='utf-8') as f:
                    alevel_entries = json.load(f)
        except Exception as e:
            print(f"⚠️  Could not load existing A-Level data: {e}")
        
        try:
            # Load O-Level data
            olevel_file = self.output_dir / "olevel_data.json"
            if olevel_file.exists():
                with open(olevel_file, 'r', encoding='utf-8') as f:
                    olevel_entries = json.load(f)
        except Exception as e:
            print(f"⚠️  Could not load existing O-Level data: {e}")
        
        return alevel_entries, olevel_entries
    
    def remove_file_entries(self, entries: List[Dict], file_path: Path) -> List[Dict]:
        """Remove entries for a specific file (for reprocessing)"""
        subject, level = self.extract_subject_level(file_path.name)
        
        filtered_entries = []
        for entry in entries:
            # Keep entries that don't match the file being reprocessed
            if entry.get("subject") != subject or entry.get("level") != level:
                filtered_entries.append(entry)
        
        return filtered_entries
    
    def run_incremental_extraction(self) -> ExtractionMetrics:
        """Run incremental extraction with comprehensive data collection"""
        start_time = datetime.now()
        
        print("🚀 INCREMENTAL NCDC SYLLABUS EXTRACTION")
        print("=" * 60)
        print("🎯 COMPREHENSIVE FEATURES:")
        print("- Incremental processing (only changed files)")
        print("- Complete learning outcomes collection")
        print("- Comprehensive competency extraction")
        print("- Single source of truth data structure")
        print("- Full metadata and cross-cutting issues")
        print("=" * 60)
        
        # Load existing data
        alevel_entries, olevel_entries = self.load_existing_data()
        print(f"📂 Loaded existing data: {len(alevel_entries)} A-Level, {len(olevel_entries)} O-Level entries")
        
        # Process files incrementally
        total_files = 0
        processed_files = 0
        failed_files = 0
        incremental_updates = 0
        
        # Process A-Level files
        print("\n📚 Processing A-Level files incrementally...")
        alevel_files = list(self.alevel_dir.glob("*_clean.md"))
        
        for file_path in alevel_files:
            total_files += 1
            
            if self.should_process_file(file_path):
                print(f"  🔄 Processing: {file_path.name}")
                incremental_updates += 1
                
                # Remove existing entries for this file
                alevel_entries = self.remove_file_entries(alevel_entries, file_path)
                
                try:
                    entries = self.process_single_file(file_path)
                    if entries:
                        alevel_entries.extend(entries)
                        processed_files += 1
                        print(f"    ✅ Added {len(entries)} entries")
                    else:
                        failed_files += 1
                        print(f"    ❌ No entries extracted")
                except Exception as e:
                    print(f"    ❌ Error: {e}")
                    failed_files += 1
            else:
                print(f"  ⏭️  Skipped (unchanged): {file_path.name}")
        
        # Process O-Level files
        print("\n📚 Processing O-Level files incrementally...")
        olevel_files = list(self.olevel_dir.glob("*_clean.md"))
        
        for file_path in olevel_files:
            total_files += 1
            
            if self.should_process_file(file_path):
                print(f"  🔄 Processing: {file_path.name}")
                incremental_updates += 1
                
                # Remove existing entries for this file
                olevel_entries = self.remove_file_entries(olevel_entries, file_path)
                
                try:
                    entries = self.process_single_file(file_path)
                    if entries:
                        olevel_entries.extend(entries)
                        processed_files += 1
                        print(f"    ✅ Added {len(entries)} entries")
                    else:
                        failed_files += 1
                        print(f"    ❌ No entries extracted")
                except Exception as e:
                    print(f"    ❌ Error: {e}")
                    failed_files += 1
            else:
                print(f"  ⏭️  Skipped (unchanged): {file_path.name}")
        
        # Save updated files
        print(f"\n💾 Saving comprehensive data files...")
        
        with open(self.output_dir / "alevel_data.json", 'w', encoding='utf-8') as f:
            json.dump(alevel_entries, f, indent=2, ensure_ascii=False)
        
        with open(self.output_dir / "olevel_data.json", 'w', encoding='utf-8') as f:
            json.dump(olevel_entries, f, indent=2, ensure_ascii=False)
        
        # Clean up intermediate files and keep only final copies
        self.clean_output_directory()
        
        # Verify final outputs
        verification_results = self.verify_final_outputs()
        
        # Update cache
        self.cache.total_entries = len(alevel_entries) + len(olevel_entries)
        self.cache.last_run = datetime.now()
        self.save_cache()
        
        # Calculate metrics
        end_time = datetime.now()
        processing_time = (end_time - start_time).total_seconds()
        total_entries = len(alevel_entries) + len(olevel_entries)
        accuracy_rate = (processed_files / total_files * 100) if total_files > 0 else 0
        
        metrics = ExtractionMetrics(
            total_files=total_files,
            processed_files=processed_files,
            failed_files=failed_files,
            total_entries=total_entries,
            accuracy_rate=accuracy_rate,
            incremental_updates=incremental_updates,
            processing_time=processing_time
        )
        
        print(f"\n📊 INCREMENTAL EXTRACTION RESULTS:")
        print(f"  Total Files: {metrics.total_files}")
        print(f"  Files Processed: {metrics.processed_files}")
        print(f"  Incremental Updates: {metrics.incremental_updates}")
        print(f"  Failed Files: {metrics.failed_files}")
        print(f"  Total Entries: {metrics.total_entries}")
        print(f"  A-Level Entries: {len(alevel_entries)}")
        print(f"  O-Level Entries: {len(olevel_entries)}")
        print(f"  Processing Rate: {metrics.accuracy_rate:.1f}%")
        print(f"  Processing Time: {metrics.processing_time:.1f}s")
        
        print(f"\n📁 FINAL CLEAN OUTPUT FILES:")
        print(f"  - alevel_data.json ({len(alevel_entries)} entries)")
        print(f"  - olevel_data.json ({len(olevel_entries)} entries)")
        print(f"  - .processing_cache.json (incremental tracking)")
        print(f"  ✅ All intermediate files removed - only final copies kept")
        
        return metrics
    
    def clean_output_directory(self):
        """Clean up output directory - keep only final essential files"""
        print("🧹 Cleaning output directory - keeping only final files...")
        
        # Essential files to keep
        essential_files = {
            "alevel_data.json",
            "olevel_data.json", 
            ".processing_cache.json"
        }
        
        # Files to remove (intermediate/temporary files)
        patterns_to_remove = [
            "*_temp.json",
            "*_backup.json", 
            "*_old.json",
            "*_partial.json",
            "temp_*",
            "backup_*",
            "*_test.json",
            "*_debug.json"
        ]
        
        removed_count = 0
        
        # Remove files matching patterns
        for pattern in patterns_to_remove:
            for file_path in self.output_dir.glob(pattern):
                if file_path.is_file() and file_path.name not in essential_files:
                    try:
                        file_path.unlink()
                        removed_count += 1
                        print(f"  🗑️  Removed: {file_path.name}")
                    except Exception as e:
                        print(f"  ⚠️  Could not remove {file_path.name}: {e}")
        
        # Remove any other non-essential JSON files
        for file_path in self.output_dir.glob("*.json"):
            if file_path.is_file() and file_path.name not in essential_files:
                try:
                    file_path.unlink()
                    removed_count += 1
                    print(f"  🗑️  Removed: {file_path.name}")
                except Exception as e:
                    print(f"  ⚠️  Could not remove {file_path.name}: {e}")
        
        print(f"  ✅ Cleanup complete: {removed_count} files removed")
        print(f"  📁 Essential files retained: {list(essential_files)}")
    
    def verify_final_outputs(self):
        """Verify that final output files exist and are valid"""
        print("🔍 Verifying final output files...")
        
        required_files = {
            "alevel_data.json": "A-Level syllabus data",
            "olevel_data.json": "O-Level syllabus data"
        }
        
        verification_results = {}
        
        for filename, description in required_files.items():
            file_path = self.output_dir / filename
            
            if file_path.exists():
                try:
                    # Check file size
                    file_size = file_path.stat().st_size
                    
                    # Try to load and validate JSON
                    with open(file_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    
                    entry_count = len(data) if isinstance(data, list) else 0
                    
                    verification_results[filename] = {
                        "exists": True,
                        "valid_json": True,
                        "size_bytes": file_size,
                        "entry_count": entry_count,
                        "description": description,
                        "status": "✅ Valid"
                    }
                    
                    print(f"  ✅ {filename}: {entry_count} entries ({file_size:,} bytes)")
                    
                except Exception as e:
                    verification_results[filename] = {
                        "exists": True,
                        "valid_json": False,
                        "error": str(e),
                        "description": description,
                        "status": "❌ Invalid"
                    }
                    
                    print(f"  ❌ {filename}: Invalid JSON - {e}")
            else:
                verification_results[filename] = {
                    "exists": False,
                    "description": description,
                    "status": "❌ Missing"
                }
                
                print(f"  ❌ {filename}: File missing")
        
        # Check cache file
        cache_file = self.output_dir / ".processing_cache.json"
        if cache_file.exists():
            print(f"  ✅ .processing_cache.json: Cache file present")
        else:
            print(f"  ⚠️  .processing_cache.json: Cache file missing")
        
        return verification_results
    
    def run_final_extraction(self) -> ExtractionMetrics:
        """Run the final extraction with clean output"""
        print("🚀 FINAL NCDC SYLLABUS EXTRACTION")
        print("=" * 60)
        print("🎯 BEST FEATURES COMBINED:")
        print("- Enhanced verb classification (from fix_outcome_types.py)")
        print("- Context-aware class detection (from improved_extractor.py)")
        print("- Algorithmic topic extraction (from final_optimized_extractor.py)")
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
                else:
                    failed_files += 1
            except Exception as e:
                print(f"  Error processing {file_path.name}: {e}")
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
                else:
                    failed_files += 1
            except Exception as e:
                print(f"  Error processing {file_path.name}: {e}")
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
        
        print(f"\n📊 FINAL EXTRACTION RESULTS:")
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

def main_cleanup_only():
    """Standalone cleanup - remove intermediate files, keep only final copies"""
    extractor = FinalNCDCExtractor()
    
    print("🧹 STANDALONE CLEANUP MODE")
    print("=" * 40)
    print("Removing intermediate files...")
    print("Keeping only final essential files...")
    
    extractor.clean_output_directory()
    extractor.verify_final_outputs()
    
    print("\n✅ Cleanup complete!")
    print("📁 Only final file copies remain in output directory")

def main():
    """Main entry point - runs incremental extraction"""
    extractor = FinalNCDCExtractor()
    
    print("🎯 FINAL NCDC EXTRACTOR - INCREMENTAL EDITION")
    print("=" * 50)
    print("Choose processing mode:")
    print("1. Incremental (recommended - only changed files)")
    print("2. Full rebuild (process all files)")
    print("3. Force clean rebuild (delete cache and rebuild)")
    print("4. Cleanup only (remove intermediate files)")
    
    try:
        choice = input("\nEnter choice (1-4): ").strip()
    except KeyboardInterrupt:
        print("\n👋 Extraction cancelled by user")
        return
    
    if choice == "4":
        print("\n🧹 Cleanup only mode...")
        main_cleanup_only()
        return
    elif choice == "3":
        print("\n🧹 Force clean rebuild - deleting cache...")
        if extractor.cache_file.exists():
            extractor.cache_file.unlink()
        extractor.cache = extractor.load_cache()
        print("✅ Cache cleared")
        choice = "2"  # Fall back to full rebuild
    
    if choice == "2":
        print("\n🔄 Full rebuild - processing all files...")
        if extractor.cache_file.exists():
            extractor.cache_file.unlink()
        extractor.cache = extractor.load_cache()
        metrics = extractor.run_incremental_extraction()
    elif choice == "1":
        print("\n⚡ Incremental processing - only changed files...")
        metrics = extractor.run_incremental_extraction()
    else:
        print("❌ Invalid choice. Running incremental processing...")
        metrics = extractor.run_incremental_extraction()
    
    print("\n🎉 EXTRACTION COMPLETED!")
    print("✅ Comprehensive data ready for production use")
    print(f"📊 Processed {metrics.processed_files}/{metrics.total_files} files")
    print(f"⚡ {metrics.incremental_updates} files updated incrementally")
    print(f"📈 Total entries: {metrics.total_entries}")
    print(f"⏱️  Processing time: {metrics.processing_time:.1f}s")
    print(f"🧹 Output directory cleaned - only final files kept")
    
    return metrics

def main_incremental():
    """Direct incremental processing (no menu)"""
    extractor = FinalNCDCExtractor()
    metrics = extractor.run_incremental_extraction()
    return metrics

def main_full():
    """Direct full processing (no menu)"""
    extractor = FinalNCDCExtractor()
    if extractor.cache_file.exists():
        extractor.cache_file.unlink()
    extractor.cache = extractor.load_cache()
    metrics = extractor.run_incremental_extraction()
    return metrics

if __name__ == "__main__":
    main()
