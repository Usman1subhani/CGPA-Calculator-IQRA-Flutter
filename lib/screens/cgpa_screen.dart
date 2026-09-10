import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../data/grading_data.dart';
import '../models/history_entry.dart';
import '../models/semester_input.dart';
import '../widgets/input_cards.dart';
import '../widgets/result_card.dart';
import '../widgets/screen_header.dart';

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

class _CgpaScreenState extends State<CgpaScreen>
    with SingleTickerProviderStateMixin {
  final List<SemesterInput> _semesters = [];
  GpaResult? _result;
  bool _saving = false;
  bool get _isEditing => widget.existingEntry != null;

  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    final entry = widget.existingEntry;
    if (entry != null) {
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

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _addSemester() {
    setState(() {
      _semesters.add(
        SemesterInput(id: _nextId(), name: 'Semester ${_semesters.length + 1}'),
      );
      _result = null;
    });
  }

  void _removeSemester(String id) {
    setState(() {
      _semesters.removeWhere((s) => s.id == id);
      _result = null;
    });
  }

  void _calculate({bool silent = false}) {
    if (!silent) FocusScope.of(context).unfocus();
    final valid = _semesters
        .where((s) => s.creditHours > 0 && s.gpa >= 0 && s.gpa <= 4)
        .toList();
    if (valid.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please add valid semester GPA (0-4) and credit hours.',
            ),
          ),
        );
      }
      return;
    }
    final pairs = valid
        .map(
          (s) => (
            gpa: s.gpa,
            creditHours: s.creditHours,
            deductedQualityPoints: s.deductedQualityPoints,
            deductedCreditHours: s.deductedCreditHours,
          ),
        )
        .toList();
    setState(() => _result = GpaEngine.calculateCgpa(pairs));
  }

  Future<void> _save() async {
    if (_result == null) return;
    setState(() => _saving = true);
    final rawData = _semesters.map((s) => s.toJson()).toList();

    if (_isEditing) {
      final entry = widget.existingEntry!.copyWith(
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
      type: HistoryType.cgpa,
      title: 'Overall CGPA',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, title: const SizedBox.shrink()),
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
          AnimatedBuilder(
            animation: _blinkController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: _blinkController.value,
                    ),
                    width: 1.5,
                  ),
                ),
                child: child,
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: const [
                        TextSpan(text: 'If you repeated a failed course or improved a grade later, tap '),
                        TextSpan(text: '"Add repeated course"', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: ' in the original semester. We\'ll exclude the old attempt automatically per policy.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ..._semesters.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SemesterCard(
                semester: e.value,
                index: e.key,
                onDelete: () => _removeSemester(e.value.id),
                onChanged: () => setState(() => _result = null),
              ),
            ),
          ),
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
