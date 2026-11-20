import '../data/grading_data.dart';

class Course {
  String id;
  String name;

  /// The course's own percentage/marks out of 100 (Iqra grades each
  /// course on its own 0-100 scale — total marks are not scaled by
  /// credit hours the way some other universities do).
  double? obtainedMarks;
  int creditHours;

  Course({
    required this.id,
    this.name = '',
    this.obtainedMarks,
    this.creditHours = 3,
  });

  double get totalMarks => 100;

  double? get percentage => obtainedMarks;

  GradeBand gradeBandFor(GradingScale scale) =>
      GradingData.bandForPercent(obtainedMarks ?? 0, scale: scale);

  double qualityPointsFor(GradingScale scale) => obtainedMarks == null
      ? 0
      : GradingData.qualityPointsFor(
          obtainedMarks: obtainedMarks!,
          creditHours: creditHours,
          scale: scale,
        );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'obtainedMarks': obtainedMarks,
    'gradeSelected': obtainedMarks != null,
    'creditHours': creditHours,
  };

  factory Course.fromJson(Map<String, dynamic> json) {
    final marks = (json['obtainedMarks'] as num?)?.toDouble();
    return Course(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      obtainedMarks: json['gradeSelected'] == true
          ? marks
          : marks == 0
          ? null
          : marks,
      creditHours: json['creditHours'] as int? ?? 3,
    );
  }
}
