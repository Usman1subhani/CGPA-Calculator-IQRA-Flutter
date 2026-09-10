import 'package:flutter_test/flutter_test.dart';
import 'package:gpa_calculator_iuic/data/grading_data.dart';

void main() {
  group('Iqra University grade bands (Spring 2025 scheme)', () {
    test('every official band boundary maps to the correct grade + point', () {
      final cases = <(double percent, String grade, double point)>[
        (95, 'A', 4.00),
        (90, 'A', 4.00),
        (89, 'A-', 3.67),
        (85, 'A-', 3.67),
        (84, 'B+', 3.33),
        (80, 'B+', 3.33),
        (79, 'B', 3.00),
        (75, 'B', 3.00),
        (74, 'B-', 2.67),
        (70, 'B-', 2.67),
        (69, 'C+', 2.33),
        (65, 'C+', 2.33),
        (64, 'C', 2.00),
        (60, 'C', 2.00),
        (59, 'C-', 1.67),
        (56, 'C-', 1.67),
        (55, 'D+', 1.33),
        (53, 'D+', 1.33),
        (52, 'D', 1.00),
        (50, 'D', 1.00),
        (49, 'F', 0.00),
        (0, 'F', 0.00),
      ];
      for (final c in cases) {
        final band = GradingData.bandForPercent(c.$1);
        expect(band.grade, c.$2, reason: '${c.$1}% should be ${c.$2}');
        expect(band.gradePoint, c.$3, reason: '${c.$1}% should be ${c.$3} points');
      }
    });

    test('passing requires at least 50% (D grade, 1.00 points)', () {
      expect(GradingData.bandForPercent(50).grade, 'D');
      expect(GradingData.bandForPercent(49.99).grade, 'F');
    });
  });

  group('GPA calculation (flat grade points x credit hours)', () {
    test('quality points = grade point * credit hours (no interpolation)', () {
      // 92% -> A (4.00), 3 credit hours -> 12.00 QP
      expect(GradingData.qualityPointsFor(obtainedMarks: 92, creditHours: 3), 12.00);
      // 78% -> B (3.00), 3 credit hours -> 9.00 QP
      expect(GradingData.qualityPointsFor(obtainedMarks: 78, creditHours: 3), 9.00);
      // 55% -> D+ (1.33), 3 credit hours -> 3.99 QP
      expect(GradingData.qualityPointsFor(obtainedMarks: 55, creditHours: 3), closeTo(3.99, 0.001));
    });

    test('combines a mixed set of courses correctly', () {
      final courses = [
        (marks: 92.0, creditHours: 3), // A, 12.00 QP
        (marks: 78.0, creditHours: 3), // B, 9.00 QP
        (marks: 55.0, creditHours: 3), // D+, 3.99 QP
      ];
      final result = GpaEngine.calculateGpa(courses);
      expect(result.totalCreditHours, 9);
      // (12.00 + 9.00 + 3.99) / 9 = 24.99 / 9 = 2.7766... -> rounds to 2.78
      expect(result.gpa, 2.78);
    });

    test('a failed course (below 50%) contributes 0 quality points', () {
      final courses = [
        (marks: 45.0, creditHours: 3), // F
        (marks: 90.0, creditHours: 3), // A
      ];
      final result = GpaEngine.calculateGpa(courses);
      // (0 + 12.00) / 6 = 2.00
      expect(result.gpa, 2.00);
    });

    test('empty course list returns 0', () {
      final result = GpaEngine.calculateGpa([]);
      expect(result.gpa, 0.0);
      expect(result.totalCreditHours, 0);
    });
  });

  group('CGPA calculation', () {
    test('combines multiple semesters by credit-hour weight', () {
      final semesters = [
        (gpa: 3.5, creditHours: 18, deductedQualityPoints: 0.0, deductedCreditHours: 0),
        (gpa: 3.0, creditHours: 15, deductedQualityPoints: 0.0, deductedCreditHours: 0),
      ];
      final result = GpaEngine.calculateCgpa(semesters);
      // (3.5*18 + 3.0*15) / 33 = (63 + 45) / 33 = 108/33 = 3.2727... -> 3.27
      expect(result.gpa, 3.27);
      expect(result.totalCreditHours, 33);
    });

    test('excludes superseded (repeated/improved) course attempts', () {
      final semesters = [
        (gpa: 3.2, creditHours: 18, deductedQualityPoints: 0.0, deductedCreditHours: 0),
        // This semester had a failed course (F, 0 QP, 3 CH) later repeated elsewhere.
        (gpa: 2.5, creditHours: 15, deductedQualityPoints: 0.0, deductedCreditHours: 3),
        // The repeat itself: A, 4.00 points x 3 CH = 12.00 QP.
        (gpa: 4.0, creditHours: 3, deductedQualityPoints: 0.0, deductedCreditHours: 0),
      ];
      final result = GpaEngine.calculateCgpa(semesters);
      // totalCh = 18 + (15-3) + 3 = 33
      expect(result.totalCreditHours, 33);
      // totalQp = (3.2*18) + (2.5*15 - 0) + (4.0*3) = 57.6 + 37.5 + 12.0 = 107.1
      // 107.1 / 33 = 3.2454... -> 3.25
      expect(result.gpa, 3.25);
    });
  });

  group('CGPA standing labels', () {
    test('flags the official 1.70 probation threshold', () {
      expect(GradingData.standingForCgpa(1.5), contains('Probation'));
      expect(GradingData.standingForCgpa(1.8), contains('Below Degree Requirement'));
      expect(GradingData.standingForCgpa(2.5), 'Good Standing');
    });
  });
}
