#!/usr/bin/env python3
"""
NCDC SYLLABUS WEB UI DEMONSTRATION
Simple web interface to demonstrate the UI framework components
"""

from flask import Flask, render_template_string, request, jsonify
import json
from pathlib import Path
from syllabus_ui_framework import SyllabusUIFramework, ContentRequest

app = Flask(__name__)

# Initialize UI Framework
ui_framework = SyllabusUIFramework()

# HTML Templates
HOME_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NCDC Syllabus Browser</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; background: #f5f5f5; }
        .header { background: #2c3e50; color: white; padding: 1rem; }
        .container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
        .nav-tree { background: white; border-radius: 8px; padding: 1rem; margin-bottom: 2rem; }
        .search-box { background: white; border-radius: 8px; padding: 1rem; margin-bottom: 2rem; }
        .content-area { background: white; border-radius: 8px; padding: 1rem; }
        .node { padding: 0.5rem; cursor: pointer; border-radius: 4px; }
        .node:hover { background: #ecf0f1; }
        .node.active { background: #3498db; color: white; }
        .children { margin-left: 1.5rem; }
        .entry { border: 1px solid #ddd; border-radius: 4px; padding: 1rem; margin-bottom: 1rem; }
        .entry h3 { color: #2c3e50; margin-bottom: 0.5rem; }
        .entry .meta { color: #7f8c8d; font-size: 0.9rem; margin-bottom: 0.5rem; }
        .competency { background: #ecf0f1; padding: 0.5rem; border-radius: 4px; margin: 0.5rem 0; }
        .outcome { margin-left: 1rem; padding: 0.25rem 0; }
        .search-input { width: 100%; padding: 0.5rem; border: 1px solid #ddd; border-radius: 4px; }
        .btn { background: #3498db; color: white; padding: 0.5rem 1rem; border: none; border-radius: 4px; cursor: pointer; }
        .btn:hover { background: #2980b9; }
        .filters { display: flex; gap: 1rem; margin-bottom: 1rem; }
        .filter-select { padding: 0.5rem; border: 1px solid #ddd; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎓 NCDC Syllabus Browser</h1>
        <p>Dynamic syllabus content exploration</p>
    </div>
    
    <div class="container">
        <div class="search-box">
            <h2>🔍 Search Content</h2>
            <input type="text" id="searchInput" class="search-input" placeholder="Search topics, competencies, outcomes...">
            <div class="filters">
                <select id="levelFilter" class="filter-select">
                    <option value="">All Levels</option>
                    <option value="Advanced Secondary">A-Level</option>
                    <option value="Lower Secondary">O-Level</option>
                </select>
                <select id="subjectFilter" class="filter-select">
                    <option value="">All Subjects</option>
                </select>
                <button onclick="performSearch()" class="btn">Search</button>
            </div>
        </div>
        
        <div class="nav-tree">
            <h2>🌳 Navigation Tree</h2>
            <div id="navigationTree">
                <!-- Navigation tree will be rendered here -->
            </div>
        </div>
        
        <div class="content-area">
            <h2>📚 Content</h2>
            <div id="contentArea">
                <p>Select a node from the navigation tree or search to view content.</p>
            </div>
        </div>
    </div>

    <script>
        let navigationData = {{ navigation_data|tojson }};
        let currentFilters = {};
        
        function renderNavigationTree() {
            const container = document.getElementById('navigationTree');
            container.innerHTML = renderNode(navigationData.root);
        }
        
        function renderNode(node, level = 0) {
            let html = `<div class="node" onclick="selectNode('${node.node_id}')" style="margin-left: ${level * 20}px">
                📁 ${node.title} (${node.metadata.entry_count || 0})
            </div>`;
            
            if (node.children && node.children.length > 0) {
                html += '<div class="children">';
                for (const childId of node.children) {
                    const childNode = navigationData[childId];
                    if (childNode) {
                        html += renderNode(childNode, level + 1);
                    }
                }
                html += '</div>';
            }
            
            return html;
        }
        
        function selectNode(nodeId) {
            // Remove active class from all nodes
            document.querySelectorAll('.node').forEach(n => n.classList.remove('active'));
            
            // Add active class to selected node
            event.target.classList.add('active');
            
            // Load content for this node
            loadNodeContent(nodeId);
        }
        
        function loadNodeContent(nodeId) {
            const node = navigationData[nodeId];
            if (!node) return;
            
            const contentArea = document.getElementById('contentArea');
            
            if (node.node_type === 'topic') {
                // Load topic content
                loadTopicContent(node.data);
            } else {
                // Show node information
                contentArea.innerHTML = `
                    <div class="entry">
                        <h3>${node.title}</h3>
                        <div class="meta">
                            Type: ${node.node_type} | 
                            Entries: ${node.metadata.entry_count || 0}
                        </div>
                        <p>Select a child node to view detailed content.</p>
                    </div>
                `;
            }
        }
        
        function loadTopicContent(topicData) {
            const request = {
                request_type: "browse",
                filters: {
                    level: topicData.level,
                    subject: topicData.subject,
                    class: topicData.class,
                    topic: topicData.topic
                }
            };
            
            fetch('/content', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(request)
            })
            .then(response => response.json())
            .then(data => {
                renderTopicContent(data.entries[0]);
            });
        }
        
        function renderTopicContent(entry) {
            const contentArea = document.getElementById('contentArea');
            
            let html = `
                <div class="entry">
                    <h3>${entry.topic}</h3>
                    <div class="meta">
                        ${entry.subject} | ${entry.level} | ${entry.class} | 
                        ${entry.strand || 'No strand'} | 
                        ${entry.suggested_periods || '?'} periods
                    </div>
            `;
            
            for (const competence of entry.competences || []) {
                html += `
                    <div class="competency">
                        <strong>🎯 Competency:</strong> ${competence.text}
                        <div class="outcomes">
                `;
                
                for (const outcome of competence.learning_outcomes || []) {
                    html += `<div class="outcome">✓ ${outcome.text}</div>`;
                }
                
                html += `
                        </div>
                    </div>
                `;
            }
            
            html += '</div>';
            contentArea.innerHTML = html;
        }
        
        function performSearch() {
            const query = document.getElementById('searchInput').value;
            const level = document.getElementById('levelFilter').value;
            const subject = document.getElementById('subjectFilter').value;
            
            if (!query.trim()) {
                alert('Please enter a search query');
                return;
            }
            
            const request = {
                request_type: "search",
                filters: {
                    query: query,
                    level: level || undefined,
                    subject: subject || undefined
                }
            };
            
            fetch('/content', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(request)
            })
            .then(response => response.json())
            .then(data => {
                renderSearchResults(data);
            });
        }
        
        function renderSearchResults(searchData) {
            const contentArea = document.getElementById('contentArea');
            
            let html = `<h3>🔍 Search Results: ${searchData.total_results} found</h3>`;
            
            for (const result of searchData.results || []) {
                const entry = result.entry;
                html += `
                    <div class="entry">
                        <h3>${entry.topic}</h3>
                        <div class="meta">
                            ${entry.subject} | ${entry.level} | ${entry.class} | 
                            Relevance: ${result.relevance_score.toFixed(2)}
                        </div>
                        <p><strong>Matched in:</strong> ${result.matched_fields.join(', ')}</p>
                    </div>
                `;
            }
            
            contentArea.innerHTML = html;
        }
        
        // Initialize on page load
        document.addEventListener('DOMContentLoaded', function() {
            renderNavigationTree();
            
            // Setup search input enter key
            document.getElementById('searchInput').addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    performSearch();
                }
            });
        });
    </script>
</body>
</html>
"""

@app.route('/')
def home():
    """Home page with navigation tree"""
    # Get navigation data for frontend
    navigation_data = {}
    for node_id, node in ui_framework.navigation_tree.items():
        navigation_data[node_id] = {
            'node_id': node.node_id,
            'node_type': node.node_type,
            'title': node.title,
            'parent_id': node.parent_id,
            'children': node.children,
            'data': node.data,
            'metadata': node.metadata
        }
    
    return render_template_string(HOME_TEMPLATE, navigation_data=navigation_data)

@app.route('/content', methods=['POST'])
def get_content():
    """API endpoint to get content"""
    try:
        request_data = request.get_json()
        
        # Create ContentRequest object
        content_request = ContentRequest(
            request_type=request_data.get('request_type', 'browse'),
            filters=request_data.get('filters', {}),
            sort_by=request_data.get('sort_by'),
            limit=request_data.get('limit'),
            user_context=request_data.get('user_context', {})
        )
        
        # Generate content
        content = ui_framework.generate_content(content_request)
        
        return jsonify(content)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/navigation/<node_id>')
def get_navigation_node(node_id):
    """API endpoint to get navigation node details"""
    try:
        if node_id in ui_framework.navigation_tree:
            node = ui_framework.navigation_tree[node_id]
            return jsonify({
                'node_id': node.node_id,
                'node_type': node.node_type,
                'title': node.title,
                'parent_id': node.parent_id,
                'children': node.get_children_nodes(),
                'data': node.data,
                'metadata': node.metadata
            })
        else:
            return jsonify({'error': 'Node not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/stats')
def get_stats():
    """API endpoint to get system statistics"""
    try:
        stats = {
            'total_entries': len(ui_framework.all_data),
            'navigation_nodes': len(ui_framework.navigation_tree),
            'alevel_entries': len(ui_framework.alevel_data),
            'olevel_entries': len(ui_framework.olevel_data),
            'subjects': len(set(e.get('subject', '') for e in ui_framework.all_data)),
            'classes': len(set(e.get('class', '') for e in ui_framework.all_data))
        }
        
        return jsonify(stats)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("🌐 Starting NCDC Syllabus Web UI Demo...")
    print("📱 Open http://localhost:5000 in your browser")
    print("🎯 Features: Navigation tree, search, content browsing")
    
    app.run(debug=True, host='0.0.0.0', port=5000)
