enum SchoolLevel { oLevel, aLevel }

class SubjectPaper {
  final String code;
  final String name;

  const SubjectPaper({required this.code, required this.name});
}

class Subject {
  final String name;
  final String code;
  final SchoolLevel level;
  final List<SubjectPaper> papers;
  final bool isCompulsory;

  const Subject({
    required this.name,
    required this.code,
    required this.level,
    required this.papers,
    this.isCompulsory = false,
  });

  @override
  bool operator ==(Object other) => other is Subject && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// A' LEVEL SUBJECTS
class ALevelSubjects {
  static const List<Subject> all = [
    // --- Compulsory ---
    Subject(
      name: 'General Paper',
      code: 'S101',
      level: SchoolLevel.aLevel,
      papers: [SubjectPaper(code: 'S101/1', name: 'Paper 1')],
      isCompulsory: true,
    ),

    // --- Arts/Humanities ---
    Subject(
      name: 'History',
      code: 'P210',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P210/1', name: 'History of Africa (1885-1994)'),
        SubjectPaper(code: 'P210/2', name: 'History of Europe (1815-1990)'),
        SubjectPaper(code: 'P210/3', name: 'History of Uganda (1890-1990)'),
        SubjectPaper(
          code: 'P210/4',
          name: 'History of West Africa (1850-1990)',
        ),
        SubjectPaper(
          code: 'P210/5',
          name: 'History of East Africa (1885-1994)',
        ),
        SubjectPaper(
          code: 'P210/6',
          name: 'History of Central Africa (1880-1994)',
        ),
      ],
    ),
    Subject(
      name: 'Economics',
      code: 'P220',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P220/1', name: 'Microeconomics'),
        SubjectPaper(code: 'P220/2', name: 'Macroeconomics'),
      ],
    ),
    Subject(
      name: 'Entrepreneurship Education',
      code: 'P230',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P230/1', name: 'Paper 1'),
        SubjectPaper(code: 'P230/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Islamic Religious Education (IRE)',
      code: 'P235',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P235/1', name: 'Paper 1'),
        SubjectPaper(code: 'P235/2', name: 'Paper 2'),
        SubjectPaper(code: 'P235/3', name: 'Paper 3'),
      ],
    ),
    Subject(
      name: 'Christian Religious Education (CRE)',
      code: 'P245',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P245/1', name: 'The Old Testament'),
        SubjectPaper(code: 'P245/2', name: 'The New Testament'),
        SubjectPaper(code: 'P245/3', name: 'Ethics'),
      ],
    ),
    Subject(
      name: 'Geography',
      code: 'P250',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P250/1', name: 'Physical Geography'),
        SubjectPaper(code: 'P250/2', name: 'Human and Regional Geography'),
        SubjectPaper(code: 'P250/3', name: 'Fieldwork and Research'),
      ],
    ),
    Subject(
      name: 'Literature in English',
      code: 'P310',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P310/1', name: 'Paper 1'),
        SubjectPaper(code: 'P310/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Fine Art',
      code: 'P615',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P615/1', name: 'Paper 1'),
        SubjectPaper(code: 'P615/2', name: 'Paper 2'),
        SubjectPaper(code: 'P615/3', name: 'Paper 3'),
        SubjectPaper(code: 'P615/4', name: 'Paper 4'),
        SubjectPaper(code: 'P615/5', name: 'Paper 5'),
      ],
    ),
    Subject(
      name: 'Music',
      code: 'P620',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P620/1', name: 'Paper 1'),
        SubjectPaper(code: 'P620/2', name: 'Paper 2'),
        SubjectPaper(code: 'P620/3', name: 'Paper 3'),
      ],
    ),

    // --- Sciences ---
    Subject(
      name: 'Mathematics',
      code: 'P425',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P425/1', name: 'Paper 1'),
        SubjectPaper(code: 'P425/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Physics',
      code: 'P510',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P510/1', name: 'Paper 1'),
        SubjectPaper(code: 'P510/2', name: 'Paper 2'),
        SubjectPaper(code: 'P510/3', name: 'Practical'),
      ],
    ),
    Subject(
      name: 'Agriculture',
      code: 'P515',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P515/1', name: 'Paper 1'),
        SubjectPaper(code: 'P515/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Chemistry',
      code: 'P525',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P525/1', name: 'Paper 1'),
        SubjectPaper(code: 'P525/2', name: 'Paper 2'),
        SubjectPaper(code: 'P525/3', name: 'Practical'),
      ],
    ),
    Subject(
      name: 'Biology',
      code: 'P530',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P530/1', name: 'Paper 1'),
        SubjectPaper(code: 'P530/2', name: 'Paper 2'),
        SubjectPaper(code: 'P530/3', name: 'Practical'),
      ],
    ),
    Subject(
      name: 'Foods and Nutrition',
      code: 'P640',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P640/1', name: 'Paper 1'),
        SubjectPaper(code: 'P640/2', name: 'Paper 2'),
        SubjectPaper(code: 'P640/3', name: 'Practical'),
      ],
    ),

    // --- Technical ---
    Subject(
      name: 'Geometrical and Mechanical Drawing',
      code: 'P710',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P710/1', name: 'Paper 1'),
        SubjectPaper(code: 'P710/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Geometrical and Building Drawing',
      code: 'P720',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P720/1', name: 'Paper 1'),
        SubjectPaper(code: 'P720/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Woodwork',
      code: 'P730',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P730/1', name: 'Paper 1'),
        SubjectPaper(code: 'P730/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Engineering and Metalwork',
      code: 'P740',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P740/1', name: 'Paper 1'),
        SubjectPaper(code: 'P740/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Clothing and Textiles',
      code: 'P630',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P630/1', name: 'Paper 1'),
        SubjectPaper(code: 'P630/2', name: 'Paper 2'),
        SubjectPaper(code: 'P630/3', name: 'Practical'),
      ],
    ),

    // --- Languages ---
    Subject(
      name: 'Kiswahili',
      code: 'P320',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P320/1', name: 'Paper 1'),
        SubjectPaper(code: 'P320/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'French',
      code: 'P330',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P330/1', name: 'Paper 1'),
        SubjectPaper(code: 'P330/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'German',
      code: 'P340',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P340/1', name: 'Paper 1'),
        SubjectPaper(code: 'P340/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Luganda',
      code: 'P350',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P350/1', name: 'Paper 1'),
        SubjectPaper(code: 'P350/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Latin',
      code: 'P360',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P360/1', name: 'Paper 1'),
        SubjectPaper(code: 'P360/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Arabic',
      code: 'P370',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P370/1', name: 'Paper 1'),
        SubjectPaper(code: 'P370/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Leb Acoli',
      code: 'P361',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P361/1', name: 'Paper 1'),
        SubjectPaper(code: 'P361/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Leb Lango',
      code: 'P362',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P362/1', name: 'Paper 1'),
        SubjectPaper(code: 'P362/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Runyankore/Rukiga',
      code: 'P364',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P364/1', name: 'Paper 1'),
        SubjectPaper(code: 'P364/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Lusoga',
      code: 'P366',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P366/1', name: 'Paper 1'),
        SubjectPaper(code: 'P366/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Ateso',
      code: 'P367',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P367/1', name: 'Paper 1'),
        SubjectPaper(code: 'P367/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Runyoro/Rutooro',
      code: 'P369',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P369/1', name: 'Paper 1'),
        SubjectPaper(code: 'P369/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Lumasaaba',
      code: 'P371',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P371/1', name: 'Paper 1'),
        SubjectPaper(code: 'P371/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Chinese',
      code: 'P372',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'P372/1', name: 'Paper 1'),
        SubjectPaper(code: 'P372/2', name: 'Paper 2'),
      ],
    ),

    // --- Subsidiaries ---
    Subject(
      name: 'Subsidiary ICT',
      code: 'S850',
      level: SchoolLevel.aLevel,
      papers: [
        SubjectPaper(code: 'S850/1', name: 'Paper 1'),
        SubjectPaper(code: 'S850/2', name: 'Paper 2'),
      ],
    ),
    Subject(
      name: 'Subsidiary Mathematics',
      code: 'S475',
      level: SchoolLevel.aLevel,
      papers: [SubjectPaper(code: 'S475/1', name: 'Paper 1')],
    ),
  ];
}

/// O' LEVEL SUBJECTS
class OLevelSubjects {
  static const List<Subject> all = [
    // Compulsory Subjects
    Subject(
      name: 'English Language',
      code: '112',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '112/1', name: 'Paper 1')],
      isCompulsory: true,
    ),
    Subject(
      name: 'Mathematics',
      code: '456',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '456/1', name: 'Paper 1')],
      isCompulsory: true,
    ),
    Subject(
      name: 'History & Political Education',
      code: '241',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '241/1', name: 'Paper 1')],
      isCompulsory: true,
    ),
    Subject(
      name: 'Geography',
      code: '273',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '273/1', name: 'Paper 1')],
      isCompulsory: true,
    ),
    Subject(
      name: 'Physics',
      code: '535',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '535/1', name: 'Theory'),
        SubjectPaper(code: '535/2', name: 'Practical'),
      ],
      isCompulsory: true,
    ),
    Subject(
      name: 'Chemistry',
      code: '545',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '545/1', name: 'Theory'),
        SubjectPaper(code: '545/2', name: 'Practical'),
      ],
      isCompulsory: true,
    ),
    Subject(
      name: 'Biology',
      code: '553',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '553/1', name: 'Theory'),
        SubjectPaper(code: '553/2', name: 'Practical'),
      ],
      isCompulsory: true,
    ),

    // Religious Education (Elective)
    Subject(
      name: 'Christian Religious Education (CRE)',
      code: '223',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '223/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Islamic Religious Education (IRE)',
      code: '225',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '225/1', name: 'Paper 1')],
    ),

    // Other Electives
    Subject(
      name: 'Agriculture',
      code: '527',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '527/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Art and Design',
      code: '610',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '610/1', name: 'Theory'),
        SubjectPaper(code: '610/2', name: 'Practical'),
      ],
    ),
    Subject(
      name: 'Entrepreneurship Education',
      code: '808',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '808/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Information and Communication Technology (ICT)',
      code: '840',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '840/1', name: 'Theory'),
        SubjectPaper(code: '840/2', name: 'Practical'),
      ],
    ),
    Subject(
      name: 'Foods and Nutrition',
      code: '662',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '662/1', name: 'Theory'),
        SubjectPaper(code: '662/2', name: 'Practical'),
      ],
    ),
    Subject(
      name: 'Performing Arts',
      code: '621',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '621/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Technology and Design',
      code: '700',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '700/1', name: 'Theory'),
        SubjectPaper(code: '700/2', name: 'Practical'),
        SubjectPaper(code: '700/3', name: 'Practical'),
      ],
    ),
    Subject(
      name: 'Physical Education (P.E.)',
      code: '555',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '555/1', name: 'Theory'),
        SubjectPaper(code: '555/2', name: 'Performance'),
      ],
    ),
    Subject(
      name: 'Ugandan Sign Language',
      code: '397',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '397/1', name: 'Theory'),
        SubjectPaper(code: '397/2', name: 'Observing and Signing'),
      ],
    ),

    // Languages (Elective)
    Subject(
      name: 'Literature in English',
      code: '208',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '208/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Kiswahili',
      code: '336',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '336/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Luganda',
      code: '335',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '335/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Runyankore/Rukiga',
      code: '364',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '364/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Lusoga',
      code: '366',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '366/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Ateso',
      code: '367',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '367/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Leb Lango',
      code: '362',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '362/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Leb Acoli',
      code: '361',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '361/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Runyoro/Rutooro',
      code: '369',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '369/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'Lumasaba',
      code: '371',
      level: SchoolLevel.oLevel,
      papers: [SubjectPaper(code: '371/1', name: 'Paper 1')],
    ),
    Subject(
      name: 'French',
      code: '314',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '314/1', name: 'Theory'),
        SubjectPaper(code: '314/2', name: 'Oral'),
      ],
    ),
    Subject(
      name: 'German',
      code: '309',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '309/1', name: 'Theory'),
        SubjectPaper(code: '309/2', name: 'Speaking & Listening'),
      ],
    ),
    Subject(
      name: 'Arabic',
      code: '337',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '337/1', name: 'Theory'),
        SubjectPaper(code: '337/2', name: 'Oral'),
      ],
    ),
    Subject(
      name: 'Chinese',
      code: '372',
      level: SchoolLevel.oLevel,
      papers: [
        SubjectPaper(code: '372/1', name: 'Theory'),
        SubjectPaper(code: '372/2', name: 'Oral'),
      ],
    ),
  ];
}

/// A map of all subjects keyed by their code for efficient lookup.
final Map<String, Subject> _allSubjectsByCode = {
  for (var s in [...OLevelSubjects.all, ...ALevelSubjects.all]) s.code: s,
};

/// Finds a subject by its unique code. Returns null if not found.
Subject? findSubjectByCode(String code) {
  return _allSubjectsByCode[code];
}

/// A class to provide easy access to combined and sorted subject lists.
class AllSubjects {
  /// A combined and sorted list of all O-Level and A-Level subjects.
  static final List<Subject> list = [
    ...OLevelSubjects.all,
    ...ALevelSubjects.all,
  ]..sort((a, b) => a.name.compareTo(b.name));
}
