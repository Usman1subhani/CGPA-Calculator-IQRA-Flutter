import '../data/grading_data.dart';

class Course {
  String id;
  String name;
  String? selectedGrade;

  /// The course's own percentage/marks out of 100 (Iqra grades each
  /// course on its own 0-100 scale — total marks are not scaled by
  /// credit hours the way some other universities do).
  double? obtainedMarks;
  int creditHours;

  Course({
    required this.id,
    this.name = '',
    this.obtainedMarks,
    this.selectedGrade,
    this.creditHours = 3,
  });

  double get totalMarks => 100;

  double? get percentage => obtainedMarks;

  GradeBand? gradeBandFor(GradingScale scale) =>
      GradingData.bandForGrade(selectedGrade, scale: scale);

  bool updateScale(GradingScale scale) {
    if (selectedGrade == null) return false;
    final band = gradeBandFor(scale);
    if (band == null) {
      selectedGrade = null;
      obtainedMarks = null;
      return true;
    }
    obtainedMarks = band.minPercent;
    return false;
  }

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
    'selectedGrade': selectedGrade,
    'creditHours': creditHours,
  };

  factory Course.fromJson(
    Map<String, dynamic> json, {
    GradingScale scale = GradingScale.spring2025,
  }) {
    final marks = (json['obtainedMarks'] as num?)?.toDouble();
    final gradeSelected =
        json['gradeSelected'] == true ||
        (json['gradeSelected'] == null && marks != null && marks != 0);
    return Course(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      obtainedMarks: gradeSelected ? marks : null,
      selectedGrade:
          json['selectedGrade'] as String? ??
          (gradeSelected && marks != null
              ? GradingData.bandForPercent(marks, scale: scale).grade
              : null),
      creditHours: json['creditHours'] as int? ?? 3,
    );
  }
}
