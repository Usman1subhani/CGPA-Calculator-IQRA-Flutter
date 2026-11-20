import 'package:flutter/material.dart';
import 'package:gpa_calculator_iuic/data/grading_data.dart';
import '../models/course.dart';
import '../models/semester_input.dart';
import '../models/history_entry.dart';
import '../theme.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final int index;
  final GradingScale gradingScale;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const CourseCard({
    super.key,
    required this.course,
    required this.index,
    this.gradingScale = GradingScale.spring2025,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showGrade = course.creditHours > 0 && course.obtainedMarks != null;
    final band = showGrade ? course.gradeBandFor(gradingScale) : null;
    final gradeBands = GradingData.gradeBandsFor(gradingScale);
    final currentValue = course.gradeBandFor(gradingScale)?.minPercent;

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
                    key: ValueKey(
                      'course-grade-${course.id}-${gradingScale.name}',
                    ),
                    initialValue: currentValue,
                    decoration: InputDecoration(
                      labelText: 'Grade',
                      isDense: true,
                    ),
                    items: gradeBands.map((b) {
                      return DropdownMenuItem<double>(
                        value: b.minPercent,
                        child: Text(b.grade),
                      );
                    }).toList(),
                    onChanged: (v) {
                      course.obtainedMarks = v;
                      course.selectedGrade = v == null
                          ? null
                          : gradeBands
                                .firstWhere((band) => band.minPercent == v)
                                .grade;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('course-hours-${course.id}'),
                    initialValue:
                        course.creditHours >= 1 && course.creditHours <= 6
                        ? course.creditHours
                        : null,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.forGrade(band.grade).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Grade ${band.grade} • ${course.qualityPointsFor(gradingScale).toStringAsFixed(2)} QP',
                  style: TextStyle(
                    color: AppColors.forGrade(band.grade),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
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
  final List<SemesterInput> semesters;
  final List<HistoryEntry> savedGpas;
  final int index;
  final GradingScale gradingScale;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final ValueChanged<HistoryEntry> onImportGpa;

  const SemesterCard({
    super.key,
    required this.semester,
    required this.semesters,
    required this.savedGpas,
    required this.index,
    required this.gradingScale,
    required this.onDelete,
    required this.onChanged,
    required this.onImportGpa,
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
                    onChanged: (v) {
                      semester.name = v;
                      onChanged();
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
            if (savedGpas.isNotEmpty)
              DropdownButtonFormField<String>(
                key: ValueKey('gpa-import-${semester.id}'),
                decoration: const InputDecoration(
                  labelText: 'Use saved GPA calculation (optional)',
                  isDense: true,
                ),
                items: savedGpas
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.id,
                        child: Text(
                          '${entry.title} • ${entry.value.toStringAsFixed(2)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  onImportGpa(savedGpas.firstWhere((entry) => entry.id == id));
                },
              ),
            if (savedGpas.isNotEmpty) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: semester.hasGpaInput
                        ? semester.gpa.toString()
                        : '',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Semester GPA',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final parsed = SemesterInput.parseGpa(v);
                      semester.hasGpaInput = v.trim().isNotEmpty;
                      semester.hasInvalidGpaInput =
                          semester.hasGpaInput && parsed == null;
                      semester.gpa = parsed ?? 0;
                      semester.qualityPoints = null;
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
                      final parsed = int.tryParse(v);
                      semester.hasCreditHoursInput = v.trim().isNotEmpty;
                      semester.hasInvalidCreditHoursInput =
                          semester.hasCreditHoursInput && parsed == null;
                      semester.creditHours = parsed ?? 0;
                      semester.qualityPoints = null;
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
              final repeatSemesters = semesters
                  .where((candidate) => candidate.id != semester.id)
                  .toList();
              return Container(
                key: ValueKey(course.id),
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
                      'The higher grade counts toward CGPA. Select both attempts '
                      'and the semester containing the repeat.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'repeat-semester-${course.id}-${semester.id}',
                      ),
                      initialValue:
                          repeatSemesters.any(
                            (candidate) =>
                                candidate.id == course.repeatedSemesterId,
                          )
                          ? course.repeatedSemesterId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Semester of repeat',
                        isDense: true,
                      ),
                      items: repeatSemesters
                          .map(
                            (candidate) => DropdownMenuItem(
                              value: candidate.id,
                              child: Text(
                                candidate.name.isEmpty
                                    ? 'Semester ${semesters.indexOf(candidate) + 1}'
                                    : candidate.name,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        course.repeatedSemesterId = id;
                        onChanged();
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _gradePicker(
                            label: 'Original grade',
                            value: course.originalGrade,
                            scale: gradingScale,
                            keyName: 'original-${course.id}',
                            onChanged: (value) {
                              course.originalGrade = value;
                              course.originalMarks = value == null
                                  ? null
                                  : GradingData.gradeBandsFor(gradingScale)
                                        .firstWhere(
                                          (band) => band.grade == value,
                                        )
                                        .minPercent;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _gradePicker(
                            label: 'Repeat grade',
                            value: course.repeatedGrade,
                            scale: gradingScale,
                            keyName: 'repeat-${course.id}',
                            onChanged: (value) {
                              course.repeatedGrade = value;
                              course.repeatedMarks = value == null
                                  ? null
                                  : GradingData.gradeBandsFor(gradingScale)
                                        .firstWhere(
                                          (band) => band.grade == value,
                                        )
                                        .minPercent;
                              onChanged();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _creditPicker(
                            label: 'Original hrs',
                            value: course.originalCreditHours,
                            keyName: 'original-hours-${course.id}',
                            onChanged: (value) {
                              course.originalCreditHours = value;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _creditPicker(
                            label: 'Repeat hrs',
                            value: course.repeatedCreditHours,
                            keyName: 'repeat-hours-${course.id}',
                            onChanged: (value) {
                              course.repeatedCreditHours = value;
                              onChanged();
                            },
                          ),
                        ),
                      ],
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
                      'Add a repeated/improved course',
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

  Widget _gradePicker({
    required String label,
    required String? value,
    required GradingScale scale,
    required String keyName,
    required ValueChanged<String?> onChanged,
  }) {
    final bands = GradingData.gradeBandsFor(scale);
    final selected = bands.any((band) => band.grade == value) ? value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('$keyName-${scale.name}'),
      initialValue: selected,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: bands
          .map(
            (band) =>
                DropdownMenuItem(value: band.grade, child: Text(band.grade)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _creditPicker({
    required String label,
    required int value,
    required String keyName,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: ValueKey(keyName),
      initialValue: value >= 1 && value <= 6 ? value : null,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: List.generate(6, (i) => i + 1)
          .map((hours) => DropdownMenuItem(value: hours, child: Text('$hours')))
          .toList(),
      onChanged: (hours) {
        if (hours != null) onChanged(hours);
      },
    );
  }
}
