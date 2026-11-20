import '../data/grading_data.dart';

class SupersededCourse {
  String id;
  double? originalMarks;
  String? originalGrade;
  int originalCreditHours;
  double? repeatedMarks;
  String? repeatedGrade;
  int repeatedCreditHours;
  String? repeatedSemesterId;

  SupersededCourse({
    required this.id,
    this.originalMarks,
    this.originalGrade,
    this.originalCreditHours = 3,
    this.repeatedMarks,
    this.repeatedGrade,
    this.repeatedCreditHours = 3,
    this.repeatedSemesterId,
  });

  bool updateScale(GradingScale scale) {
    var clearedGrade = false;
    final originalBand = GradingData.bandForGrade(originalGrade, scale: scale);
    if (originalGrade != null) {
      if (originalBand == null) {
        originalGrade = null;
        originalMarks = null;
        clearedGrade = true;
      } else {
        originalMarks = originalBand.minPercent;
      }
    }
    final repeatedBand = GradingData.bandForGrade(repeatedGrade, scale: scale);
    if (repeatedGrade != null) {
      if (repeatedBand == null) {
        repeatedGrade = null;
        repeatedMarks = null;
        clearedGrade = true;
      } else {
        repeatedMarks = repeatedBand.minPercent;
      }
    }
    return clearedGrade;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalMarks': originalMarks,
    'originalGrade': originalGrade,
    'originalCreditHours': originalCreditHours,
    'repeatedMarks': repeatedMarks,
    'repeatedGrade': repeatedGrade,
    'repeatedCreditHours': repeatedCreditHours,
    'repeatedSemesterId': repeatedSemesterId,
  };

  factory SupersededCourse.fromJson(
    Map<String, dynamic> json, {
    GradingScale scale = GradingScale.spring2025,
  }) {
    final originalMarks =
        (json['originalMarks'] as num?)?.toDouble() ??
        (json['obtainedMarks'] as num?)?.toDouble();
    final repeatedMarks = (json['repeatedMarks'] as num?)?.toDouble();
    return SupersededCourse(
      id: json['id'] as String,
      originalMarks: originalMarks,
      originalGrade:
          json['originalGrade'] as String? ??
          (originalMarks == null
              ? null
              : GradingData.bandForPercent(originalMarks, scale: scale).grade),
      originalCreditHours:
          json['originalCreditHours'] as int? ??
          json['creditHours'] as int? ??
          3,
      repeatedMarks: repeatedMarks,
      repeatedGrade:
          json['repeatedGrade'] as String? ??
          (repeatedMarks == null
              ? null
              : GradingData.bandForPercent(repeatedMarks, scale: scale).grade),
      repeatedCreditHours:
          json['repeatedCreditHours'] as int? ??
          json['creditHours'] as int? ??
          3,
      repeatedSemesterId: json['repeatedSemesterId'] as String?,
    );
  }
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

  factory SemesterInput.fromJson(
    Map<String, dynamic> json, {
    GradingScale scale = GradingScale.spring2025,
  }) => SemesterInput(
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
        .map(
          (e) => SupersededCourse.fromJson(
            e as Map<String, dynamic>,
            scale: scale,
          ),
        )
        .toList(),
  );

  static double? parseGpa(String input) =>
      double.tryParse(input.trim().replaceAll(',', '.'));
}
