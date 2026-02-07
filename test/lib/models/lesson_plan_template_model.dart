class LessonPlanTemplate {
  final String id;
  final String name;
  final String description;
  final String duration;
  final String teachingStyle;
  final List<String> learningObjectives;
  final List<Map<String, dynamic>> activities;
  final List<String> materials;
  final Map<String, dynamic> assessment;
  final String category;
  final List<String> applicableSubjects;
  final DateTime createdAt;
  final bool isDefault;

  LessonPlanTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.teachingStyle,
    required this.learningObjectives,
    required this.activities,
    required this.materials,
    required this.assessment,
    required this.category,
    required this.applicableSubjects,
    required this.createdAt,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'teaching_style': teachingStyle,
      'learning_objectives': learningObjectives,
      'activities': activities,
      'materials': materials,
      'assessment': assessment,
      'category': category,
      'applicable_subjects': applicableSubjects,
      'created_at': createdAt.toIso8601String(),
      'is_default': isDefault,
    };
  }

  factory LessonPlanTemplate.fromMap(Map<String, dynamic> map) {
    return LessonPlanTemplate(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      duration: map['duration'],
      teachingStyle: map['teaching_style'],
      learningObjectives: List<String>.from(map['learning_objectives']),
      activities: List<Map<String, dynamic>>.from(map['activities']),
      materials: List<String>.from(map['materials']),
      assessment: Map<String, dynamic>.from(map['assessment']),
      category: map['category'],
      applicableSubjects: List<String>.from(map['applicable_subjects']),
      createdAt: DateTime.parse(map['created_at']),
      isDefault: map['is_default'] ?? false,
    );
  }
}

class LessonPlanTemplateService {
  static final LessonPlanTemplateService _instance =
      LessonPlanTemplateService._internal();
  factory LessonPlanTemplateService() => _instance;
  LessonPlanTemplateService._internal();

  List<LessonPlanTemplate> _templates = [];

  List<LessonPlanTemplate> getTemplates() {
    if (_templates.isEmpty) {
      _initializeDefaultTemplates();
    }
    return _templates;
  }

  LessonPlanTemplate? getTemplateById(String id) {
    return _templates.firstWhere((template) => template.id == id);
  }

  List<LessonPlanTemplate> getTemplatesByCategory(String category) {
    return _templates
        .where((template) => template.category == category)
        .toList();
  }

  List<LessonPlanTemplate> getTemplatesBySubject(String subject) {
    return _templates
        .where((template) =>
            template.applicableSubjects.contains(subject) ||
            template.applicableSubjects.contains('All'))
        .toList();
  }

  void _initializeDefaultTemplates() {
    _templates = [
      // Interactive Learning Templates
      LessonPlanTemplate(
        id: 'interactive_40min',
        name: 'Interactive 40-Minute Lesson',
        description:
            'Engaging lesson with student participation and hands-on activities',
        duration: '40 minutes',
        teachingStyle: 'Interactive',
        learningObjectives: [
          'Engage students through active participation',
          'Facilitate collaborative learning',
          'Provide immediate feedback',
        ],
        activities: [
          {
            'name': 'Hook & Introduction',
            'duration': 5,
            'type': 'introduction',
            'description':
                'Start with an engaging question or real-world scenario',
            'resources': ['Whiteboard', 'Visual aids'],
          },
          {
            'name': 'Interactive Exploration',
            'duration': 20,
            'type': 'collaborative',
            'description': 'Students work in groups to explore concepts',
            'resources': ['Worksheet', 'Group materials'],
          },
          {
            'name': 'Share & Discuss',
            'duration': 10,
            'type': 'discussion',
            'description': 'Groups share findings and class discusses',
            'resources': ['Presentation space'],
          },
          {
            'name': 'Quick Assessment',
            'duration': 5,
            'type': 'assessment',
            'description': 'Exit ticket or quick quiz',
            'resources': ['Assessment tools'],
          },
        ],
        materials: [
          'Whiteboard',
          'Markers',
          'Worksheet',
          'Timer',
          'Visual aids'
        ],
        assessment: {
          'type': 'formative',
          'methods': ['Exit ticket', 'Observation', 'Quick quiz'],
          'criteria': ['Participation', 'Understanding', 'Collaboration'],
        },
        category: 'Interactive',
        applicableSubjects: ['All'],
        createdAt: DateTime.now(),
        isDefault: true,
      ),

      // Direct Instruction Templates
      LessonPlanTemplate(
        id: 'direct_60min',
        name: 'Direct Instruction 60-Minute Lesson',
        description:
            'Teacher-centered lesson with clear explanations and guided practice',
        duration: '60 minutes',
        teachingStyle: 'Direct Instruction',
        learningObjectives: [
          'Present new concepts clearly',
          'Provide structured learning',
          'Ensure mastery through practice',
        ],
        activities: [
          {
            'name': 'Introduction & Objectives',
            'duration': 5,
            'type': 'introduction',
            'description':
                'State learning objectives and connect to prior knowledge',
            'resources': ['Whiteboard', 'Lesson objectives'],
          },
          {
            'name': 'Direct Instruction',
            'duration': 20,
            'type': 'lecture',
            'description': 'Teacher presents new content with examples',
            'resources': ['Presentation slides', 'Whiteboard'],
          },
          {
            'name': 'Guided Practice',
            'duration': 20,
            'type': 'guided_practice',
            'description': 'Work through examples together as a class',
            'resources': ['Practice problems', 'Answer keys'],
          },
          {
            'name': 'Independent Practice',
            'duration': 10,
            'type': 'independent',
            'description': 'Students practice independently',
            'resources': ['Worksheet', 'Answer keys'],
          },
          {
            'name': 'Assessment & Closure',
            'duration': 5,
            'type': 'assessment',
            'description': 'Check understanding and summarize',
            'resources': ['Quiz materials'],
          },
        ],
        materials: [
          'Presentation slides',
          'Whiteboard',
          'Markers',
          'Worksheet',
          'Answer keys'
        ],
        assessment: {
          'type': 'summative',
          'methods': ['Quiz', 'Worksheet completion', 'Observation'],
          'criteria': ['Accuracy', 'Completion', 'Understanding'],
        },
        category: 'Direct Instruction',
        applicableSubjects: ['All'],
        createdAt: DateTime.now(),
        isDefault: true,
      ),

      // Science Lab Templates
      LessonPlanTemplate(
        id: 'lab_80min',
        name: 'Laboratory Investigation 80-Minute Lesson',
        description:
            'Hands-on scientific investigation with experiment and analysis',
        duration: '80 minutes',
        teachingStyle: 'Hands-on Learning',
        learningObjectives: [
          'Conduct scientific investigations',
          'Apply scientific method',
          'Analyze experimental data',
          'Draw evidence-based conclusions',
        ],
        activities: [
          {
            'name': 'Safety Briefing & Introduction',
            'duration': 10,
            'type': 'introduction',
            'description':
                'Review safety procedures and introduce investigation',
            'resources': ['Safety equipment', 'Investigation sheet'],
          },
          {
            'name': 'Background Knowledge',
            'duration': 15,
            'type': 'lecture',
            'description': 'Explain scientific concepts and procedures',
            'resources': ['Presentation slides', 'Textbook'],
          },
          {
            'name': 'Experiment Setup',
            'duration': 20,
            'type': 'practical',
            'description': 'Students set up and conduct experiments',
            'resources': ['Lab equipment', 'Materials', 'Safety gear'],
          },
          {
            'name': 'Data Collection & Analysis',
            'duration': 20,
            'type': 'analysis',
            'description': 'Record and analyze experimental data',
            'resources': ['Data sheets', 'Calculators', 'Graph paper'],
          },
          {
            'name': 'Conclusion & Cleanup',
            'duration': 15,
            'type': 'conclusion',
            'description': 'Discuss findings and clean up',
            'resources': ['Discussion prompts', 'Cleaning supplies'],
          },
        ],
        materials: [
          'Laboratory equipment',
          'Safety gear',
          'Investigation sheets',
          'Data sheets',
          'Calculators',
          'Graph paper',
          'Cleaning supplies'
        ],
        assessment: {
          'type': 'performance',
          'methods': ['Lab report', 'Observation', 'Data analysis'],
          'criteria': [
            'Procedure accuracy',
            'Data quality',
            'Analysis depth',
            'Safety compliance'
          ],
        },
        category: 'Science Lab',
        applicableSubjects: ['Chemistry', 'Biology', 'Physics'],
        createdAt: DateTime.now(),
        isDefault: true,
      ),

      // Language Arts Templates
      LessonPlanTemplate(
        id: 'language_40min',
        name: 'Language Arts 40-Minute Lesson',
        description: 'Reading comprehension and writing skills development',
        duration: '40 minutes',
        teachingStyle: 'Collaborative',
        learningObjectives: [
          'Improve reading comprehension',
          'Develop writing skills',
          'Enhance vocabulary',
          'Practice communication skills',
        ],
        activities: [
          {
            'name': 'Warm-up Reading',
            'duration': 5,
            'type': 'reading',
            'description': 'Short reading passage to engage students',
            'resources': ['Reading passage', 'Timer'],
          },
          {
            'name': 'Vocabulary Building',
            'duration': 10,
            'type': 'vocabulary',
            'description': 'Introduce and practice new vocabulary',
            'resources': ['Vocabulary cards', 'Dictionary'],
          },
          {
            'name': 'Reading Comprehension',
            'duration': 15,
            'type': 'reading',
            'description': 'Read and analyze text with comprehension questions',
            'resources': ['Text', 'Comprehension questions'],
          },
          {
            'name': 'Writing Practice',
            'duration': 8,
            'type': 'writing',
            'description': 'Short writing activity related to reading',
            'resources': ['Writing paper', 'Writing prompts'],
          },
          {
            'name': 'Share & Reflect',
            'duration': 2,
            'type': 'discussion',
            'description': 'Quick share of writing',
            'resources': ['Share space'],
          },
        ],
        materials: [
          'Reading passages',
          'Vocabulary cards',
          'Textbooks',
          'Writing paper',
          'Dictionary'
        ],
        assessment: {
          'type': 'formative',
          'methods': [
            'Reading comprehension',
            'Writing sample',
            'Vocabulary quiz'
          ],
          'criteria': [
            'Comprehension accuracy',
            'Writing quality',
            'Vocabulary usage'
          ],
        },
        category: 'Language Arts',
        applicableSubjects: ['English', 'Literature'],
        createdAt: DateTime.now(),
        isDefault: true,
      ),

      // Mathematics Templates
      LessonPlanTemplate(
        id: 'math_60min',
        name: 'Mathematics 60-Minute Lesson',
        description:
            'Problem-based mathematics lesson with conceptual understanding',
        duration: '60 minutes',
        teachingStyle: 'Mixed Methods',
        learningObjectives: [
          'Understand mathematical concepts',
          'Apply problem-solving strategies',
          'Practice mathematical skills',
          'Connect math to real-world applications',
        ],
        activities: [
          {
            'name': 'Math Warm-up',
            'duration': 5,
            'type': 'practice',
            'description': 'Quick mental math or review problems',
            'resources': ['Warm-up problems', 'Timer'],
          },
          {
            'name': 'Concept Introduction',
            'duration': 15,
            'type': 'lecture',
            'description': 'Introduce new mathematical concept with examples',
            'resources': ['Whiteboard', 'Visual aids', 'Manipulatives'],
          },
          {
            'name': 'Guided Problem Solving',
            'duration': 20,
            'type': 'problem_solving',
            'description': 'Work through problems together as a class',
            'resources': ['Problem sets', 'Answer keys', 'Calculator'],
          },
          {
            'name': 'Independent Practice',
            'duration': 15,
            'type': 'independent',
            'description': 'Students solve problems independently',
            'resources': ['Worksheet', 'Calculator'],
          },
          {
            'name': 'Application & Extension',
            'duration': 5,
            'type': 'application',
            'description': 'Real-world application or extension activity',
            'resources': ['Application problems', 'Extension materials'],
          },
        ],
        materials: [
          'Whiteboard',
          'Markers',
          'Calculator',
          'Manipulatives',
          'Worksheet',
          'Textbook'
        ],
        assessment: {
          'type': 'mixed',
          'methods': ['Problem solving', 'Quiz', 'Observation'],
          'criteria': ['Accuracy', 'Method', 'Understanding', 'Application'],
        },
        category: 'Mathematics',
        applicableSubjects: ['Mathematics', 'Statistics'],
        createdAt: DateTime.now(),
        isDefault: true,
      ),

      // Project-Based Templates
      LessonPlanTemplate(
        id: 'project_120min',
        name: 'Project-Based Learning 120-Minute Lesson',
        description:
            'Extended project work with research, creation, and presentation',
        duration: '120 minutes',
        teachingStyle: 'Collaborative',
        learningObjectives: [
          'Develop research skills',
          'Create original work',
          'Collaborate effectively',
          'Present findings clearly',
          'Manage time and resources',
        ],
        activities: [
          {
            'name': 'Project Introduction',
            'duration': 10,
            'type': 'introduction',
            'description': 'Introduce project requirements and timeline',
            'resources': ['Project guidelines', 'Rubric'],
          },
          {
            'name': 'Team Formation & Planning',
            'duration': 15,
            'type': 'planning',
            'description': 'Form teams and plan project approach',
            'resources': ['Planning sheets', 'Team roles'],
          },
          {
            'name': 'Research & Development',
            'duration': 45,
            'type': 'research',
            'description': 'Research and create project deliverables',
            'resources': ['Research materials', 'Creation tools'],
          },
          {
            'name': 'Project Assembly',
            'duration': 20,
            'type': 'creation',
            'description': 'Assemble final project components',
            'resources': ['Assembly materials', 'Presentation tools'],
          },
          {
            'name': 'Presentations & Feedback',
            'duration': 25,
            'type': 'presentation',
            'description': 'Present projects and provide peer feedback',
            'resources': ['Presentation space', 'Feedback forms'],
          },
          {
            'name': 'Reflection & Assessment',
            'duration': 5,
            'type': 'reflection',
            'description': 'Reflect on learning and process',
            'resources': ['Reflection sheets'],
          },
        ],
        materials: [
          'Project guidelines',
          'Rubrics',
          'Research materials',
          'Creation tools',
          'Presentation equipment',
          'Feedback forms'
        ],
        assessment: {
          'type': 'performance',
          'methods': [
            'Project rubric',
            'Presentation',
            'Peer evaluation',
            'Self-reflection'
          ],
          'criteria': [
            'Content quality',
            'Creativity',
            'Collaboration',
            'Presentation skills',
            'Process'
          ],
        },
        category: 'Project-Based',
        applicableSubjects: ['All'],
        createdAt: DateTime.now(),
        isDefault: true,
      ),
    ];
  }

  Future<void> addTemplate(LessonPlanTemplate template) async {
    _templates.add(template);
  }

  Future<void> updateTemplate(LessonPlanTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _templates[index] = template;
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    _templates.removeWhere((template) => template.id == templateId);
  }
}
