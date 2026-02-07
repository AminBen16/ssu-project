#!/usr/bin/env python3
"""
NCDC SYLLABUS UI INTEGRATION FRAMEWORK
Dynamic UI-based content generation system for syllabus data
Button-based navigation, topic selection, competency viewing, and query processing
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple, Union
from dataclasses import dataclass, asdict
from datetime import datetime
from collections import defaultdict, Counter
import sqlite3
import hashlib

@dataclass
class UIComponent:
    """UI component definition"""
    component_type: str
    component_id: str
    title: str
    description: str
    data_source: str
    actions: List[str]
    dependencies: List[str]

@dataclass
class NavigationNode:
    """Navigation tree node"""
    node_id: str
    node_type: str  # "level", "subject", "class", "strand", "topic"
    title: str
    parent_id: Optional[str]
    children: List[str]
    data: Dict[str, Any]
    metadata: Dict[str, Any]

@dataclass
class ContentRequest:
    """Content generation request"""
    request_type: str
    filters: Dict[str, Any]
    sort_by: Optional[str]
    limit: Optional[int]
    user_context: Dict[str, Any]

class SyllabusUIFramework:
    def __init__(self, base_dir: str = "C:/Users/user/SSU"):
        self.base_dir = Path(base_dir)
        self.data_dir = self.base_dir / "syllabus_data_structure"
        self.db_file = self.data_dir / "syllabus_ui.db"
        
        # Load data
        self.alevel_data = []
        self.olevel_data = []
        self.all_data = []
        
        # UI state
        self.navigation_tree = {}
        self.content_cache = {}
        self.user_preferences = {}
        
        # Initialize
        self.load_data()
        self.initialize_database()
        self.build_navigation_tree()
    
    def load_data(self):
        """Load syllabus data"""
        try:
            with open(self.data_dir / "alevel_data.json", 'r', encoding='utf-8') as f:
                self.alevel_data = json.load(f)
        except Exception as e:
            print(f"❌ Error loading A-Level data: {e}")
        
        try:
            with open(self.data_dir / "olevel_data.json", 'r', encoding='utf-8') as f:
                self.olevel_data = json.load(f)
        except Exception as e:
            print(f"❌ Error loading O-Level data: {e}")
        
        self.all_data = self.alevel_data + self.olevel_data
        print(f"📚 Loaded {len(self.all_data)} total entries")
    
    def initialize_database(self):
        """Initialize SQLite database for UI operations"""
        conn = sqlite3.connect(self.db_file)
        cursor = conn.cursor()
        
        # Create tables
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS syllabus_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                entry_id TEXT UNIQUE,
                level TEXT,
                subject TEXT,
                class TEXT,
                strand TEXT,
                topic TEXT,
                competency_count INTEGER,
                outcome_count INTEGER,
                data_hash TEXT,
                full_data TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS navigation_cache (
                node_id TEXT PRIMARY KEY,
                node_type TEXT,
                title TEXT,
                parent_id TEXT,
                children TEXT,
                data TEXT,
                metadata TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_interactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT,
                interaction_type TEXT,
                node_id TEXT,
                filters TEXT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Indexes for performance
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_level ON syllabus_entries(level)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_subject ON syllabus_entries(subject)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_class ON syllabus_entries(class)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_topic ON syllabus_entries(topic)')
        
        conn.commit()
        conn.close()
        
        print("🗄️  Database initialized")
    
    def populate_database(self):
        """Populate database with syllabus data"""
        conn = sqlite3.connect(self.db_file)
        cursor = conn.cursor()
        
        # Clear existing data
        cursor.execute("DELETE FROM syllabus_entries")
        
        # Insert entries
        for entry in self.all_data:
            entry_id = self.generate_entry_id(entry)
            data_hash = self.generate_data_hash(entry)
            
            competency_count = len(entry.get("competences", []))
            outcome_count = sum(
                len(comp.get("learning_outcomes", [])) 
                for comp in entry.get("competences", [])
            )
            
            cursor.execute('''
                INSERT OR REPLACE INTO syllabus_entries 
                (entry_id, level, subject, class, strand, topic, 
                 competency_count, outcome_count, data_hash, full_data)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                entry_id,
                entry.get("level", ""),
                entry.get("subject", ""),
                entry.get("class", ""),
                entry.get("strand", ""),
                entry.get("topic", ""),
                competency_count,
                outcome_count,
                data_hash,
                json.dumps(entry)
            ))
        
        conn.commit()
        conn.close()
        
        print(f"💾 Database populated with {len(self.all_data)} entries")
    
    def generate_entry_id(self, entry: Dict) -> str:
        """Generate unique entry ID"""
        level = entry.get("level", "").replace(" ", "_")
        subject = entry.get("subject", "").replace(" ", "_").lower()
        topic = entry.get("topic", "").replace(" ", "_").lower()[:20]
        class_name = entry.get("class", "").replace(" ", "_")
        
        return f"{level}_{subject}_{topic}_{class_name}"
    
    def generate_data_hash(self, entry: Dict) -> str:
        """Generate hash for data integrity"""
        content = json.dumps(entry, sort_keys=True)
        return hashlib.md5(content.encode()).hexdigest()
    
    def build_navigation_tree(self):
        """Build hierarchical navigation tree"""
        print("🌳 Building navigation tree...")
        
        # Root nodes
        self.navigation_tree = {
            "root": NavigationNode(
                node_id="root",
                node_type="root",
                title="NCDC Syllabus",
                parent_id=None,
                children=["alevel", "olevel"],
                data={},
                metadata={"total_entries": len(self.all_data)}
            )
        }
        
        # Level nodes
        alevel_node = NavigationNode(
            node_id="alevel",
            node_type="level",
            title="Advanced Secondary (A-Level)",
            parent_id="root",
            children=[],
            data={"level": "Advanced Secondary"},
            metadata={
                "entry_count": len(self.alevel_data),
                "subject_count": len(set(e.get("subject", "") for e in self.alevel_data))
            }
        )
        
        olevel_node = NavigationNode(
            node_id="olevel",
            node_type="level",
            title="Lower Secondary (O-Level)",
            parent_id="root",
            children=[],
            data={"level": "Lower Secondary"},
            metadata={
                "entry_count": len(self.olevel_data),
                "subject_count": len(set(e.get("subject", "") for e in self.olevel_data))
            }
        )
        
        self.navigation_tree["alevel"] = alevel_node
        self.navigation_tree["olevel"] = olevel_node
        self.navigation_tree["root"].children = ["alevel", "olevel"]
        
        # Subject nodes
        self.add_subject_nodes("alevel", self.alevel_data)
        self.add_subject_nodes("olevel", self.olevel_data)
        
        # Cache navigation tree
        self.cache_navigation_tree()
        
        print(f"🌳 Navigation tree built with {len(self.navigation_tree)} nodes")
    
    def add_subject_nodes(self, level_id: str, data: List[Dict]):
        """Add subject nodes to navigation tree"""
        level_node = self.navigation_tree[level_id]
        subjects = defaultdict(list)
        
        # Group by subject
        for entry in data:
            subject = entry.get("subject", "Unknown")
            subjects[subject].append(entry)
        
        # Create subject nodes
        for subject, entries in subjects.items():
            subject_id = f"{level_id}_{subject.lower().replace(' ', '_')}"
            
            subject_node = NavigationNode(
                node_id=subject_id,
                node_type="subject",
                title=subject,
                parent_id=level_id,
                children=[],
                data={"subject": subject, "level": level_node.data["level"]},
                metadata={
                    "entry_count": len(entries),
                    "classes": list(set(e.get("class", "") for e in entries)),
                    "strands": list(set(e.get("strand", "") for e in entries))
                }
            )
            
            self.navigation_tree[subject_id] = subject_node
            level_node.children.append(subject_id)
            
            # Add class nodes
            self.add_class_nodes(subject_id, entries)
    
    def add_class_nodes(self, subject_id: str, entries: List[Dict]):
        """Add class nodes to navigation tree"""
        subject_node = self.navigation_tree[subject_id]
        classes = defaultdict(list)
        
        # Group by class
        for entry in entries:
            class_name = entry.get("class", "Unknown")
            classes[class_name].append(entry)
        
        # Create class nodes
        for class_name, class_entries in classes.items():
            class_id = f"{subject_id}_{class_name.lower().replace(' ', '_')}"
            
            class_node = NavigationNode(
                node_id=class_id,
                node_type="class",
                title=class_name,
                parent_id=subject_id,
                children=[],
                data={
                    "subject": subject_node.data["subject"],
                    "level": subject_node.data["level"],
                    "class": class_name
                },
                metadata={
                    "entry_count": len(class_entries),
                    "topics": [e.get("topic", "") for e in class_entries]
                }
            )
            
            self.navigation_tree[class_id] = class_node
            subject_node.children.append(class_id)
            
            # Add topic nodes
            self.add_topic_nodes(class_id, class_entries)
    
    def add_topic_nodes(self, class_id: str, entries: List[Dict]):
        """Add topic nodes to navigation tree"""
        class_node = self.navigation_tree[class_id]
        
        # Create topic nodes
        for entry in entries:
            topic = entry.get("topic", "Unknown Topic")
            topic_id = f"{class_id}_{topic.lower().replace(' ', '_').replace('/', '_')}"
            
            topic_node = NavigationNode(
                node_id=topic_id,
                node_type="topic",
                title=topic,
                parent_id=class_id,
                children=[],
                data={
                    "subject": class_node.data["subject"],
                    "level": class_node.data["level"],
                    "class": class_node.data["class"],
                    "topic": topic,
                    "strand": entry.get("strand", ""),
                    "suggested_periods": entry.get("suggested_periods")
                },
                metadata={
                    "competency_count": len(entry.get("competences", [])),
                    "outcome_count": sum(
                        len(comp.get("learning_outcomes", [])) 
                        for comp in entry.get("competences", [])
                    ),
                    "entry_data": entry
                }
            )
            
            self.navigation_tree[topic_id] = topic_node
            class_node.children.append(topic_id)
    
    def cache_navigation_tree(self):
        """Cache navigation tree in database"""
        conn = sqlite3.connect(self.db_file)
        cursor = conn.cursor()
        
        # Clear existing cache
        cursor.execute("DELETE FROM navigation_cache")
        
        # Insert nodes
        for node_id, node in self.navigation_tree.items():
            cursor.execute('''
                INSERT INTO navigation_cache 
                (node_id, node_type, title, parent_id, children, data, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                node_id,
                node.node_type,
                node.title,
                node.parent_id,
                json.dumps(node.children),
                json.dumps(node.data),
                json.dumps(node.metadata)
            ))
        
        conn.commit()
        conn.close()
    
    def get_navigation_path(self, node_id: str) -> List[NavigationNode]:
        """Get navigation path from root to node"""
        path = []
        current_id = node_id
        
        while current_id and current_id in self.navigation_tree:
            node = self.navigation_tree[current_id]
            path.append(node)
            current_id = node.parent_id
        
        return list(reversed(path))
    
    def get_children_nodes(self, node_id: str) -> List[NavigationNode]:
        """Get children of a navigation node"""
        if node_id not in self.navigation_tree:
            return []
        
        node = self.navigation_tree[node_id]
        children = []
        
        for child_id in node.children:
            if child_id in self.navigation_tree:
                children.append(self.navigation_tree[child_id])
        
        return children
    
    def search_content(self, query: str, filters: Dict[str, Any] = None) -> List[Dict]:
        """Search syllabus content"""
        if filters is None:
            filters = {}
        
        results = []
        query_lower = query.lower()
        
        for entry in self.all_data:
            # Apply filters
            if filters.get("level") and entry.get("level") != filters["level"]:
                continue
            if filters.get("subject") and entry.get("subject") != filters["subject"]:
                continue
            if filters.get("class") and entry.get("class") != filters["class"]:
                continue
            
            # Search in text fields
            searchable_text = " ".join([
                entry.get("subject", ""),
                entry.get("topic", ""),
                entry.get("strand", ""),
                entry.get("class", "")
            ]).lower()
            
            # Search in competencies and outcomes
            for competence in entry.get("competences", []):
                searchable_text += " " + competence.get("text", "").lower()
                for outcome in competence.get("learning_outcomes", []):
                    searchable_text += " " + outcome.get("text", "").lower()
            
            if query_lower in searchable_text:
                results.append({
                    "entry": entry,
                    "relevance_score": self.calculate_relevance(query, entry),
                    "matched_fields": self.get_matched_fields(query, entry)
                })
        
        # Sort by relevance
        results.sort(key=lambda x: x["relevance_score"], reverse=True)
        
        return results
    
    def calculate_relevance(self, query: str, entry: Dict) -> float:
        """Calculate relevance score for search"""
        query_lower = query.lower()
        score = 0.0
        
        # Title matches
        if query_lower in entry.get("topic", "").lower():
            score += 3.0
        
        if query_lower in entry.get("subject", "").lower():
            score += 2.0
        
        # Competency matches
        for competence in entry.get("competences", []):
            if query_lower in competence.get("text", "").lower():
                score += 1.5
            for outcome in competence.get("learning_outcomes", []):
                if query_lower in outcome.get("text", "").lower():
                    score += 1.0
        
        return score
    
    def get_matched_fields(self, query: str, entry: Dict) -> List[str]:
        """Get fields that matched the query"""
        query_lower = query.lower()
        matched = []
        
        if query_lower in entry.get("topic", "").lower():
            matched.append("topic")
        if query_lower in entry.get("subject", "").lower():
            matched.append("subject")
        if query_lower in entry.get("strand", "").lower():
            matched.append("strand")
        
        return matched
    
    def generate_content(self, request: ContentRequest) -> Dict[str, Any]:
        """Generate content based on request"""
        cache_key = self.generate_cache_key(request)
        
        # Check cache
        if cache_key in self.content_cache:
            return self.content_cache[cache_key]
        
        # Generate content
        if request.request_type == "browse":
            content = self.generate_browse_content(request)
        elif request.request_type == "search":
            content = self.generate_search_content(request)
        elif request.request_type == "competency_view":
            content = self.generate_competency_content(request)
        elif request.request_type == "learning_outcomes":
            content = self.generate_outcomes_content(request)
        else:
            content = {"error": "Unknown request type"}
        
        # Cache result
        self.content_cache[cache_key] = content
        
        return content
    
    def generate_cache_key(self, request: ContentRequest) -> str:
        """Generate cache key for request"""
        content = json.dumps({
            "request_type": request.request_type,
            "filters": request.filters,
            "sort_by": request.sort_by,
            "limit": request.limit
        }, sort_keys=True)
        return hashlib.md5(content.encode()).hexdigest()
    
    def generate_browse_content(self, request: ContentRequest) -> Dict[str, Any]:
        """Generate browse content"""
        filters = request.filters or {}
        
        # Filter data
        filtered_data = self.all_data
        
        if filters.get("level"):
            filtered_data = [e for e in filtered_data if e.get("level") == filters["level"]]
        
        if filters.get("subject"):
            filtered_data = [e for e in filtered_data if e.get("subject") == filters["subject"]]
        
        if filters.get("class"):
            filtered_data = [e for e in filtered_data if e.get("class") == filters["class"]]
        
        # Sort
        if request.sort_by == "topic":
            filtered_data.sort(key=lambda x: x.get("topic", ""))
        elif request.sort_by == "subject":
            filtered_data.sort(key=lambda x: x.get("subject", ""))
        elif request.sort_by == "class":
            filtered_data.sort(key=lambda x: x.get("class", ""))
        
        # Limit
        if request.limit:
            filtered_data = filtered_data[:request.limit]
        
        return {
            "content_type": "browse",
            "total_entries": len(filtered_data),
            "entries": filtered_data,
            "filters_applied": filters,
            "navigation_breadcrumbs": self.generate_breadcrumbs(filters)
        }
    
    def generate_search_content(self, request: ContentRequest) -> Dict[str, Any]:
        """Generate search content"""
        query = request.filters.get("query", "")
        search_filters = {k: v for k, v in request.filters.items() if k != "query"}
        
        results = self.search_content(query, search_filters)
        
        # Limit results
        if request.limit:
            results = results[:request.limit]
        
        return {
            "content_type": "search",
            "query": query,
            "total_results": len(results),
            "results": results,
            "filters_applied": search_filters
        }
    
    def generate_competency_content(self, request: ContentRequest) -> Dict[str, Any]:
        """Generate competency-focused content"""
        filters = request.filters or {}
        
        # Get specific entry or entries
        if filters.get("entry_id"):
            entry = self.find_entry_by_id(filters["entry_id"])
            if entry:
                return {
                    "content_type": "competency_detail",
                    "entry": entry,
                    "competencies": entry.get("competences", []),
                    "metadata": {
                        "subject": entry.get("subject"),
                        "topic": entry.get("topic"),
                        "class": entry.get("class")
                    }
                }
        
        # Get competencies for filtered entries
        filtered_data = self.apply_filters(self.all_data, filters)
        all_competencies = []
        
        for entry in filtered_data:
            for competence in entry.get("competences", []):
                all_competencies.append({
                    "competence": competence,
                    "source_entry": entry
                })
        
        return {
            "content_type": "competency_list",
            "total_competencies": len(all_competencies),
            "competencies": all_competencies,
            "filters_applied": filters
        }
    
    def generate_outcomes_content(self, request: ContentRequest) -> Dict[str, Any]:
        """Generate learning outcomes content"""
        filters = request.filters or {}
        
        # Get specific competency outcomes
        if filters.get("competency_id"):
            # Find competency and return its outcomes
            for entry in self.all_data:
                for competence in entry.get("competences", []):
                    if self.generate_competency_id(competence) == filters["competency_id"]:
                        return {
                            "content_type": "learning_outcomes_detail",
                            "competence": competence,
                            "outcomes": competence.get("learning_outcomes", []),
                            "source_entry": entry
                        }
        
        # Get outcomes for filtered entries
        filtered_data = self.apply_filters(self.all_data, filters)
        all_outcomes = []
        
        for entry in filtered_data:
            for competence in entry.get("competences", []):
                for outcome in competence.get("learning_outcomes", []):
                    all_outcomes.append({
                        "outcome": outcome,
                        "competence": competence,
                        "source_entry": entry
                    })
        
        return {
            "content_type": "learning_outcomes_list",
            "total_outcomes": len(all_outcomes),
            "outcomes": all_outcomes,
            "filters_applied": filters
        }
    
    def apply_filters(self, data: List[Dict], filters: Dict[str, Any]) -> List[Dict]:
        """Apply filters to data"""
        filtered = data
        
        for key, value in filters.items():
            if key == "level":
                filtered = [e for e in filtered if e.get("level") == value]
            elif key == "subject":
                filtered = [e for e in filtered if e.get("subject") == value]
            elif key == "class":
                filtered = [e for e in filtered if e.get("class") == value]
            elif key == "strand":
                filtered = [e for e in filtered if e.get("strand") == value]
        
        return filtered
    
    def find_entry_by_id(self, entry_id: str) -> Optional[Dict]:
        """Find entry by ID"""
        for entry in self.all_data:
            if self.generate_entry_id(entry) == entry_id:
                return entry
        return None
    
    def generate_competency_id(self, competence: Dict) -> str:
        """Generate competency ID"""
        text = competence.get("text", "")[:50]
        return hashlib.md5(text.encode()).hexdigest()[:8]
    
    def generate_breadcrumbs(self, filters: Dict[str, Any]) -> List[Dict]:
        """Generate navigation breadcrumbs"""
        breadcrumbs = [{"title": "Home", "node_id": "root"}]
        
        if filters.get("level"):
            level_id = "alevel" if filters["level"] == "Advanced Secondary" else "olevel"
            breadcrumbs.append({
                "title": filters["level"],
                "node_id": level_id
            })
        
        if filters.get("subject"):
            breadcrumbs.append({
                "title": filters["subject"],
                "node_id": f"{level_id}_{filters['subject'].lower().replace(' ', '_')}"
            })
        
        if filters.get("class"):
            breadcrumbs.append({
                "title": filters["class"],
                "node_id": f"{level_id}_{filters['subject'].lower().replace(' ', '_')}_{filters['class'].lower().replace(' ', '_')}"
            })
        
        return breadcrumbs
    
    def get_ui_components(self) -> List[UIComponent]:
        """Get available UI components"""
        return [
            UIComponent(
                component_type="navigation",
                component_id="main_nav",
                title="Main Navigation",
                description="Hierarchical navigation tree",
                data_source="navigation_tree",
                actions=["browse", "expand", "collapse"],
                dependencies=["database"]
            ),
            UIComponent(
                component_type="search",
                component_id="content_search",
                title="Content Search",
                description="Full-text search across syllabus content",
                data_source="all_data",
                actions=["search", "filter", "sort"],
                dependencies=["search_index"]
            ),
            UIComponent(
                component_type="browser",
                component_id="topic_browser",
                title="Topic Browser",
                description="Browse topics by subject and class",
                data_source="filtered_data",
                actions=["browse", "filter", "detail"],
                dependencies=["navigation_tree"]
            ),
            UIComponent(
                component_type="viewer",
                component_id="competency_viewer",
                title="Competency Viewer",
                description="View detailed competency information",
                data_source="competency_data",
                actions=["view", "expand_outcomes", "cross_reference"],
                dependencies=["competency_index"]
            ),
            UIComponent(
                component_type="filter",
                component_id="dynamic_filter",
                title="Dynamic Filter",
                description="Filter content by multiple criteria",
                data_source="filter_options",
                actions=["filter", "save", "load"],
                dependencies=["filter_schema"]
            )
        ]
    
    def initialize_ui_system(self):
        """Initialize the complete UI system"""
        print("🚀 Initializing NCDC Syllabus UI Framework...")
        
        # Populate database
        self.populate_database()
        
        # Build navigation
        self.build_navigation_tree()
        
        # Get UI components
        components = self.get_ui_components()
        
        print(f"✅ UI Framework initialized with {len(components)} components")
        print(f"📊 Navigation tree: {len(self.navigation_tree)} nodes")
        print(f"🗄️  Database: {len(self.all_data)} entries indexed")
        
        return {
            "status": "initialized",
            "components": [asdict(comp) for comp in components],
            "navigation_nodes": len(self.navigation_tree),
            "indexed_entries": len(self.all_data),
            "database_path": str(self.db_file)
        }

def main():
    """Main UI framework initializer"""
    ui_framework = SyllabusUIFramework()
    
    # Initialize system
    initialization_result = ui_framework.initialize_ui_system()
    
    print("\n🎉 UI Framework Ready!")
    print("=" * 50)
    
    for key, value in initialization_result.items():
        if key != "components":
            print(f"  {key.title()}: {value}")
    
    print(f"\n📱 Available Components: {len(initialization_result['components'])}")
    for comp in initialization_result['components']:
        print(f"  • {comp['title']} ({comp['component_type']})")
    
    return initialization_result

if __name__ == "__main__":
    main()
