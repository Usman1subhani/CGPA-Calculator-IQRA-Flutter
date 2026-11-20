enum GradingScale {
  legacy,
  spring2025;

  String get label => switch (this) {
    GradingScale.legacy => 'Admitted before Spring 2025',
    GradingScale.spring2025 => 'Newly admitted Spring 2025 onward',
  };
}

class GradeBand {
  final String grade;
  final double gradePoint;
  final double minPercent;
  final double maxPercent;
  final String remarks;

  const GradeBand(
    this.grade,
    this.gradePoint,
    this.minPercent,
    this.maxPercent,
    this.remarks,
  );
}

class GradingData {
  GradingData._();

  static const String universityName = 'Iqra University';
  static const String universityShortName = 'IUIC';

  static const List<GradeBand> legacyGradeBands = [
    GradeBand('A', 4.0, 88, 100, 'Exceptional'),
    GradeBand('B+', 3.5, 81, 87.999, 'Outstanding'),
    GradeBand('B', 3.0, 74, 80.999, 'Very Good'),
    GradeBand('C+', 2.5, 67, 73.999, 'Above Average'),
    GradeBand('C', 2.0, 60, 66.999, 'Satisfactory'),
    GradeBand('F', 0.0, 0, 59.999, 'Fail'),
  ];

  static const List<GradeBand> spring2025GradeBands = [
    GradeBand('A', 4.0, 90, 100, 'Outstanding'),
    GradeBand('A-', 3.67, 85, 89.999, 'Excellent'),
    GradeBand('B+', 3.33, 80, 84.999, 'Very Good'),
    GradeBand('B', 3.0, 75, 79.999, 'Good'),
    GradeBand('B-', 2.67, 70, 74.999, 'Fairly Good'),
    GradeBand('C+', 2.33, 65, 69.999, 'Above Average'),
    GradeBand('C', 2.0, 60, 64.999, 'Average'),
    GradeBand('C-', 1.67, 56, 59.999, 'Below Average'),
    GradeBand('D+', 1.33, 53, 55.999, 'Poor'),
    GradeBand('D', 1.0, 50, 52.999, 'Unsatisfactory'),
    GradeBand('F', 0.0, 0, 49.999, 'Fail'),
  ];

  static List<GradeBand> gradeBandsFor(GradingScale scale) =>
      scale == GradingScale.legacy ? legacyGradeBands : spring2025GradeBands;

  static double passingPercentFor(GradingScale scale) =>
      scale == GradingScale.legacy ? 60 : 50;

  static GradeBand bandForPercent(
    double percent, {
    GradingScale scale = GradingScale.spring2025,
  }) {
    final bands = gradeBandsFor(scale);
    for (final band in bands) {
      if (percent >= band.minPercent) return band;
    }
    return percent > 100 ? bands.first : bands.last;
  }

  static double qualityPointsFor({
    required double obtainedMarks,
    required int creditHours,
    GradingScale scale = GradingScale.spring2025,
  }) {
    return bandForPercent(obtainedMarks, scale: scale).gradePoint * creditHours;
  }

  static String standingForSemesterGpa(double gpa) {
    if (gpa < 1.7) return 'Probation Risk (semester GPA below 1.70)';
    if (gpa < 2.0) return 'Below Degree Requirement (2.00)';
    if (gpa >= 3.5) return 'Excellent Standing';
    if (gpa >= 3.0) return 'Very Good Standing';
    if (gpa >= 2.5) return 'Good Standing';
    return 'Satisfactory Standing';
  }

  static String standingForCgpa(double cgpa) {
    if (cgpa < 2.0) return 'Below Degree Requirement (CGPA below 2.00)';
    if (cgpa >= 3.5) return 'Excellent Standing';
    if (cgpa >= 3.0) return 'Very Good Standing';
    if (cgpa >= 2.5) return 'Good Standing';
    return 'Satisfactory Standing';
  }
}

class GpaResult {
  final double gpa;
  final int totalCreditHours;
  final double qualityPoints;

  const GpaResult({
    required this.gpa,
    required this.totalCreditHours,
    this.qualityPoints = 0,
  });
}

class GpaEngine {
  GpaEngine._();

  static double _truncate2(double value) =>
      (value * 100).truncateToDouble() / 100;

  static ({bool original, double qualityPoints, int creditHours})
  excludedRepeatAttempt({
    required double originalGradePoint,
    required int originalCreditHours,
    required double repeatedGradePoint,
    required int repeatedCreditHours,
  }) {
    if (originalGradePoint > repeatedGradePoint) {
      return (
        original: false,
        qualityPoints: repeatedGradePoint * repeatedCreditHours,
        creditHours: repeatedCreditHours,
      );
    }
    return (
      original: true,
      qualityPoints: originalGradePoint * originalCreditHours,
      creditHours: originalCreditHours,
    );
  }

  static GpaResult calculateGpa(
    List<({double marks, int creditHours})> courses, {
    GradingScale scale = GradingScale.spring2025,
  }) {
    final valid = courses.where((c) => c.creditHours > 0).toList();
    if (valid.isEmpty) {
      return const GpaResult(gpa: 0, totalCreditHours: 0);
    }

    final totalCh = valid.fold<int>(
      0,
      (sum, course) => sum + course.creditHours,
    );
    final totalQp = valid.fold<double>(
      0,
      (sum, course) =>
          sum +
          GradingData.qualityPointsFor(
            obtainedMarks: course.marks,
            creditHours: course.creditHours,
            scale: scale,
          ),
    );
    return GpaResult(
      gpa: _truncate2(totalQp / totalCh),
      totalCreditHours: totalCh,
      qualityPoints: totalQp,
    );
  }

  static GpaResult calculateCgpa(
    List<
      ({
        double gpa,
        int creditHours,
        double deductedQualityPoints,
        int deductedCreditHours,
      })
    >
    semesters,
  ) {
    final valid = semesters
        .where((semester) => semester.creditHours > 0)
        .toList();
    if (valid.isEmpty) {
      return const GpaResult(gpa: 0, totalCreditHours: 0);
    }

    final totalCh = valid.fold<int>(
      0,
      (sum, semester) =>
          sum + semester.creditHours - semester.deductedCreditHours,
    );
    final totalQp = valid.fold<double>(
      0,
      (sum, semester) =>
          sum +
          (semester.gpa * semester.creditHours) -
          semester.deductedQualityPoints,
    );
    return GpaResult(
      gpa: totalCh <= 0 ? 0 : _truncate2(totalQp / totalCh),
      totalCreditHours: totalCh,
      qualityPoints: totalQp,
    );
  }
}
