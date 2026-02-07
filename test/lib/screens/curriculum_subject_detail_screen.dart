import 'package:flutter/material.dart';
import '../services/curriculum_database_service.dart';
import '../models/enhanced_curriculum_models.dart';
import '../models/curriculum_models.dart';
import 'curriculum_topic_detail_screen.dart';

/// Subject Detail Screen
class CurriculumSubjectDetailScreen extends StatefulWidget {
  final EnhancedSubject subject;

  const CurriculumSubjectDetailScreen({Key? key, required this.subject}) : super(key: key);

  @override
  _CurriculumSubjectDetailScreenState createState() => _CurriculumSubjectDetailScreenState();
}

class _CurriculumSubjectDetailScreenState extends State<CurriculumSubjectDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<EnhancedStrand> _strands = [];
  List<EnhancedTopic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSubjectData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjectData() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.subject.id != null) {
        final strands = await CurriculumDatabaseService.getStrandsBySubject(widget.subject.id!);
        final topics = await CurriculumDatabaseService.getTopicsBySubject(widget.subject.id!);
        
        setState(() {
          _strands = strands.map((s) => EnhancedStrand(
            id: s.id,
            subjectId: s.subjectId,
            name: s.name,
            code: s.code,
            description: s.description,
            orderIndex: s.orderIndex,
          )).toList();
          _topics = topics.map((t) => EnhancedTopic(
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
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subject data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Overview'),
            Tab(icon: Icon(Icons.category), text: 'Strands'),
            Tab(icon: Icon(Icons.topic), text: 'Topics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildStrandsTab(),
          _buildTopicsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStrandDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Name', widget.subject.name),
                  _buildInfoRow('Education Level', widget.subject.educationLevel),
                  if (widget.subject.periodsPerWeek != null)
                    _buildInfoRow('Periods per Week', widget.subject.periodsPerWeek.toString()),
                  if (widget.subject.periodDuration != null)
                    _buildInfoRow('Period Duration', '${widget.subject.periodDuration} minutes'),
                  if (widget.subject.classNames != null)
                    _buildInfoRow('Classes', widget.subject.classNames!.join(', ')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.subject.description != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.subject.description!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.subject.rationale != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rationale',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.subject.rationale!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStrandsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _strands.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No strands found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    Text('Add strands to organize your curriculum content'),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _strands.length,
                itemBuilder: (context, index) {
                  final strand = _strands[index];
                  return _buildStrandCard(strand);
                },
              );
  }

  Widget _buildStrandCard(EnhancedStrand strand) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(strand.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (strand.term != null) Text('Term: ${strand.term}'),
            if (strand.seniorLevel != null) Text('Class: ${strand.seniorLevel}'),
            if (strand.durationPeriods != null) 
              Text('Duration: ${strand.durationPeriods} periods'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
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
              case 'edit':
                _showEditStrandDialog(strand);
                break;
              case 'delete':
                _showDeleteStrandDialog(strand);
                break;
            }
          },
        ),
        onTap: () {
          // Navigate to strand detail (could implement strand detail screen)
        },
      ),
    );
  }

  Widget _buildTopicsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _topics.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.topic_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No topics found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    Text('Add topics to strands to populate this list'),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _topics.length,
                itemBuilder: (context, index) {
                  final topic = _topics[index];
                  return _buildTopicCard(topic);
                },
              );
  }

  Widget _buildTopicCard(EnhancedTopic topic) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(topic.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(topic.competency),
            if (topic.durationPeriods != null) 
              Text('Duration: ${topic.durationPeriods} periods'),
            if (topic.className != null) 
              Text('Class: ${topic.className}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CurriculumTopicDetailScreen(topic: topic),
            ),
          );
        },
      ),
    );
  }

  void _showAddStrandDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final termController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Strand'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Strand Name',
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
              TextField(
                controller: termController,
                decoration: const InputDecoration(
                  labelText: 'Term (e.g., TERM 1)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (periods)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
              if (nameController.text.isNotEmpty && widget.subject.id != null) {
                final strand = EnhancedStrand(
                  subjectId: widget.subject.id!,
                  name: nameController.text,
                  description: descriptionController.text,
                  term: termController.text,
                  durationPeriods: int.tryParse(durationController.text),
                );
                
                try {
                  await CurriculumDatabaseService.insertEnhancedStrand(strand);
                  Navigator.of(context).pop();
                  _loadSubjectData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Strand added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding strand: $e')),
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

  void _showEditStrandDialog(EnhancedStrand strand) {
    final nameController = TextEditingController(text: strand.name);
    final descriptionController = TextEditingController(text: strand.description ?? '');
    final termController = TextEditingController(text: strand.term ?? '');
    final durationController = TextEditingController(text: strand.durationPeriods?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Strand'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Strand Name',
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
              TextField(
                controller: termController,
                decoration: const InputDecoration(
                  labelText: 'Term (e.g., TERM 1)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (periods)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
              if (nameController.text.isNotEmpty && strand.id != null) {
                final updatedStrand = EnhancedStrand(
                  id: strand.id,
                  subjectId: strand.subjectId,
                  name: nameController.text,
                  description: descriptionController.text,
                  term: termController.text,
                  durationPeriods: int.tryParse(durationController.text),
                  seniorLevel: strand.seniorLevel,
                  orderIndex: strand.orderIndex,
                );
                
                try {
                  // Convert EnhancedStrand back to Strand for database update
                  final strandForUpdate = Strand(
                    id: updatedStrand.id,
                    subjectId: updatedStrand.subjectId,
                    name: updatedStrand.name,
                    code: updatedStrand.code,
                    description: updatedStrand.description,
                    orderIndex: updatedStrand.orderIndex,
                  );
                  await CurriculumDatabaseService.updateStrand(strandForUpdate);
                  Navigator.of(context).pop();
                  _loadSubjectData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Strand updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating strand: $e')),
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

  void _showDeleteStrandDialog(EnhancedStrand strand) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Strand'),
        content: Text('Are you sure you want to delete "${strand.name}"? This will also delete all associated topics and learning outcomes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (strand.id != null) {
                try {
                  await CurriculumDatabaseService.deleteStrand(strand.id!);
                  Navigator.of(context).pop();
                  _loadSubjectData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Strand deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting strand: $e')),
                  );
                }
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
