import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gpa_calculator_iuic/data/grading_data.dart';
import 'package:gpa_calculator_iuic/models/history_entry.dart';
import 'package:gpa_calculator_iuic/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('migrates old keys and skips corrupt history rows', () async {
    final entry = HistoryEntry(
      id: 'good',
      type: HistoryType.gpa,
      title: 'Semester',
      value: 3.2,
      creditHours: 15,
      date: DateTime(2026, 1, 1),
    );
    SharedPreferences.setMockInitialValues({
      'arid_calc_history_v1': [jsonEncode(entry.toJson()), '{broken'],
      'arid_calc_theme_v1': 'dark',
    });

    final history = await LocalStorage.instance.getHistory();
    final preferences = await SharedPreferences.getInstance();

    expect(history.map((saved) => saved.id), ['good']);
    expect(preferences.getStringList('iuic_calc_history_v1'), [
      jsonEncode(entry.toJson()),
    ]);
    expect(preferences.getStringList('arid_calc_history_v1'), isNull);
    expect(await LocalStorage.instance.getThemeMode(), 'dark');
  });

  test('persists the selected grading scale', () async {
    await LocalStorage.instance.setGradingScale(GradingScale.legacy.name);

    expect(await LocalStorage.instance.getGradingScale(), 'legacy');
  });

  test(
    'saving an unchanged CGPA calculation replaces its history entry',
    () async {
      final first = HistoryEntry(
        id: 'first',
        type: HistoryType.cgpa,
        title: 'Overall CGPA',
        value: 3.2,
        creditHours: 90,
        date: DateTime(2026, 1, 1),
        rawData: [
          {'id': 'semester-1', 'gpa': 3.2},
        ],
      );
      final second = first.copyWith(
        date: DateTime(2026, 1, 2),
        title: 'Overall CGPA',
      );
      final replacement = HistoryEntry(
        id: 'second',
        type: second.type,
        title: second.title,
        value: second.value,
        creditHours: second.creditHours,
        date: second.date,
        rawData: second.rawData,
      );

      await LocalStorage.instance.addEntry(first);
      await LocalStorage.instance.addEntry(replacement);

      final history = await LocalStorage.instance.getHistory();
      expect(history, hasLength(1));
      expect(history.single.id, 'second');
    },
  );
}
