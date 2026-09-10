/// Official grading data for Iqra University (undergraduate/ADP programs).
///
/// Source: Iqra University's own "New Grading Scheme and Assessment Models —
/// Implementation from Spring 2025" circular (letterhead document), cross-
/// verified against an independent, actively-maintained 2026 guide
/// (pakstudentcalc.com/archives/iqra-university-grading-system-offical-2026)
/// which reproduces the identical table. Both agree exactly, so this is
/// treated as the current, authoritative scale — NOT the older scheme
/// (A=4.0 at 88%+, B+=3.5, B=3.0, C+=2.5, C=2.0, no +/- grades) still
/// quoted by some third-party sites (scholaro, campusaxis, meershair),
/// which predates the Spring 2025 revision.
///
/// Unlike UAAR, Iqra's grade points are a flat value per letter grade —
/// there is no official "Quality Points" interpolation table, and a
/// course's percentage is its own mark out of 100 (not scaled by credit
/// hours). GPA / CGPA = (Sum of Quality Points) / (Sum of Credit Hours),
/// where a course's quality points = its flat grade point x its credit
/// hours.
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

  /// Minimum passing percentage (below this is F).
  static const double passingPercent = 50;

  static const List<GradeBand> gradeBands = [
    GradeBand('A', 4.0, 88, 100, 'Exceptional'),
    GradeBand('B+', 3.5, 81, 87.999, 'Outstanding'),
    GradeBand('B', 3.0, 74, 80.999, 'Very Good'),
    GradeBand('C+', 2.5, 67, 73.999, 'Above Average'),
    GradeBand('C', 2.0, 60, 66.999, 'Satisfactory'),
    GradeBand('D+', 1.5, 55, 59.999, 'Barely Acceptable'),
    GradeBand('D', 1.0, 50, 54.999, 'Pass'),
    GradeBand('F', 0.0, 0, 49.999, 'Fail'),
  ];

  static GradeBand bandForPercent(double percent) {
    for (final band in gradeBands) {
      if (percent >= band.minPercent && percent <= band.maxPercent) {
        return band;
      }
    }
    return percent > 100 ? gradeBands.first : gradeBands.last;
  }

  /// Quality points for one course: flat grade point (by percentage band)
  /// multiplied by credit hours. [obtainedMarks] is the course's own
  /// percentage/marks out of 100 — Iqra does not scale total marks by
  /// credit hours the way some other universities do.
  static double qualityPointsFor({
    required double obtainedMarks,
    required int creditHours,
  }) {
    final band = bandForPercent(obtainedMarks);
    return band.gradePoint * creditHours;
  }

  /// Iqra's official probation threshold is a semester GPA below 1.70
  /// (per the revised Spring 2025 scheme). Below that is flagged; below
  /// 2.00 (the "C" / degree-requirement floor) is a softer warning.
  static String standingForCgpa(double cgpa) {
    if (cgpa >= 3.5) return 'Excellent Standing';
    if (cgpa >= 3.0) return 'Very Good Standing';
    if (cgpa >= 2.5) return 'Good Standing';
    if (cgpa >= 2.0) return 'Satisfactory Standing';
    if (cgpa >= 1.7) return 'Below Degree Requirement (2.00)';
    return 'Probation Risk (below 1.70)';
  }
}

class GpaResult {
  final double gpa;
  final int totalCreditHours;
  const GpaResult({required this.gpa, required this.totalCreditHours});
}

/// Pure calculation logic for Iqra University's GPA/CGPA formula.
///
/// NOTE ON ROUNDING: unlike UAAR (verified via real transcripts to
/// truncate), we have no real Iqra transcript to confirm whether the
/// university rounds or truncates its displayed GPA. This engine uses
/// standard rounding (round-half-up) to 2 decimals as the more common
/// convention — flag this assumption if you find an official transcript
/// that shows otherwise.
class GpaEngine {
  GpaEngine._();

  static double _round2(double value) {
    return (value * 100).round() / 100;
  }

  /// GPA for a list of (obtainedMarks, creditHours) course pairs.
  static GpaResult calculateGpa(
    List<({double marks, int creditHours})> courses,
  ) {
    final valid = courses.where((c) => c.creditHours > 0).toList();
    if (valid.isEmpty) return const GpaResult(gpa: 0, totalCreditHours: 0);

    final totalCh = valid.fold<int>(0, (s, c) => s + c.creditHours);
    final totalQp = valid.fold<double>(
      0,
      (s, c) =>
          s +
          GradingData.qualityPointsFor(
            obtainedMarks: c.marks,
            creditHours: c.creditHours,
          ),
    );
    final gpa = totalCh == 0 ? 0.0 : totalQp / totalCh;
    return GpaResult(gpa: _round2(gpa), totalCreditHours: totalCh);
  }

  /// CGPA for a list of semester contributions.
  ///
  /// Each semester passes its own (gpa, creditHours) as printed on the
  /// transcript, PLUS optional [deductedQualityPoints] / [deductedCreditHours]
  /// — the quality points and credit hours of any course taken THIS
  /// semester that was later repeated (after failing) or improved in a
  /// different semester. Per standard policy, only the new (better)
  /// attempt counts toward CGPA — the original attempt's quality points
  /// AND credit hours are dropped entirely, not averaged in.
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
    final valid = semesters.where((s) => s.creditHours > 0).toList();
    if (valid.isEmpty) return const GpaResult(gpa: 0, totalCreditHours: 0);

    final totalCh = valid.fold<int>(
      0,
      (s, x) => s + x.creditHours - x.deductedCreditHours,
    );
    final totalQp = valid.fold<double>(
      0,
      (s, x) => s + (x.gpa * x.creditHours) - x.deductedQualityPoints,
    );
    final cgpa = totalCh <= 0 ? 0.0 : totalQp / totalCh;
    return GpaResult(gpa: _round2(cgpa), totalCreditHours: totalCh);
  }
}
