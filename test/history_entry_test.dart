import 'package:flutter_test/flutter_test.dart';
import 'package:gpa_calculator_iuic/models/course.dart';
import 'package:gpa_calculator_iuic/models/history_entry.dart';
import 'package:gpa_calculator_iuic/models/semester_input.dart';

void main() {
  group('HistoryEntry round-trip (needed to reopen a saved calculation for editing)', () {
    test('GPA entry preserves every course exactly through JSON', () {
      final courses = [
        Course(id: 'c1', name: 'CS-300', obtainedMarks: 49, creditHours: 3),
        Course(id: 'c2', name: 'CS-323', obtainedMarks: 53, creditHours: 4),
      ];
      final entry = HistoryEntry(
        id: 'e1',
        type: HistoryType.gpa,
        title: 'Semester 1',
        value: 3.56,
        creditHours: 19,
        date: DateTime(2026, 1, 1),
        rawData: courses.map((c) => c.toJson()).toList(),
      );

      final restored = HistoryEntry.fromJson(entry.toJson());
      final restoredCourses = restored.courses;

      expect(restoredCourses.length, 2);
      expect(restoredCourses[0].name, 'CS-300');
      expect(restoredCourses[0].obtainedMarks, 49);
      expect(restoredCourses[0].creditHours, 3);
      expect(restoredCourses[1].name, 'CS-323');
    });

    test('CGPA entry preserves semesters AND superseded courses through JSON', () {
      final semester = SemesterInput(
        id: 's1',
        name: 'Spring-22',
        gpa: 2.12,
        creditHours: 21,
        supersededCourses: [
          SupersededCourse(id: 'sup1', obtainedMarks: 14, creditHours: 3),
        ],
      );
      final entry = HistoryEntry(
        id: 'e2',
        type: HistoryType.cgpa,
        title: 'Overall CGPA',
        value: 3.07,
        creditHours: 131,
        date: DateTime(2026, 1, 1),
        rawData: [semester.toJson()],
      );

      final restored = HistoryEntry.fromJson(entry.toJson());
      final restoredSemesters = restored.semesters;

      expect(restoredSemesters.length, 1);
      expect(restoredSemesters[0].gpa, 2.12);
      expect(restoredSemesters[0].supersededCourses.length, 1);
      expect(restoredSemesters[0].supersededCourses[0].obtainedMarks, 14);
      expect(restoredSemesters[0].deductedCreditHours, 3);
    });

    test('older history entries with no rawData still restore safely (empty list)', () {
      final entry = HistoryEntry(
        id: 'e3',
        type: HistoryType.gpa,
        title: 'Legacy entry',
        value: 3.0,
        creditHours: 15,
        date: DateTime(2026, 1, 1),
      );
      final restored = HistoryEntry.fromJson(entry.toJson());
      expect(restored.courses, isEmpty);
    });
  });
}
