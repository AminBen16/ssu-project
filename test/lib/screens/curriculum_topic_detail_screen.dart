import 'package:flutter/material.dart';
import '../services/curriculum_database_service.dart';
import '../models/enhanced_curriculum_models.dart';
import '../models/curriculum_models.dart';

/// Topic Detail Screen
class CurriculumTopicDetailScreen extends StatefulWidget {
  final EnhancedTopic topic;

  const CurriculumTopicDetailScreen({super.key, required this.topic});

  @override
  _CurriculumTopicDetailScreenState createState() => _CurriculumTopicDetailScreenState();
}

class _CurriculumTopicDetailScreenState extends State<CurriculumTopicDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<LearningOutcome> _learningOutcomes = [];
  List<SuggestedActivity> _activities = [];
  List<AssessmentStrategy> _assessments = [];
  List<EnhancedMaterial> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTopicData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTopicData() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.topic.id != null) {
        final learningOutcomes = await CurriculumDatabaseService.getLearningOutcomesByTopic(widget.topic.id!);
        
        // Load related data for each learning outcome
        final activities = <SuggestedActivity>[];
        final materials = <EnhancedMaterial>[];
        final assessments = <AssessmentStrategy>[];
        
        for (final outcome in learningOutcomes) {
          if (outcome.id != null) {
            final outcomeActivities = await CurriculumDatabaseService.getActivitiesByLearningOutcome(outcome.id!);
            final outcomeMaterials = await CurriculumDatabaseService.getMaterialsByLearningOutcome(outcome.id!);
            final outcomeAssessments = await CurriculumDatabaseService.getAssessmentsByLearningOutcome(outcome.id!);
            
            activities.addAll(outcomeActivities);
            materials.addAll(outcomeMaterials);
            assessments.addAll(outcomeAssessments);
          }
        }
        
        setState(() {
          _learningOutcomes = learningOutcomes;
          _activities = activities;
          _materials = materials;
          _assessments = assessments;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading topic data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic.name),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Overview'),
            Tab(icon: Icon(Icons.check_circle), text: 'Outcomes'),
            Tab(icon: Icon(Icons.play_lesson), text: 'Activities'),
            Tab(icon: Icon(Icons.quiz), text: 'Assessments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildLearningOutcomesTab(),
          _buildActivitiesTab(),
          _buildAssessmentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLearningOutcomeDialog,
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
                    'Topic Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Name', widget.topic.name),
                  _buildInfoRow('Competency', widget.topic.competency),
                  if (widget.topic.durationPeriods != null)
                    _buildInfoRow('Duration', '${widget.topic.durationPeriods} periods'),
                  if (widget.topic.className != null)
                    _buildInfoRow('Class', widget.topic.className!),
                  if (widget.topic.term != null)
                    _buildInfoRow('Term', widget.topic.term!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.topic.description != null) ...[
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
                    Text(widget.topic.description!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildStatisticsCard(),
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
            width: 100,
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

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Learning Outcomes',
                    _learningOutcomes.length.toString(),
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Activities',
                    _activities.length.toString(),
                    Icons.play_lesson,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Materials',
                    _materials.length.toString(),
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Assessments',
                    _assessments.length.toString(),
                    Icons.quiz,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningOutcomesTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _learningOutcomes.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No learning outcomes found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    Text('Add learning outcomes to define what students should achieve'),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _learningOutcomes.length,
                itemBuilder: (context, index) {
                  final outcome = _learningOutcomes[index];
                  return _buildLearningOutcomeCard(outcome);
                },
              );
  }

  Widget _buildLearningOutcomeCard(LearningOutcome outcome) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          'Learning Outcome ${outcome.orderIndex != null ? outcome.orderIndex! + 1 : ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(outcome.outcomeText),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (outcome.outcomeType != null) ...[
                  _buildDetailRow('Type', outcome.outcomeType!),
                  const SizedBox(height: 8),
                ],
                if (outcome.lessonUnit != null) ...[
                  _buildDetailRow('Lesson Unit', outcome.lessonUnit!),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Full Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(outcome.outcomeText),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showEditLearningOutcomeDialog(outcome),
                      child: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: () => _showDeleteLearningOutcomeDialog(outcome),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildActivitiesTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _activities.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_lesson_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No activities found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    Text('Activities will appear here when added to learning outcomes'),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final activity = _activities[index];
                  return _buildActivityCard(activity);
                },
              );
  }

  Widget _buildActivityCard(SuggestedActivity activity) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(activity.activity),
        subtitle: activity.descriptionText != null 
            ? Text(activity.descriptionText!)
            : null,
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
                _showEditActivityDialog(activity);
                break;
              case 'delete':
                _showDeleteActivityDialog(activity);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildAssessmentsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _assessments.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No assessments found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    Text('Assessments will appear here when added to learning outcomes'),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _assessments.length,
                itemBuilder: (context, index) {
                  final assessment = _assessments[index];
                  return _buildAssessmentCard(assessment);
                },
              );
  }

  Widget _buildAssessmentCard(AssessmentStrategy assessment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(assessment.strategy),
        subtitle: assessment.strategy.isNotEmpty ? Text(assessment.strategy) : null,
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
                _showEditAssessmentDialog(assessment);
                break;
              case 'delete':
                _showDeleteAssessmentDialog(assessment);
                break;
            }
          },
        ),
      ),
    );
  }

  void _showAddLearningOutcomeDialog() {
    final textController = TextEditingController();
    final typeController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Learning Outcome'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Learning Outcome Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Outcome Type (Knowledge, Skills, Attitudes, Values)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Lesson Unit',
                  border: OutlineInputBorder(),
                ),
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
              if (textController.text.isNotEmpty && widget.topic.id != null) {
                final learningOutcome = LearningOutcome(
                  topicId: widget.topic.id!,
                  outcomeText: textController.text,
                  outcomeType: typeController.text,
                  orderIndex: _learningOutcomes.length,
                );
                
                try {
                  await CurriculumDatabaseService.insertLearningOutcome(learningOutcome);
                  Navigator.of(context).pop();
                  _loadTopicData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Learning outcome added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding learning outcome: $e')),
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

  void _showEditLearningOutcomeDialog(LearningOutcome outcome) {
    final textController = TextEditingController(text: outcome.outcomeText);
    final typeController = TextEditingController(text: outcome.outcomeType ?? '');
    final unitController = TextEditingController(text: outcome.lessonUnit ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Learning Outcome'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Learning Outcome Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Outcome Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Lesson Unit',
                  border: OutlineInputBorder(),
                ),
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
              if (textController.text.isNotEmpty && outcome.id != null) {
                final updatedOutcome = LearningOutcome(
                  id: outcome.id,
                  topicId: outcome.topicId,
                  outcomeText: textController.text,
                  outcomeType: typeController.text,
                  lessonUnit: unitController.text,
                  orderIndex: outcome.orderIndex,
                );
                
                try {
                  await CurriculumDatabaseService.updateLearningOutcome(updatedOutcome);
                  Navigator.of(context).pop();
                  _loadTopicData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Learning outcome updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating learning outcome: $e')),
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

  void _showDeleteLearningOutcomeDialog(LearningOutcome outcome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Learning Outcome'),
        content: const Text('Are you sure you want to delete this learning outcome?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (outcome.id != null) {
                try {
                  await CurriculumDatabaseService.deleteLearningOutcome(outcome.id!);
                  Navigator.of(context).pop();
                  _loadTopicData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Learning outcome deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting learning outcome: $e')),
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

  void _showEditActivityDialog(SuggestedActivity activity) {
    final textController = TextEditingController(text: activity.activity);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Activity'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Activity Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty && activity.id != null) {
                final updatedActivity = SuggestedActivity(
                  id: activity.id,
                  learningOutcomeId: activity.learningOutcomeId,
                  activityText: textController.text,
                  orderIndex: activity.orderIndex,
                );
                
                try {
                  await CurriculumDatabaseService.updateActivity(updatedActivity);
                  Navigator.of(context).pop();
                  _loadTopicData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating activity: $e')),
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

  void _showDeleteActivityDialog(SuggestedActivity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (activity.id != null) {
                try {
                  await CurriculumDatabaseService.deleteActivity(activity.id!);
                  Navigator.of(context).pop();
                  _loadTopicData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting activity: $e')),
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

  void _showEditAssessmentDialog(AssessmentStrategy assessment) {
    final textController = TextEditingController(text: assessment.strategy);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Assessment'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Assessment Method',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty && assessment.id != null) {
                final updatedAssessment = AssessmentStrategy(
                  id: assessment.id,
                  learningOutcomeId: assessment.learningOutcomeId,
                  strategyText: textController.text,
                  orderIndex: assessment.orderIndex,
                );
                
                try {
                  await CurriculumDatabaseService.updateAssessment(updatedAssessment);
                  Navigator.of(context).pop();
                  _loadTopicData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assessment updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating assessment: $e')),
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

  void _showDeleteAssessmentDialog(AssessmentStrategy assessment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assessment'),
        content: const Text('Are you sure you want to delete this assessment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (assessment.id != null) {
                try {
                  await CurriculumDatabaseService.deleteActivity(assessment.id!);
                  Navigator.of(context).pop();
                  _loadTopicData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assessment deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting assessment: $e')),
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
