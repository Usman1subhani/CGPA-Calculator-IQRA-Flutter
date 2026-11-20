import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../data/grading_data.dart';
import '../models/history_entry.dart';
import '../models/semester_input.dart';
import '../widgets/common.dart';
import '../widgets/input_cards.dart';
import '../widgets/result_card.dart';
import '../widgets/share_result_button.dart';
import '../widgets/screen_header.dart';
import 'grading_scale_screen.dart';

int _seq = 0;
String _nextId() => 's${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

class CgpaScreen extends StatefulWidget {
  /// If provided, the screen opens pre-filled with this saved calculation's
  /// semesters so the person can review or edit it. Saving again updates
  /// the same history entry instead of creating a new one.
  final HistoryEntry? existingEntry;

  const CgpaScreen({super.key, this.existingEntry});

  @override
  State<CgpaScreen> createState() => _CgpaScreenState();
}

class _CgpaScreenState extends State<CgpaScreen> {
  final List<SemesterInput> _semesters = [];
  GpaResult? _result;
  String? _validationError;
  bool _saving = false;
  bool _showRepeatTip = true;
  bool get _isEditing => widget.existingEntry != null;
  GradingScale _gradingScale = GradingScale.spring2025;
  final Map<String, int> _formRevisions = {};
  int _semesterListRevision = 0;

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    if (entry != null) {
      _gradingScale = entry.gradingScale;
      final savedSemesters = entry.semesters;
      if (savedSemesters.isNotEmpty) {
        _semesters.addAll(savedSemesters);
      } else {
        _addSemester();
        _addSemester();
      }
      _calculate(silent: true);
    } else {
      _addSemester();
      _addSemester();
    }
  }

  void _addSemester() {
    setState(() {
      _semesters.add(
        SemesterInput(id: _nextId(), name: 'Semester ${_semesters.length + 1}'),
      );
      _semesterListRevision++;
      _result = null;
      _validationError = null;
    });
  }

  void _removeSemester(String id) {
    setState(() {
      _semesters.removeWhere((s) => s.id == id);
      for (final semester in _semesters) {
        for (final course in semester.supersededCourses) {
          if (course.repeatedSemesterId == id) {
            course.repeatedSemesterId = null;
          }
        }
      }
      _semesterListRevision++;
      _result = null;
      _validationError = null;
    });
  }

  void _showInputError(String message, {bool silent = false}) {
    if (silent) {
      _validationError = message;
      return;
    }
    setState(() => _validationError = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _calculate({bool silent = false}) {
    if (!silent) FocusScope.of(context).unfocus();
    final invalid = _semesters.any((semester) {
      final hasInput =
          semester.hasGpaInput ||
          semester.hasCreditHoursInput ||
          semester.gpa != 0 ||
          semester.creditHours != 0;
      return semester.hasInvalidGpaInput ||
          semester.hasInvalidCreditHoursInput ||
          !semester.gpa.isFinite ||
          semester.gpa < 0 ||
          semester.gpa > 4 ||
          semester.creditHours < 0 ||
          semester.creditHours > 40 ||
          (hasInput &&
              (!semester.hasGpaInput ||
                  !semester.hasCreditHoursInput ||
                  semester.creditHours == 0));
    });
    if (invalid) {
      _showInputError(
        'Each started semester needs a GPA from 0 to 4 and credit hours from 1 to 40.',
        silent: silent,
      );
      return;
    }

    final repeats = <({String semesterId, double qualityPoints, int hours})>[];
    for (final semester in _semesters) {
      for (final course in semester.supersededCourses) {
        final repeatSemester = _semesters.where(
          (candidate) => candidate.id == course.repeatedSemesterId,
        );
        if (course.originalMarks == null ||
            course.repeatedMarks == null ||
            course.originalCreditHours < 1 ||
            course.originalCreditHours > 6 ||
            course.repeatedCreditHours < 1 ||
            course.repeatedCreditHours > 6 ||
            course.repeatedSemesterId == semester.id ||
            repeatSemester.isEmpty ||
            repeatSemester.first.creditHours <= 0) {
          _showInputError(
            'Complete both grades, credit hours, and the repeat semester for every repeated course.',
            silent: silent,
          );
          return;
        }

        final originalPoints = GradingData.qualityPointsFor(
          obtainedMarks: course.originalMarks!,
          creditHours: course.originalCreditHours,
          scale: _gradingScale,
        );
        final repeatedPoints = GradingData.qualityPointsFor(
          obtainedMarks: course.repeatedMarks!,
          creditHours: course.repeatedCreditHours,
          scale: _gradingScale,
        );
        final excluded = GpaEngine.excludedRepeatAttempt(
          originalGradePoint: originalPoints / course.originalCreditHours,
          originalCreditHours: course.originalCreditHours,
          repeatedGradePoint: repeatedPoints / course.repeatedCreditHours,
          repeatedCreditHours: course.repeatedCreditHours,
        );
        repeats.add((
          semesterId: excluded.original
              ? semester.id
              : course.repeatedSemesterId!,
          qualityPoints: excluded.qualityPoints,
          hours: excluded.creditHours,
        ));
      }
    }

    final valid = _semesters.where((s) => s.creditHours > 0).toList();
    if (valid.isEmpty) {
      if (silent) {
        _validationError = null;
      } else {
        _showInputError(
          'Add at least one semester with a valid GPA and credit hours.',
        );
      }
      return;
    }
    final deductions = <String, ({double points, int hours})>{};
    for (final repeat in repeats) {
      final current = deductions[repeat.semesterId] ?? (points: 0.0, hours: 0);
      deductions[repeat.semesterId] = (
        points: current.points + repeat.qualityPoints,
        hours: current.hours + repeat.hours,
      );
    }
    for (final semester in valid) {
      final deduction = deductions[semester.id] ?? (points: 0.0, hours: 0);
      final semesterPoints =
          semester.qualityPoints ?? semester.gpa * semester.creditHours;
      if (deduction.hours > semester.creditHours ||
          deduction.points > semesterPoints + 1e-9) {
        _showInputError(
          'Repeated-course adjustments exceed the semester GPA or credit hours.',
          silent: silent,
        );
        return;
      }
    }
    final pairs = valid.map((semester) {
      final deduction = deductions[semester.id] ?? (points: 0.0, hours: 0);
      return (
        gpa: semester.qualityPoints != null && semester.creditHours > 0
            ? semester.qualityPoints! / semester.creditHours
            : semester.gpa,
        creditHours: semester.creditHours,
        deductedQualityPoints: deduction.points,
        deductedCreditHours: deduction.hours,
      );
    }).toList();
    setState(() {
      _validationError = null;
      _result = GpaEngine.calculateCgpa(pairs);
    });
  }

  Future<void> _save() async {
    if (_result == null) return;
    setState(() => _saving = true);
    final rawData = _semesters.map((s) => s.toJson()).toList();

    if (_isEditing) {
      final entry = widget.existingEntry!.copyWith(
        value: _result!.gpa,
        creditHours: _result!.totalCreditHours,
        qualityPoints: _result!.qualityPoints,
        gradingScale: _gradingScale,
        date: DateTime.now(),
        rawData: rawData,
      );
      await context.read<AppState>().updateHistory(entry);
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Updated in history')));
      Navigator.of(context).pop();
      return;
    }

    final entry = HistoryEntry(
      id: _nextId(),
      type: HistoryType.cgpa,
      title: 'Overall CGPA',
      value: _result!.gpa,
      creditHours: _result!.totalCreditHours,
      qualityPoints: _result!.qualityPoints,
      gradingScale: _gradingScale,
      date: DateTime.now(),
      rawData: rawData,
    );
    await context.read<AppState>().addHistory(entry);
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved to history')));
  }

  @override
  Widget build(BuildContext context) {
    final savedGpas = context.watch<AppState>().gpaHistory;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: 'Grading scale reference',
            onPressed: () => openGradingScaleReference(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          ScreenHeader(
            title: _isEditing ? 'Edit CGPA Calculation' : 'CGPA Calculator',
            subtitle: _isEditing
                ? 'Review or update this saved calculation.'
                : 'Compute your overall CGPA by entering semester details and '
                      'handling repeated courses efficiently.',
          ),
          if (_showRepeatTip)
            Dismissible(
              key: const ValueKey('repeat-course-tip'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => setState(() => _showRepeatTip = false),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'For a repeated or improved course, add it in the original semester, enter both grades, and select the repeat semester. The higher grade counts.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss tip',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _showRepeatTip = false),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          DropdownButtonFormField<GradingScale>(
            initialValue: _gradingScale,
            decoration: const InputDecoration(labelText: 'Admission batch'),
            items: GradingScale.values
                .map(
                  (scale) =>
                      DropdownMenuItem(value: scale, child: Text(scale.label)),
                )
                .toList(),
            onChanged: (scale) {
              if (scale != null) {
                setState(() {
                  _gradingScale = scale;
                  _result = null;
                  _validationError = null;
                });
              }
            },
          ),
          const SizedBox(height: 14),
          ..._semesters.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SemesterCard(
                key: ValueKey(
                  '${e.value.id}:${_formRevisions[e.value.id] ?? 0}:$_semesterListRevision',
                ),
                semester: e.value,
                semesters: _semesters,
                savedGpas: savedGpas,
                index: e.key,
                gradingScale: _gradingScale,
                onDelete: () => _removeSemester(e.value.id),
                onChanged: () => setState(() {
                  _result = null;
                  _validationError = null;
                }),
                onImportGpa: (entry) {
                  setState(() {
                    e.value.name = entry.title;
                    e.value.creditHours = entry.creditHours;
                    e.value.qualityPoints = entry.qualityPoints;
                    e.value.hasGpaInput = true;
                    e.value.hasCreditHoursInput = entry.creditHours > 0;
                    e.value.hasInvalidGpaInput = false;
                    e.value.hasInvalidCreditHoursInput = false;
                    e.value.gpa =
                        entry.qualityPoints != null && entry.creditHours > 0
                        ? entry.qualityPoints! / entry.creditHours
                        : entry.value;
                    _formRevisions[e.value.id] =
                        (_formRevisions[e.value.id] ?? 0) + 1;
                    _result = null;
                    _validationError = null;
                  });
                },
              ),
            ),
          ),
          if (_validationError != null)
            InputErrorBanner(message: _validationError!),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _addSemester,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Semester'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calculate CGPA'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            ResultCard(
              label: 'Your Overall CGPA',
              value: _result!.gpa,
              totalCreditHours: _result!.totalCreditHours,
            ),
            const SizedBox(height: 14),
            ShareResultButton(
              resultType: 'Overall CGPA',
              value: _result!.gpa,
              creditHours: _result!.totalCreditHours,
              details: ['Grading scale: ${_gradingScale.label}'],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isEditing
                          ? Icons.save_outlined
                          : Icons.bookmark_add_outlined,
                    ),
              label: Text(_isEditing ? 'Update History' : 'Save to History'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
