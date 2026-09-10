import 'package:flutter/material.dart';
import 'package:gpa_calculator_iuic/data/grading_data.dart';
import '../models/course.dart';
import '../models/semester_input.dart';
import '../theme.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final int index;
  final bool isPercentageMode;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const CourseCard({
    super.key,
    required this.course,
    required this.index,
    this.isPercentageMode = false,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showGrade = course.creditHours > 0 && course.obtainedMarks > 0;
    final band = showGrade ? course.gradeBand : null;

    // Ensure the current obtainedMarks is exactly one of the minPercent values,
    // otherwise the Dropdown will throw an error if it doesn't match an item.
    final validValues = GradingData.gradeBands
        .map((b) => b.minPercent)
        .toList();
    double? currentValue = course.obtainedMarks > 0
        ? course.obtainedMarks
        : null;
    if (currentValue != null && !validValues.contains(currentValue)) {
      // If it doesn't match exactly (e.g., from old data), snap it to the closest band's minPercent.
      currentValue = GradingData.bandForPercent(currentValue).minPercent;
      // We don't call setState here to avoid build loops, but the UI will show the snapped value.
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: course.name,
                    decoration: const InputDecoration(
                      hintText: 'Course name',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      course.name = v;
                    },
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.close_rounded),
                  color: theme.colorScheme.error,
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: currentValue,
                    decoration: InputDecoration(
                      labelText: isPercentageMode ? 'Percentage' : 'Grade',
                      isDense: true,
                    ),
                    items: GradingData.gradeBands.map((b) {
                      final label = isPercentageMode
                          ? '${b.minPercent.toInt()}-${b.maxPercent.toInt()}%'
                          : b.grade;
                      return DropdownMenuItem<double>(
                        value: b.minPercent,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (v) {
                      course.obtainedMarks = v ?? 0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: course.creditHours,
                    decoration: const InputDecoration(
                      labelText: 'Credit hrs',
                      isDense: true,
                    ),
                    items: List.generate(6, (i) => i + 1)
                        .map(
                          (ch) =>
                              DropdownMenuItem(value: ch, child: Text('$ch')),
                        )
                        .toList(),
                    onChanged: (v) {
                      course.creditHours = v ?? 3;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            if (band != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.forGrade(
                        band.grade,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Grade ${band.grade} • ${course.qualityPoints.toStringAsFixed(2)} QP',
                      style: TextStyle(
                        color: AppColors.forGrade(band.grade),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${course.percentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SemesterCard extends StatelessWidget {
  final SemesterInput semester;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const SemesterCard({
    super.key,
    required this.semester,
    required this.index,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: semester.name,
                    decoration: const InputDecoration(
                      hintText: 'Semester name',
                      isDense: true,
                    ),
                    onChanged: (v) => semester.name = v,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.close_rounded),
                  color: theme.colorScheme.error,
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: semester.gpa == 0
                        ? ''
                        : semester.gpa.toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Semester GPA',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      semester.gpa = double.tryParse(v) ?? 0;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: semester.creditHours == 0
                        ? ''
                        : semester.creditHours.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Credit hours',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      semester.creditHours = int.tryParse(v) ?? 0;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...semester.supersededCourses.asMap().entries.map((entry) {
              final sIndex = entry.key;
              final course = entry.value;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 15,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Repeated/improved course #${sIndex + 1}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            semester.supersededCourses.removeAt(sIndex);
                            onChanged();
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter this course\'s percentage exactly as it was in the '
                      'ORIGINAL attempt (before it was repeated/improved).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: course.obtainedMarks == 0
                                ? ''
                                : course.obtainedMarks.toString(),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Percentage (%)',
                              isDense: true,
                            ),
                            onChanged: (v) {
                              course.obtainedMarks = double.tryParse(v) ?? 0;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: course.creditHours,
                            decoration: const InputDecoration(
                              labelText: 'Credit hrs',
                              isDense: true,
                            ),
                            items: List.generate(6, (i) => i + 1)
                                .map(
                                  (ch) => DropdownMenuItem(
                                    value: ch,
                                    child: Text('$ch'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              course.creditHours = v ?? 3;
                              onChanged();
                            },
                          ),
                        ),
                      ],
                    ),
                    if (course.obtainedMarks > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Excluded from CGPA: ${course.qualityPoints.toStringAsFixed(2)} QP, ${course.creditHours} credit hrs',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                semester.supersededCourses.add(
                  SupersededCourse(
                    id: 'sup${DateTime.now().microsecondsSinceEpoch}',
                  ),
                );
                onChanged();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Add repeated/improved course from this semester',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
