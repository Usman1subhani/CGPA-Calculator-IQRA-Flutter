import '../data/grading_data.dart';

class Course {
  String id;
  String name;

  /// The course's own percentage/marks out of 100 (Iqra grades each
  /// course on its own 0-100 scale — total marks are not scaled by
  /// credit hours the way some other universities do).
  double obtainedMarks;
  int creditHours;

  Course({
    required this.id,
    this.name = '',
    this.obtainedMarks = 0,
    this.creditHours = 3,
  });

  double get totalMarks => 100;

  double get percentage => obtainedMarks;

  GradeBand get gradeBand => GradingData.bandForPercent(percentage);

  double get qualityPoints => GradingData.qualityPointsFor(
        obtainedMarks: obtainedMarks,
        creditHours: creditHours,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'obtainedMarks': obtainedMarks,
        'creditHours': creditHours,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        obtainedMarks: (json['obtainedMarks'] as num?)?.toDouble() ?? 0,
        creditHours: json['creditHours'] as int? ?? 3,
      );
}
