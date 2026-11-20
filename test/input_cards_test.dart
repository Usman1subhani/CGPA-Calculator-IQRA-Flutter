import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpa_calculator_iuic/data/grading_data.dart';
import 'package:gpa_calculator_iuic/models/course.dart';
import 'package:gpa_calculator_iuic/models/semester_input.dart';
import 'package:gpa_calculator_iuic/widgets/input_cards.dart';

void main() {
  testWidgets('course selection displays the letter grade, not a percent', (
    tester,
  ) async {
    final course = Course(id: 'course', selectedGrade: 'A-', obtainedMarks: 85);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourseCard(
            course: course,
            index: 0,
            gradingScale: GradingScale.spring2025,
            onDelete: () {},
            onChanged: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Grade A-'), findsOneWidget);
    expect(find.text('85.0%'), findsNothing);
  });

  testWidgets('semester GPA stays blank when only credit hours are entered', (
    tester,
  ) async {
    final semester = SemesterInput(
      id: 'semester',
      creditHours: 3,
      hasCreditHoursInput: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SemesterCard(
            semester: semester,
            semesters: [semester],
            savedGpas: const [],
            index: 0,
            gradingScale: GradingScale.spring2025,
            onDelete: () {},
            onChanged: () {},
            onImportGpa: (_) {},
          ),
        ),
      ),
    );

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.elementAt(1).initialValue, isEmpty);
  });
}
