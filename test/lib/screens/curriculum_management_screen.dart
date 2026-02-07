import 'package:flutter/material.dart';
import '../services/curriculum_database_service.dart';
import '../services/curriculum_data_ingestion_service.dart';
import '../models/enhanced_curriculum_models.dart';
import '../models/curriculum_models.dart';
import 'curriculum_subject_detail_screen.dart';
import 'curriculum_topic_detail_screen.dart';

/// Main Curriculum Management Screen
class CurriculumManagementScreen extends StatefulWidget {
  const CurriculumManagementScreen({super.key});

  @override
  _CurriculumManagementScreenState createState() =>
      _CurriculumManagementScreenState();
}

class _CurriculumManagementScreenState extends State<CurriculumManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<EnhancedSubject> _subjects = [];
  List<EnhancedSubject> _filteredSubjects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedLevel = 'All';
  bool _isIngesting = false;
  String _ingestionProgress = '';
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final subjects = await CurriculumDatabaseService.getAllSubjects();
      final statistics =
          await CurriculumDatabaseService.getCurriculumStatistics();

      setState(() {
        _subjects = subjects
            .map((s) => EnhancedSubject(
                  id: s.id,
                  name: s.name,
                  educationLevel: s.educationLevel,
                  classNames: [s.className],
                  periodDuration: s.periodDuration,
                  periodsPerWeek: s.periodsPerWeek,
                  createdAt: s.createdAt,
                ))
            .cast<EnhancedSubject>()
            .toList();
        _filteredSubjects = _subjects;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _filterSubjects() {
    setState(() {
      _filteredSubjects = _subjects.where((subject) {
        final matchesSearch =
            subject.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesLevel =
            _selectedLevel == 'All' || subject.educationLevel == _selectedLevel;
        return matchesSearch && matchesLevel;
      }).toList();
    });
  }

  Future<void> _startDataIngestion() async {
    setState(() {
      _isIngesting = true;
      _ingestionProgress = 'Starting data ingestion...';
    });

    try {
      final results =
          await CurriculumDataIngestionService.ingestAllCurriculumData(
        forceRebuild: true,
        onProgress: (progress) {
          setState(() {
            _ingestionProgress = progress;
          });
        },
      );

      setState(() {
        _isIngesting = false;
        _ingestionProgress = 'Ingestion completed!';
      });

      // Reload data
      await _loadData();

      // Show results
      _showIngestionResults(results);
    } catch (e) {
      setState(() {
        _isIngesting = false;
        _ingestionProgress = 'Error: $e';
      });
    }
  }

  void _showIngestionResults(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Ingestion Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Subjects: ${results['subjects']}'),
              Text('Strands: ${results['strands']}'),
              Text('Topics: ${results['topics']}'),
              Text('Learning Outcomes: ${results['learningOutcomes']}'),
              Text('Activities: ${results['activities']}'),
              Text('Materials: ${results['materials']}'),
              Text('Assessments: ${results['assessments']}'),
              if (results['errors'].isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Errors:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...results['errors'].map<Widget>((error) => Text('• $error')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curriculum Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: 'Subjects'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
            Tab(icon: Icon(Icons.upload_file), text: 'Data Ingestion'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubjectsTab(),
          _buildStatisticsTab(),
          _buildDataIngestionTab(),
          _buildSearchTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjectsTab() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredSubjects.isEmpty
                  ? const Center(child: Text('No subjects found'))
                  : ListView.builder(
                      itemCount: _filteredSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = _filteredSubjects[index];
                        return _buildSubjectCard(subject);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search subjects...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _filterSubjects();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Level: '),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedLevel,
                  isExpanded: true,
                  items: ['All', 'Advanced Secondary', 'Lower Secondary']
                      .map((level) {
                    return DropdownMenuItem(value: level, child: Text(level));
                  }).toList(),
                  onChanged: (value) {
                    _selectedLevel = value!;
                    _filterSubjects();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(EnhancedSubject subject) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(subject.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level: ${subject.educationLevel}'),
            if (subject.periodsPerWeek != null)
              Text('Periods per week: ${subject.periodsPerWeek}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: const [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: const [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CurriculumSubjectDetailScreen(subject: subject),
                  ),
                );
                break;
              case 'edit':
                _showEditSubjectDialog(subject);
                break;
              case 'delete':
                _showDeleteSubjectDialog(subject);
                break;
            }
          },
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  CurriculumSubjectDetailScreen(subject: subject),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Curriculum Statistics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                    'Subjects',
                    _statistics['subjects']?.toString() ?? '0',
                    Icons.book,
                    Colors.blue),
                _buildStatCard(
                    'Strands',
                    _statistics['strands']?.toString() ?? '0',
                    Icons.category,
                    Colors.green),
                _buildStatCard(
                    'Topics',
                    _statistics['topics']?.toString() ?? '0',
                    Icons.topic,
                    Colors.orange),
                _buildStatCard(
                    'Learning Outcomes',
                    _statistics['learningOutcomes']?.toString() ?? '0',
                    Icons.check_circle,
                    Colors.purple),
                _buildStatCard(
                    'Activities',
                    _statistics['activities']?.toString() ?? '0',
                    Icons.play_lesson,
                    Colors.red),
                _buildStatCard(
                    'Materials',
                    _statistics['materials']?.toString() ?? '0',
                    Icons.inventory,
                    Colors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataIngestionTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Data Ingestion',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Import curriculum data from cleaned markdown files. This will process all A-Level and O-Level syllabus files and populate the database with structured curriculum data.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isIngesting ? null : _startDataIngestion,
            icon: _isIngesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload),
            label: Text(_isIngesting ? 'Ingesting...' : 'Start Data Ingestion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          if (_ingestionProgress.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_ingestionProgress),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search curriculum...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (query) {
              if (query.isNotEmpty) {
                _performSearch(query);
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Search for topics, competencies, learning outcomes, and other curriculum content across all subjects.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    try {
      final topics = await CurriculumDatabaseService.searchTopics(query);
      final enhancedTopics = topics
          .map((t) => EnhancedTopic(
                id: t.id,
                strandId: t.strandId,
                name: t.name,
                code: t.code,
                description: t.description,
                competency: t.competency ?? '',
                durationPeriods: t.durationPeriods,
                term: t.term,
                className: t.className,
                orderIndex: t.orderIndex,
              ))
          .toList();

      if (enhancedTopics.isNotEmpty) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CurriculumSearchResultsScreen(
              query: query,
              topics: enhancedTopics,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    }
  }

  void _showAddSubjectDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedLevel = 'Advanced Secondary';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Education Level',
                  border: OutlineInputBorder(),
                ),
                items: ['Advanced Secondary', 'Lower Secondary'].map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) {
                  selectedLevel = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final subject = EnhancedSubject(
                  name: nameController.text,
                  educationLevel: selectedLevel,
                  description: descriptionController.text,
                );

                try {
                  await CurriculumDatabaseService.insertEnhancedSubject(
                      subject);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subject added successfully')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding subject: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSubjectDialog(EnhancedSubject subject) {
    final nameController = TextEditingController(text: subject.name);
    final descriptionController =
        TextEditingController(text: subject.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final updatedSubject = EnhancedSubject(
                  id: subject.id,
                  name: nameController.text,
                  educationLevel: subject.educationLevel,
                  description: descriptionController.text,
                  rationale: subject.rationale,
                  periodDuration: subject.periodDuration,
                  periodsPerWeek: subject.periodsPerWeek,
                  classNames: subject.classNames,
                );

                try {
                  // Convert EnhancedSubject back to Subject for database update
                  final subjectForUpdate = Subject(
                    id: updatedSubject.id,
                    name: updatedSubject.name,
                    educationLevel: updatedSubject.educationLevel,
                    className: updatedSubject.classNames?.first ?? 'Unknown',
                    periodDuration: updatedSubject.periodDuration,
                    periodsPerWeek: updatedSubject.periodsPerWeek,
                    createdAt: updatedSubject.createdAt,
                  );
                  await CurriculumDatabaseService.updateSubject(
                      subjectForUpdate);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Subject updated successfully')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating subject: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubjectDialog(EnhancedSubject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
            'Are you sure you want to delete "${subject.name}"? This will also delete all associated strands, topics, and learning outcomes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await CurriculumDatabaseService.deleteSubject(subject.id!);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject deleted successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting subject: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Search Results Screen
class CurriculumSearchResultsScreen extends StatelessWidget {
  final String query;
  final List<EnhancedTopic> topics;

  const CurriculumSearchResultsScreen({
    Key? key,
    required this.query,
    required this.topics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results: "$query"'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];
          return ListTile(
            title: Text(topic.name),
            subtitle: Text(topic.competency),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      CurriculumTopicDetailScreen(topic: topic),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
