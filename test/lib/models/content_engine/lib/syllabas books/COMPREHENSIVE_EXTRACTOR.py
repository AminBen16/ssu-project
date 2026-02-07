#!/usr/bin/env python3
"""
COMPREHENSIVE NCDC EXTRACTOR - Extracts ALL content including activities, materials, and guidance
Makes the app truly automatic by extracting complete lesson content
"""

import os
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass

@dataclass
class ExtractionMetrics:
    total_files: int
    processed_files: int
    failed_files: int
    total_entries: int
    activities_extracted: int
    materials_extracted: int
    guidance_extracted: int

class ComprehensiveExtractor:
    def __init__(self, base_dir: str = "C:/Users/user/SSU"):
        self.base_dir = Path(base_dir)
        self.alevel_dir = self.base_dir / "cleaned_alevel_syllabi"
        self.olevel_dir = self.base_dir / "cleaned_olevel_syllabi"
        self.output_dir = self.base_dir / "syllabus_data_structure"
        self.output_dir.mkdir(exist_ok=True)
        
        # Enhanced verb sets
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
        
        # Activity and material patterns
        self.activity_patterns = [
            r'(show|demonstrate|apply|perform|carry out|conduct|implement|use|create|design|develop)\s+skills?\s+in\s+([^.]+)',
            r'(show|demonstrate|apply|perform)\s+([^,.]+?)\s+skills?',
            r'(design|create|develop|plan|establish)\s+([^,.]+)',
            r'(apply|use|implement)\s+([^,.]+?)\s+principles?',
            r'(carry out|conduct|perform)\s+([^,.]+)',
        ]
        
        self.material_patterns = [
            r'(tools?|equipment|implements?|materials?|resources|supplies)',
            r'(measurement\s+tools?|farm\s+tools?|garden\s+tools?|wood\s+working\s+tools?)',
            r'(seedlings?|seeds?|fertilizer|pesticides?|herbicides?)',
            r'(soil|water|feed|nutrients|organic\s+matter)',
            r'(paper|pen|pencil|notebook|computer|calculator)',
        ]
        
        self.guidance_patterns = [
            r'(assess|evaluate|judge|critique|compare|contrast)',
            r'(cupping|tasting|testing|measuring|analyzing)',
            r'(demonstrate|show|perform|display)',
            r'(explain|describe|identify|classify)',
        ]
    
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
        context_start = max(0, section_start - 2000)
        context = content[context_start:section_start + 500]
        
        class_patterns = [
            r'### (SENIOR [1-6])\s*\n',
            r'### (Senior [1-6|Five|Six])\s*\n',
            r'## (SENIOR [1-6])\s*\n',
            r'## (Senior [1-6|Five|Six])\s*\n',
            r'(SENIOR [1-6])\s*\(',
            r'(Senior [1-6|Five|Six])\s*\(',
        ]
        
        best_match = None
        best_distance = float('inf')
        
        for pattern in class_patterns:
            matches = list(re.finditer(pattern, context, re.IGNORECASE))
            for match in matches:
                distance = abs(section_start - (context_start + match.start()))
                if distance < best_distance:
                    best_distance = distance
                    best_match = match
        
        if best_match:
            class_name = best_match.group(1).strip()
            return self.normalize_class_name(class_name)
        
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
        
        if class_name in ["S5", "S6"]:
            return f"SENIOR {class_name[1]}"
        elif class_name in ["S1", "S2", "S3", "S4"]:
            return f"SENIOR {class_name[1]}"
        
        return class_name
    
    def extract_comprehensive_content(self, learning_outcome_text: str) -> Dict[str, Any]:
        """Extract activities, materials, and guidance from learning outcome text"""
        activities = []
        materials = []
        guidance = None
        
        text_lower = learning_outcome_text.lower()
        
        # Extract activities
        for pattern in self.activity_patterns:
            matches = re.finditer(pattern, learning_outcome_text, re.IGNORECASE)
            for match in matches:
                activity = match.group(0).strip()
                if len(activity) > 10:
                    activities.append(activity)
        
        # Extract materials mentioned
        for pattern in self.material_patterns:
            matches = re.finditer(pattern, text_lower)
            for match in matches:
                material = match.group(1).strip()
                if material and material not in materials:
                    materials.append(material)
        
        # Extract assessment guidance
        for pattern in self.guidance_patterns:
            matches = re.finditer(pattern, text_lower)
            for match in matches:
                if not guidance:
                    guidance = f"Students should be able to {match.group(1)} the demonstrated skills"
                    break
        
        # Additional context-based extraction
        if "financial management" in text_lower:
            activities.append("Apply financial management principles")
            materials.extend(["calculator", "financial records", "budget sheets"])
        
        if "safety" in text_lower or "health" in text_lower:
            activities.append("Demonstrate safety procedures")
            materials.extend(["safety equipment", "protective gear", "first aid kit"])
        
        if "measurement" in text_lower:
            activities.append("Perform measurements using appropriate tools")
            materials.extend(["measuring tools", "recording sheets", "measurement units chart"])
        
        if "soil" in text_lower:
            activities.append("Analyze soil properties")
            materials.extend(["soil samples", "testing kits", "pH meters"])
        
        if "nursery" in text_lower or "seedlings" in text_lower:
            activities.append("Establish and manage nursery")
            materials.extend(["seedling trays", "potting soil", "watering cans", "seeds"])
        
        return {
            "activities": activities,
            "materials": materials,
            "guidance": guidance
        }
    
    def extract_topics_comprehensive(self, content: str) -> List[Dict]:
        """Extract topics with comprehensive content analysis"""
        topics_data = []
        
        # Check if this is the alternative format
        if "**Learning Outcomes:**" in content and "**Competency:**" not in content:
            topics_data = self.extract_alternative_format_comprehensive(content)
        else:
            topics_data = self.extract_standard_format_comprehensive(content)
        
        return topics_data
    
    def extract_standard_format_comprehensive(self, content: str) -> List[Dict]:
        """Extract topics from standard format with comprehensive content"""
        topics_data = []
        
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
        
        for i, section in enumerate(best_sections[1:], 1):
            if not section.strip():
                continue
                
            lines = section.strip().split('\n')
            if not lines:
                continue
            
            topic_info = self.extract_topic_info_comprehensive(lines, content, section)
            if topic_info:
                topics_data.append(topic_info)
        
        if not topics_data:
            topics_data = self.extract_from_competency_patterns_comprehensive(content)
        
        return topics_data
    
    def extract_alternative_format_comprehensive(self, content: str) -> List[Dict]:
        """Extract topics from alternative format with comprehensive content"""
        topics_data = []
        
        lo_sections = re.finditer(
            r'\*\*Learning Outcomes:\*\*\s*\n\s*The learner should be able to:\s*\n((?:-\s*[^\n]+\s*\n?)+)',
            content,
            re.IGNORECASE | re.MULTILINE
        )
        
        for match in lo_sections:
            lo_text = match.group(1)
            learning_outcomes = re.findall(r'-\s*([^\n]+)', lo_text)
            learning_outcomes = [outcome.strip() for outcome in learning_outcomes if outcome.strip()]
            
            if not learning_outcomes:
                continue
            
            section_start = max(0, match.start() - 500)
            section_end = match.end()
            context = content[section_start:section_start + 1000]
            
            topic_name = self.extract_topic_name_from_context(context)
            class_info = self.extract_class_with_context(content, match.start())
            
            # Create comprehensive learning outcomes with extracted content
            comprehensive_outcomes = []
            for lo_text in learning_outcomes:
                extracted_content = self.extract_comprehensive_content(lo_text)
                
                outcome = {
                    "text": lo_text,
                    "outcome_type": self.determine_outcome_type(lo_text),
                    "lesson_unit": "single_outcome",
                    "activities": extracted_content["activities"],
                    "materials": extracted_content["materials"],
                    "assessment": {
                        "guidance": extracted_content["guidance"],
                        "mode": "formative",
                        "exam_eligibility": self.determine_exam_eligibility(lo_text)
                    },
                    "cross_cutting_issues": self.extract_cross_cutting_issues(lo_text)
                }
                comprehensive_outcomes.append(outcome)
            
            if comprehensive_outcomes:
                first_lo = comprehensive_outcomes[0]
                competency_text = f"The learner {first_lo['text'].lower()}"
                
                topics_data.append({
                    "class": class_info,
                    "strand": "General",
                    "topic": topic_name or "General Topic",
                    "suggested_periods": None,
                    "competency": competency_text,
                    "learning_outcomes": comprehensive_outcomes
                })
        
        return topics_data
    
    def extract_cross_cutting_issues(self, text: str) -> List[str]:
        """Extract cross-cutting issues from learning outcome text"""
        issues = []
        text_lower = text.lower()
        
        cross_cutting_keywords = {
            "environment": "Environmental sustainability",
            "financial": "Financial literacy",
            "entrepreneur": "Entrepreneurship skills",
            "safety": "Health and safety",
            "gender": "Gender issues",
            "technology": "Technology integration",
            "ict": "Information and communication technology",
            "conservation": "Conservation of natural resources",
            "climate": "Climate change awareness",
            "human rights": "Human rights",
            "democracy": "Democratic principles",
            "peace": "Peace and conflict resolution"
        }
        
        for keyword, issue in cross_cutting_keywords.items():
            if keyword in text_lower:
                issues.append(issue)
        
        return issues
    
    def extract_topic_name_from_context(self, context: str) -> str:
        """Extract topic name from surrounding context"""
        topic_patterns = [
            r'\*\*([^\*]+)\*\*\s*\((\d+) periods?\)',
            r'\*\*([^\*]+)\*\*',
            r'#### (.+)',
            r'### (.+)',
            r'## (.+)',
        ]
        
        for pattern in topic_patterns:
            match = re.search(pattern, context, re.IGNORECASE)
            if match:
                topic_name = match.group(1).strip()
                topic_name = re.sub(r'\s*\(\d+\s*periods?\)', '', topic_name)
                if len(topic_name) > 3:
                    return topic_name
        
        return "General Topic"
    
    def extract_topic_info_comprehensive(self, lines: List[str], full_content: str, section: str) -> Optional[Dict]:
        """Extract comprehensive topic information"""
        topic_line = lines[0]
        topic_name = self.clean_topic_name(topic_line)
        if not topic_name or len(topic_name) < 3:
            return None
        
        section_pos = full_content.find(section[:200])
        periods = self.extract_periods_enhanced(topic_line)
        competency = self.extract_competency_from_section(section)
        learning_outcomes = self.extract_learning_outcomes_comprehensive(section)
        class_info = self.extract_class_with_context(full_content, section_pos)
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
        topic_name = re.sub(r'\s*\(\d+\s*periods?\)', '', topic_line)
        topic_name = re.sub(r'\*\*$', '', topic_name)
        topic_name = topic_name.strip()
        
        skip_patterns = [
            r'competency:', r'learning outcomes:', r'the learner should',
            r'term \d+', r'senior \d+', r'assessment', r'cross-cutting'
        ]
        
        for pattern in skip_patterns:
            if re.search(pattern, topic_line, re.IGNORECASE):
                return ""
        
        return topic_name
    
    def extract_periods_enhanced(self, text: str) -> Optional[int]:
        """Enhanced period extraction"""
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
                competency = re.sub(r'\s+', ' ', competency)
                if len(competency) > 10 and not competency.lower().startswith('the learner'):
                    return competency
        
        return ""
    
    def extract_learning_outcomes_comprehensive(self, section: str) -> List[Dict]:
        """Extract learning outcomes with comprehensive content"""
        lo_patterns = [
            r'\*\*Learning Outcomes:\*\*\s*\n((?:-\s*[^\n]+\s*\n?)+)',
            r'The learner should be able to:\s*\n((?:-\s*[^\n]+\s*\n?)+)',
            r'Learning outcomes?:\s*\n((?:[-\*]\s*[^\n]+\s*\n?)+)',
            r'Should be able to:\s*\n((?:[-\*]\s*[^\n]+\s*\n?)+)',
        ]
        
        comprehensive_outcomes = []
        
        for pattern in lo_patterns:
            match = re.search(pattern, section, re.IGNORECASE)
            if match:
                lo_text = match.group(1)
                outcomes = re.findall(r'[-\*]\s*([^\n]+)', lo_text)
                learning_outcomes = [outcome.strip() for outcome in outcomes if outcome.strip()]
                
                for lo_text in learning_outcomes:
                    extracted_content = self.extract_comprehensive_content(lo_text)
                    
                    outcome = {
                        "text": lo_text,
                        "outcome_type": self.determine_outcome_type(lo_text),
                        "lesson_unit": "single_outcome",
                        "activities": extracted_content["activities"],
                        "materials": extracted_content["materials"],
                        "assessment": {
                            "guidance": extracted_content["guidance"],
                            "mode": "formative",
                            "exam_eligibility": self.determine_exam_eligibility(lo_text)
                        },
                        "cross_cutting_issues": self.extract_cross_cutting_issues(lo_text)
                    }
                    comprehensive_outcomes.append(outcome)
                
                break
        
        # Fallback: Look for any bullet points
        if not comprehensive_outcomes:
            bullet_points = re.findall(r'[-\*]\s*([^\n]+)', section)
            for bp_text in bullet_points:
                bp_text = bp_text.strip()
                if len(bp_text) > 10:
                    extracted_content = self.extract_comprehensive_content(bp_text)
                    
                    outcome = {
                        "text": bp_text,
                        "outcome_type": self.determine_outcome_type(bp_text),
                        "lesson_unit": "single_outcome",
                        "activities": extracted_content["activities"],
                        "materials": extracted_content["materials"],
                        "assessment": {
                            "guidance": extracted_content["guidance"],
                            "mode": "formative",
                            "exam_eligibility": self.determine_exam_eligibility(bp_text)
                        },
                        "cross_cutting_issues": self.extract_cross_cutting_issues(bp_text)
                    }
                    comprehensive_outcomes.append(outcome)
        
        return comprehensive_outcomes[:10]
    
    def extract_strand_from_context(self, content: str, section_pos: int) -> str:
        """Extract strand/theme from context"""
        context_start = max(0, section_pos - 1000)
        context = content[context_start:section_pos]
        
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
    
    def extract_from_competency_patterns_comprehensive(self, content: str) -> List[Dict]:
        """Fallback extraction using competency patterns"""
        topics_data = []
        
        competency_matches = re.finditer(r'\*\*Competency:\*\* ([^\n]+)', content, re.IGNORECASE)
        
        for match in competency_matches:
            competency_text = match.group(1).strip()
            
            start_pos = max(0, match.start() - 300)
            end_pos = min(len(content), match.end() + 800)
            context = content[start_pos:end_pos]
            
            topic_name = self.extract_topic_from_context(context, match.start() - start_pos)
            learning_outcomes = self.extract_learning_outcomes_comprehensive(context)
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
                topic_match = matches[-1]
                topic_name = topic_match.group(1).strip()
                topic_name = re.sub(r'\s*\(\d+\s*periods?\)', '', topic_name)
                return topic_name
        
        return ""
    
    def determine_outcome_type(self, outcome_text: str) -> str:
        """Determine outcome type with enhanced logic"""
        text_lower = outcome_text.lower()
        
        skill_count = sum(1 for verb in self.skill_verbs if f' {verb} ' in f' {text_lower} ')
        if skill_count > 0:
            return "skill"
        
        knowledge_count = sum(1 for verb in self.knowledge_verbs if f' {verb} ' in f' {text_lower} ')
        if knowledge_count > 0:
            return "knowledge"
        
        value_count = sum(1 for verb in self.value_verbs if f' {verb} ' in f' {text_lower} ')
        if value_count > 0:
            return "value"
        
        for verb in self.skill_verbs:
            if re.search(r'\b' + re.escape(verb) + r'\b', text_lower):
                return "skill"
        
        for verb in self.knowledge_verbs:
            if re.search(r'\b' + re.escape(verb) + r'\b', text_lower):
                return "knowledge"
        
        for verb in self.value_verbs:
            if re.search(r'\b' + re.escape(verb) + r'\b', text_lower):
                return "value"
        
        return "knowledge"
    
    def determine_exam_eligibility(self, outcome_text: str) -> str:
        """Determine exam eligibility"""
        text_lower = outcome_text.lower()
        
        if any(verb in text_lower for verb in self.exam_verbs):
            return "yes"
        
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
    
    def create_structured_entry_comprehensive(self, file_path: Path, topic_data: Dict) -> Optional[Dict]:
        """Create structured syllabus entry with comprehensive content"""
        subject, level = self.extract_subject_level(file_path.name)
        
        competency_text = topic_data["competency"].strip()
        if not competency_text or len(competency_text) < 10:
            return None
        
        # Create main entry
        entry = {
            "subject": subject,
            "level": level,
            "class": topic_data["class"],
            "strand": topic_data["strand"],
            "sub_strand": None,
            "topic": topic_data["topic"],
            "suggested_periods": topic_data.get("suggested_periods"),
            "competences": [{
                "text": competency_text,
                "learning_outcomes": topic_data["learning_outcomes"]
            }]
        }
        
        return entry
    
    def process_single_file_comprehensive(self, file_path: Path) -> Tuple[List[Dict], Dict[str, int]]:
        """Process single file with comprehensive extraction"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return [], {}
        
        topics_data = self.extract_topics_comprehensive(content)
        
        if not topics_data:
            print(f"No topics found in {file_path.name}")
            return [], {}
        
        entries = []
        content_metrics = {
            "activities": 0,
            "materials": 0,
            "guidance": 0
        }
        
        for topic_data in topics_data:
            entry = self.create_structured_entry_comprehensive(file_path, topic_data)
            if entry:
                entries.append(entry)
                
                # Count extracted content
                for competence in entry.get("competences", []):
                    for lo in competence.get("learning_outcomes", []):
                        content_metrics["activities"] += len(lo.get("activities", []))
                        content_metrics["materials"] += len(lo.get("materials", []))
                        if lo.get("assessment", {}).get("guidance"):
                            content_metrics["guidance"] += 1
        
        return entries, content_metrics
    
    def run_comprehensive_extraction(self) -> ExtractionMetrics:
        """Run comprehensive extraction with full content"""
        print("🚀 COMPREHENSIVE NCDC EXTRACTION")
        print("=" * 60)
        print("🎯 COMPREHENSIVE FEATURES:")
        print("- Extracts ACTIVITIES from learning outcomes")
        print("- Extracts MATERIALS mentioned in content")
        print("- Extracts ASSESSMENT GUIDANCE from context")
        print("- Identifies CROSS-CUTTING ISSUES")
        print("- Makes app truly AUTOMATIC GENERATOR")
        print("=" * 60)
        
        alevel_entries = []
        olevel_entries = []
        total_files = 0
        processed_files = 0
        failed_files = 0
        total_activities = 0
        total_materials = 0
        total_guidance = 0
        
        # Process A-Level files
        print("\n📚 Processing A-Level files...")
        alevel_files = list(self.alevel_dir.glob("*_clean.md"))
        
        for file_path in alevel_files:
            total_files += 1
            print(f"  Processing: {file_path.name}")
            try:
                entries, metrics = self.process_single_file_comprehensive(file_path)
                if entries:
                    alevel_entries.extend(entries)
                    processed_files += 1
                    total_activities += metrics["activities"]
                    total_materials += metrics["materials"]
                    total_guidance += metrics["guidance"]
                    print(f"    ✅ {len(entries)} entries, {metrics['activities']} activities, {metrics['materials']} materials")
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
                entries, metrics = self.process_single_file_comprehensive(file_path)
                if entries:
                    olevel_entries.extend(entries)
                    processed_files += 1
                    total_activities += metrics["activities"]
                    total_materials += metrics["materials"]
                    total_guidance += metrics["guidance"]
                    print(f"    ✅ {len(entries)} entries, {metrics['activities']} activities, {metrics['materials']} materials")
                else:
                    failed_files += 1
                    print(f"    ❌ No entries extracted")
            except Exception as e:
                print(f"    Error processing {file_path.name}: {e}")
                failed_files += 1
        
        # Save comprehensive files
        print(f"\n💾 Saving comprehensive files...")
        
        with open(self.output_dir / "alevel_data_comprehensive.json", 'w', encoding='utf-8') as f:
            json.dump(alevel_entries, f, indent=2, ensure_ascii=False)
        
        with open(self.output_dir / "olevel_data_comprehensive.json", 'w', encoding='utf-8') as f:
            json.dump(olevel_entries, f, indent=2, ensure_ascii=False)
        
        total_entries = len(alevel_entries) + len(olevel_entries)
        
        metrics = ExtractionMetrics(
            total_files=total_files,
            processed_files=processed_files,
            failed_files=failed_files,
            total_entries=total_entries,
            activities_extracted=total_activities,
            materials_extracted=total_materials,
            guidance_extracted=total_guidance
        )
        
        print(f"\n📊 COMPREHENSIVE EXTRACTION RESULTS:")
        print(f"  Total Files: {metrics.total_files}")
        print(f"  Processed Files: {metrics.processed_files}")
        print(f"  Failed Files: {metrics.failed_files}")
        print(f"  Total Entries: {metrics.total_entries}")
        print(f"  A-Level Entries: {len(alevel_entries)}")
        print(f"  O-Level Entries: {len(olevel_entries)}")
        print(f"  Activities Extracted: {metrics.activities_extracted}")
        print(f"  Materials Extracted: {metrics.materials_extracted}")
        print(f"  Guidance Extracted: {metrics.guidance_extracted}")
        
        print(f"\n📁 COMPREHENSIVE OUTPUT FILES:")
        print(f"  - alevel_data_comprehensive.json ({len(alevel_entries)} entries)")
        print(f"  - olevel_data_comprehensive.json ({len(olevel_entries)} entries)")
        
        return metrics

def main():
    extractor = ComprehensiveExtractor()
    metrics = extractor.run_comprehensive_extraction()
    print("\n🎉 COMPREHENSIVE EXTRACTION COMPLETED!")
    print("✅ App is now truly AUTOMATIC with full content!")
    return metrics

if __name__ == "__main__":
    main()
