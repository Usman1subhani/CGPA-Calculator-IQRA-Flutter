import 'package:flutter_test/flutter_test.dart';
import 'package:gpa_calculator_iuic/data/grading_data.dart';
import 'package:gpa_calculator_iuic/models/course.dart';
import 'package:gpa_calculator_iuic/models/semester_input.dart';

void main() {
  group('Iqra University grading scales', () {
    test('Spring 2025 scale uses the 11 official bands', () {
      final cases = <(double, String, double)>[
        (90, 'A', 4.00),
        (89, 'A-', 3.67),
        (85, 'A-', 3.67),
        (84, 'B+', 3.33),
        (80, 'B+', 3.33),
        (75, 'B', 3.00),
        (70, 'B-', 2.67),
        (65, 'C+', 2.33),
        (60, 'C', 2.00),
        (56, 'C-', 1.67),
        (53, 'D+', 1.33),
        (50, 'D', 1.00),
        (49.99, 'F', 0.00),
        (0, 'F', 0.00),
      ];

      for (final (percent, grade, points) in cases) {
        final band = GradingData.bandForPercent(percent);
        expect(band.grade, grade, reason: '$percent% should be $grade');
        expect(band.gradePoint, points);
      }
    });

    test('pre-Spring 2025 scale has no D grades and below 60 is F', () {
      final cases = <(double, String, double)>[
        (88, 'A', 4.0),
        (87.99, 'B+', 3.5),
        (81, 'B+', 3.5),
        (74, 'B', 3.0),
        (67, 'C+', 2.5),
        (60, 'C', 2.0),
        (59.99, 'F', 0),
        (0, 'F', 0),
      ];

      for (final (percent, grade, points) in cases) {
        final band = GradingData.bandForPercent(
          percent,
          scale: GradingScale.legacy,
        );
        expect(band.grade, grade, reason: '$percent% should be $grade');
        expect(band.gradePoint, points);
      }
    });
  });

  group('GPA calculation', () {
    test('changing scales preserves available letter grades', () {
      final course = Course(
        id: 'course',
        selectedGrade: 'B+',
        obtainedMarks: 80,
      );

      expect(course.updateScale(GradingScale.legacy), isFalse);
      expect(course.selectedGrade, 'B+');
      expect(course.obtainedMarks, 81);
      expect(course.gradeBandFor(GradingScale.legacy)?.grade, 'B+');
    });

    test(
      'changing scales clears grades that do not exist on the new scale',
      () {
        final course = Course(
          id: 'course',
          selectedGrade: 'A-',
          obtainedMarks: 85,
        );

        expect(course.updateScale(GradingScale.legacy), isTrue);
        expect(course.selectedGrade, isNull);
        expect(course.obtainedMarks, isNull);
      },
    );

    test('uses the selected scale and flat grade points', () {
      expect(
        GradingData.qualityPointsFor(obtainedMarks: 89, creditHours: 3),
        11.01,
      );
      expect(
        GradingData.qualityPointsFor(
          obtainedMarks: 87,
          creditHours: 3,
          scale: GradingScale.legacy,
        ),
        10.5,
      );
    });

    test('truncates the displayed GPA rather than rounding it', () {
      final result = GpaEngine.calculateGpa([
        (marks: 92.0, creditHours: 3),
        (marks: 78.0, creditHours: 3),
        (marks: 55.0, creditHours: 3),
      ]);
      expect(result.totalCreditHours, 9);
      expect(result.qualityPoints, closeTo(24.99, 0.001));
      expect(result.gpa, 2.77);
    });

    test('a selected F grade contributes zero points', () {
      final result = GpaEngine.calculateGpa([
        (marks: 0.0, creditHours: 3),
        (marks: 90.0, creditHours: 3),
      ]);
      expect(result.totalCreditHours, 6);
      expect(result.gpa, 2.0);
    });

    test('empty course list returns zero', () {
      final result = GpaEngine.calculateGpa([]);
      expect(result.gpa, 0);
      expect(result.totalCreditHours, 0);
    });
  });

  group('CGPA calculation', () {
    test('combines multiple semesters by credit-hour weight and truncates', () {
      final result = GpaEngine.calculateCgpa([
        (
          gpa: 3.5,
          creditHours: 18,
          deductedQualityPoints: 0.0,
          deductedCreditHours: 0,
        ),
        (
          gpa: 3.0,
          creditHours: 15,
          deductedQualityPoints: 0.0,
          deductedCreditHours: 0,
        ),
      ]);
      expect(result.gpa, 3.27);
      expect(result.totalCreditHours, 33);
    });

    test('uses exact quality points when imported GPA is not rounded', () {
      final exactQualityPoints = 10.01;
      final exactSemesterGpa = exactQualityPoints / 3;
      final result = GpaEngine.calculateCgpa([
        (
          gpa: exactSemesterGpa,
          creditHours: 3,
          deductedQualityPoints: 0.0,
          deductedCreditHours: 0,
        ),
      ]);
      expect(result.qualityPoints, closeTo(exactQualityPoints, 1e-10));
      expect(result.gpa, 3.33);
    });

    test('does not truncate an exactly representable decimal GPA down', () {
      final result = GpaEngine.calculateCgpa([
        (
          gpa: 2.3,
          creditHours: 10,
          deductedQualityPoints: 0.0,
          deductedCreditHours: 0,
        ),
      ]);
      expect(result.gpa, 2.30);
    });

    test('excludes the lower of the original and repeated attempts', () {
      final oldAttempt = GpaEngine.excludedRepeatAttempt(
        originalGradePoint: 1.0,
        originalCreditHours: 3,
        repeatedGradePoint: 4.0,
        repeatedCreditHours: 3,
      );
      expect(oldAttempt.original, isTrue);
      expect(oldAttempt.qualityPoints, 3);

      final repeatAttempt = GpaEngine.excludedRepeatAttempt(
        originalGradePoint: 4.0,
        originalCreditHours: 3,
        repeatedGradePoint: 1.0,
        repeatedCreditHours: 3,
      );
      expect(repeatAttempt.original, isFalse);
      expect(repeatAttempt.qualityPoints, 3);
    });
  });

  group('Academic standing labels', () {
    test('probation applies to semester GPA, not CGPA', () {
      expect(GradingData.standingForSemesterGpa(1.5), contains('Probation'));
      expect(GradingData.standingForCgpa(1.5), contains('CGPA below 2.00'));
      expect(GradingData.standingForCgpa(2.5), 'Good Standing');
    });
  });

  test('Semester GPA accepts decimal comma input', () {
    expect(SemesterInput.parseGpa('3,5'), 3.5);
    expect(SemesterInput.parseGpa('not a GPA'), isNull);
  });
}
