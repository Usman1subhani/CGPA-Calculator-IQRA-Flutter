import 'course.dart';
import 'semester_input.dart';

enum HistoryType { gpa, cgpa }

class HistoryEntry {
  final String id;
  final HistoryType type;
  final String title;
  final double value;
  final int creditHours;
  final DateTime date;

  /// The exact form data behind this result, so the GPA/CGPA screen can be
  /// reopened fully pre-filled for editing.
  /// - For [HistoryType.gpa]: a list of [Course].
  /// - For [HistoryType.cgpa]: a list of [SemesterInput].
  final List<Map<String, dynamic>> rawData;

  HistoryEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.value,
    required this.creditHours,
    required this.date,
    this.rawData = const [],
  });

  List<Course> get courses =>
      rawData.map((e) => Course.fromJson(e)).toList();

  List<SemesterInput> get semesters =>
      rawData.map((e) => SemesterInput.fromJson(e)).toList();

  HistoryEntry copyWith({
    double? value,
    int? creditHours,
    DateTime? date,
    List<Map<String, dynamic>>? rawData,
    String? title,
  }) {
    return HistoryEntry(
      id: id,
      type: type,
      title: title ?? this.title,
      value: value ?? this.value,
      creditHours: creditHours ?? this.creditHours,
      date: date ?? this.date,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'value': value,
        'creditHours': creditHours,
        'date': date.toIso8601String(),
        'rawData': rawData,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        type: HistoryType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => HistoryType.gpa,
        ),
        title: json['title'] as String,
        value: (json['value'] as num).toDouble(),
        creditHours: json['creditHours'] as int,
        date: DateTime.parse(json['date'] as String),
        rawData: (json['rawData'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}
