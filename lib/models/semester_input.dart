import '../data/grading_data.dart';

/// One course, taken this semester, that was LATER repeated (after
/// failing) or improved in a different semester. Its original quality
/// points and credit hours must be excluded from CGPA — only the new
/// attempt (entered as its own semester/course elsewhere) counts.
class SupersededCourse {
  String id;
  double obtainedMarks;
  int creditHours;

  SupersededCourse({
    required this.id,
    this.obtainedMarks = 0,
    this.creditHours = 3,
  });

  double get qualityPoints => GradingData.qualityPointsFor(
        obtainedMarks: obtainedMarks,
        creditHours: creditHours,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'obtainedMarks': obtainedMarks,
        'creditHours': creditHours,
      };

  factory SupersededCourse.fromJson(Map<String, dynamic> json) => SupersededCourse(
        id: json['id'] as String,
        obtainedMarks: (json['obtainedMarks'] as num?)?.toDouble() ?? 0,
        creditHours: json['creditHours'] as int? ?? 3,
      );
}

class SemesterInput {
  String id;
  String name;
  double gpa;
  int creditHours;
  List<SupersededCourse> supersededCourses;

  SemesterInput({
    required this.id,
    this.name = '',
    this.gpa = 0,
    this.creditHours = 0,
    List<SupersededCourse>? supersededCourses,
  }) : supersededCourses = supersededCourses ?? [];

  double get deductedQualityPoints =>
      supersededCourses.fold(0.0, (s, c) => s + c.qualityPoints);

  int get deductedCreditHours =>
      supersededCourses.fold(0, (s, c) => s + c.creditHours);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gpa': gpa,
        'creditHours': creditHours,
        'supersededCourses': supersededCourses.map((c) => c.toJson()).toList(),
      };

  factory SemesterInput.fromJson(Map<String, dynamic> json) => SemesterInput(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        gpa: (json['gpa'] as num?)?.toDouble() ?? 0,
        creditHours: json['creditHours'] as int? ?? 0,
        supersededCourses: (json['supersededCourses'] as List<dynamic>? ?? [])
            .map((e) => SupersededCourse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
