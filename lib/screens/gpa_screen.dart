import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../data/grading_data.dart';
import '../models/course.dart';
import '../models/history_entry.dart';
import '../widgets/input_cards.dart';
import '../widgets/result_card.dart';
import '../widgets/screen_header.dart';

int _seq = 0;
String _nextId() => 'c${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

class GpaScreen extends StatefulWidget {
  /// If provided, the screen opens pre-filled with this saved calculation's
  /// courses so the person can review or edit it. Saving again updates the
  /// same history entry instead of creating a new one.
  final HistoryEntry? existingEntry;

  const GpaScreen({super.key, this.existingEntry});

  @override
  State<GpaScreen> createState() => _GpaScreenState();
}

class _GpaScreenState extends State<GpaScreen> {
  late final TextEditingController _semesterController;
  final List<Course> _courses = [];
  GpaResult? _result;
  bool _saving = false;
  bool get _isEditing => widget.existingEntry != null;
  bool _isPercentageMode = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    if (entry != null) {
      _semesterController = TextEditingController(text: entry.title);
      final savedCourses = entry.courses;
      if (savedCourses.isNotEmpty) {
        _courses.addAll(savedCourses);
      } else {
        // Older history entries saved before per-course data was tracked —
        // fall back to a blank form under the same title.
        _addCourse();
        _addCourse();
      }
      // Show the result immediately since this is a revisit, not a fresh start.
      _calculate(silent: true);
    } else {
      _semesterController = TextEditingController(text: 'Semester');
      _addCourse();
      _addCourse();
    }
  }

  void _addCourse() {
    setState(() {
      _courses.add(Course(id: _nextId()));
      _result = null;
    });
  }

  void _removeCourse(String id) {
    setState(() {
      _courses.removeWhere((c) => c.id == id);
      _result = null;
    });
  }

  void _calculate({bool silent = false}) {
    if (!silent) FocusScope.of(context).unfocus();
    final valid = _courses.where((c) => c.creditHours > 0).toList();
    if (valid.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one valid course.'),
          ),
        );
      }
      return;
    }
    final pairs = valid
        .map((c) => (marks: c.obtainedMarks, creditHours: c.creditHours))
        .toList();
    setState(() => _result = GpaEngine.calculateGpa(pairs));
  }

  Future<void> _save() async {
    if (_result == null) return;
    setState(() => _saving = true);
    final title = _semesterController.text.trim().isEmpty
        ? 'Semester'
        : _semesterController.text.trim();
    final rawData = _courses.map((c) => c.toJson()).toList();

    if (_isEditing) {
      final entry = widget.existingEntry!.copyWith(
        title: title,
        value: _result!.gpa,
        creditHours: _result!.totalCreditHours,
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
      type: HistoryType.gpa,
      title: title,
      value: _result!.gpa,
      creditHours: _result!.totalCreditHours,
      date: DateTime.now(),
      rawData: rawData,
    );
    await context.read<AppState>().addHistory(entry);
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved to history')));
    setState(() {
      _result = null;
      _courses.clear();
      _addCourse();
      _addCourse();
    });
  }

  @override
  void dispose() {
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, title: const SizedBox.shrink()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          ScreenHeader(
            title: _isEditing ? 'Edit GPA Calculation' : 'GPA Calculator',
            subtitle: _isEditing
                ? 'Review or update this saved calculation.'
                : 'Calculate your semester grade point average with precision.',
          ),
          Text(
            'Semester label',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _semesterController,
            decoration: const InputDecoration(
              hintText: 'e.g. Fall Semester 2024',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Grades'),
                  value: false,
                  groupValue: _isPercentageMode,
                  onChanged: (val) {
                    if (val != null) setState(() => _isPercentageMode = val);
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Percentage'),
                  value: true,
                  groupValue: _isPercentageMode,
                  onChanged: (val) {
                    if (val != null) setState(() => _isPercentageMode = val);
                  },
                ),
              ),
            ],
          ),
          ..._courses.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CourseCard(
                course: e.value,
                index: e.key,
                isPercentageMode: _isPercentageMode,
                onDelete: () => _removeCourse(e.value.id),
                onChanged: () => setState(() => _result = null),
              ),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _addCourse,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Course'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: const StadiumBorder(),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calculate GPA'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            ResultCard(
              label: 'Your GPA',
              value: _result!.gpa,
              totalCreditHours: _result!.totalCreditHours,
            ),
            const SizedBox(height: 14),
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
