import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test/services/syllabus_data_service.dart';

/// Main syllabus browser screen
class SyllabusBrowserScreen extends StatefulWidget {
  const SyllabusBrowserScreen({Key? key}) : super(key: key);

  @override
  _SyllabusBrowserScreenState createState() => _SyllabusBrowserScreenState();
}

class _SyllabusBrowserScreenState extends State<SyllabusBrowserScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<SyllabusEntry> _allEntries = [];
  List<NavigationNode> _navigationTree = [];
  List<NavigationNode> _currentPath = [];
  bool _isLoading = true;
  String _searchQuery = '';
  List<SearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load data into database if needed
      await SyllabusDatabaseService.loadSyllabusData();
      
      // Get all entries
      final entries = await SyllabusDatabaseService.getAllEntries();
      
      // Build navigation tree
      final navigationTree = NavigationService.buildNavigationTree(entries);
      
      setState(() {
        _allEntries = entries;
        _navigationTree = navigationTree;
        _currentPath = [_navigationTree.firstWhere((node) => node.type == NavigationType.root)];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _navigateToNode(NavigationNode node) {
    setState(() {
      // Update current path
      final nodeIndex = _currentPath.indexWhere((n) => n.id == node.id);
      if (nodeIndex >= 0) {
        _currentPath = _currentPath.sublist(0, nodeIndex + 1);
      } else {
        _currentPath.add(node);
      }
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchQuery = '';
      });
      return;
    }

    final results = SearchService.search(query, _allEntries);
    setState(() {
      _searchResults = results;
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NCDC Syllabus Browser'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.explore), text: 'Browse'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.info), text: 'About'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildSearchTab(),
          _buildAboutTab(),
        ],
      ),
    );
  }

  Widget _buildBrowseTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildBreadcrumbNavigation(),
        Expanded(
          child: _currentPath.isEmpty
              ? const Center(child: Text('No navigation data available'))
              : _buildNavigationContent(),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbNavigation() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _currentPath.asMap().entries.map((entry) {
            final index = entry.key;
            final node = entry.value;
            final isLast = index == _currentPath.length - 1;
            
            return Row(
              children: [
                if (index > 0) ...[
                  const Icon(Icons.chevron_right, color: Colors.grey),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: () {
                    if (!isLast) {
                      _navigateToNode(node);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLast ? Colors.indigo : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      node.title,
                      style: TextStyle(
                        color: isLast ? Colors.white : Colors.indigo,
                        fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavigationContent() {
    final currentNode = _currentPath.last;
    final children = _navigationTree
        .where((node) => node.parentId == currentNode.id)
        .toList();

    if (children.isEmpty) {
      // Show topic details
      if (currentNode.type == NavigationType.topic) {
        final entry = currentNode.data['entry'] as SyllabusEntry?;
        if (entry != null) {
          return TopicDetailView(entry: entry);
        }
      }
      return const Center(child: Text('No content available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final node = children[index];
        return NavigationTile(
          node: node,
          onTap: () => _navigateToNode(node),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search topics, subjects, competencies...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _performSearch(''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _performSearch,
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: _searchQuery.isEmpty
                      ? const Text('Enter a search query to find content')
                      : const Text('No results found'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return SearchResultTile(result: result);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NCDC Syllabus Browser',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Comprehensive syllabus data exploration for Ugandan education',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Total Entries', '${_allEntries.length}'),
                  _buildStatRow('Subjects', '${_allEntries.map((e) => e.subject).toSet().length}'),
                  _buildStatRow('Classes', '${_allEntries.map((e) => e.className).toSet().length}'),
                  _buildStatRow('Competencies', '${_allEntries.fold<int>(0, (sum, e) => sum + e.competences.length)}'),
                  _buildStatRow('Learning Outcomes', '${_allEntries.fold<int>(0, (sum, e) => sum + e.competences.fold<int>(0, (sum, c) => sum + c.learningOutcomes.length))}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('🌳 Hierarchical Navigation', 'Browse by level, subject, class, and topic'),
                  _buildFeatureItem('🔍 Smart Search', 'Full-text search with relevance scoring'),
                  _buildFeatureItem('📚 Detailed Content', 'Complete competencies and learning outcomes'),
                  _buildFeatureItem('🎯 Offline-First', 'Works without internet connection'),
                  _buildFeatureItem('📱 Native Performance', 'Optimized for mobile devices'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

/// Navigation tile widget
class NavigationTile extends StatelessWidget {
  final NavigationNode node;
  final VoidCallback onTap;

  const NavigationTile({
    Key? key,
    required this.node,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (node.type) {
      case NavigationType.level:
        icon = Icons.school;
        color = Colors.blue;
        break;
      case NavigationType.subject:
        icon = Icons.book;
        color = Colors.green;
        break;
      case NavigationType.class_:
        icon = Icons.people;
        color = Colors.orange;
        break;
      case NavigationType.topic:
        icon = Icons.description;
        color = Colors.purple;
        break;
      default:
        icon = Icons.folder;
        color = Colors.grey;
    }

    final entryCount = node.data['entryCount'] as int?;
    final hasChildren = node.children.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(26),
          child: Icon(icon, color: color),
        ),
        title: Text(node.title),
        subtitle: entryCount != null ? Text('$entryCount entries') : null,
        trailing: hasChildren ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}

/// Search result tile widget
class SearchResultTile extends StatelessWidget {
  final SearchResult result;

  const SearchResultTile({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entry = result.entry;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: const Icon(Icons.description, color: Colors.indigo),
        ),
        title: Text(entry.topic),
        subtitle: Text('${entry.subject} • ${entry.level} • ${entry.className}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.strand.isNotEmpty) ...[
                  Text(
                    'Strand: ${entry.strand}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
                if (result.matchedFields.isNotEmpty) ...[
                  Text(
                    'Matched in: ${result.matchedFields.join(', ')}',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Relevance: ${(result.relevanceScore * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TopicDetailView(entry: entry),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Topic detail view widget
class TopicDetailView extends StatelessWidget {
  final SyllabusEntry entry;

  const TopicDetailView({
    Key? key,
    required this.entry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.suggestedPeriods != null) ...[
          _buildInfoChip('Periods', '${entry.suggestedPeriods}'),
          const SizedBox(height: 8),
        ],
        ...entry.competences.map((competence) => _buildCompetenceCard(competence)),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('$label: $value'),
    );
  }

  Widget _buildCompetenceCard(Competence competence) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Competency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(competence.text),
            const SizedBox(height: 12),
            if (competence.learningOutcomes.isNotEmpty) ...[
              const Text(
                'Learning Outcomes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...competence.learningOutcomes.map((outcome) => _buildOutcomeItem(outcome)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutcomeItem(LearningOutcome outcome) {
    Color typeColor;
    IconData typeIcon;
    
    switch (outcome.outcomeType) {
      case 'skill':
        typeColor = Colors.green;
        typeIcon = Icons.build;
        break;
      case 'knowledge':
        typeColor = Colors.blue;
        typeIcon = Icons.psychology;
        break;
      case 'value':
        typeColor = Colors.purple;
        typeIcon = Icons.favorite;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(typeIcon, color: typeColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              outcome.text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
