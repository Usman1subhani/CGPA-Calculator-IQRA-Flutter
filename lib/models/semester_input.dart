class SupersededCourse {
  String id;
  double? originalMarks;
  int originalCreditHours;
  double? repeatedMarks;
  int repeatedCreditHours;
  String? repeatedSemesterId;

  SupersededCourse({
    required this.id,
    this.originalMarks,
    this.originalCreditHours = 3,
    this.repeatedMarks,
    this.repeatedCreditHours = 3,
    this.repeatedSemesterId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalMarks': originalMarks,
    'originalCreditHours': originalCreditHours,
    'repeatedMarks': repeatedMarks,
    'repeatedCreditHours': repeatedCreditHours,
    'repeatedSemesterId': repeatedSemesterId,
  };

  factory SupersededCourse.fromJson(
    Map<String, dynamic> json,
  ) => SupersededCourse(
    id: json['id'] as String,
    originalMarks:
        (json['originalMarks'] as num?)?.toDouble() ??
        (json['obtainedMarks'] as num?)?.toDouble(),
    originalCreditHours:
        json['originalCreditHours'] as int? ?? json['creditHours'] as int? ?? 3,
    repeatedMarks: (json['repeatedMarks'] as num?)?.toDouble(),
    repeatedCreditHours:
        json['repeatedCreditHours'] as int? ?? json['creditHours'] as int? ?? 3,
    repeatedSemesterId: json['repeatedSemesterId'] as String?,
  );
}

class SemesterInput {
  String id;
  String name;
  double gpa;
  int creditHours;
  double? qualityPoints;
  bool hasGpaInput;
  bool hasCreditHoursInput;
  bool hasInvalidGpaInput;
  bool hasInvalidCreditHoursInput;
  List<SupersededCourse> supersededCourses;

  SemesterInput({
    required this.id,
    this.name = '',
    this.gpa = 0,
    this.creditHours = 0,
    this.qualityPoints,
    this.hasGpaInput = false,
    this.hasCreditHoursInput = false,
    this.hasInvalidGpaInput = false,
    this.hasInvalidCreditHoursInput = false,
    List<SupersededCourse>? supersededCourses,
  }) : supersededCourses = supersededCourses ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gpa': gpa,
    'creditHours': creditHours,
    'qualityPoints': qualityPoints,
    'hasGpaInput': hasGpaInput,
    'hasCreditHoursInput': hasCreditHoursInput,
    'supersededCourses': supersededCourses.map((c) => c.toJson()).toList(),
  };

  factory SemesterInput.fromJson(Map<String, dynamic> json) => SemesterInput(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    gpa: (json['gpa'] as num?)?.toDouble() ?? 0,
    creditHours: json['creditHours'] as int? ?? 0,
    qualityPoints: (json['qualityPoints'] as num?)?.toDouble(),
    hasGpaInput:
        json['hasGpaInput'] as bool? ??
        (((json['gpa'] as num?)?.toDouble() ?? 0) != 0 ||
            (json['creditHours'] as int? ?? 0) > 0),
    hasCreditHoursInput:
        json['hasCreditHoursInput'] as bool? ??
        (json['creditHours'] as int? ?? 0) > 0,
    supersededCourses: (json['supersededCourses'] as List<dynamic>? ?? [])
        .map((e) => SupersededCourse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
