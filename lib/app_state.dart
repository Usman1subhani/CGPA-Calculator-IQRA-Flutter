import 'package:flutter/material.dart';
import 'data/grading_data.dart';
import 'models/history_entry.dart';
import 'storage/local_storage.dart';

class AppState extends ChangeNotifier {
  List<HistoryEntry> _history = [];
  bool _loading = true;
  ThemeMode _themeMode = ThemeMode.system;
  GradingScale _gradingScale = GradingScale.spring2025;
  bool _settingsLoaded = false;
  bool _gradingScaleChangedBeforeLoad = false;

  List<HistoryEntry> get history => _history;
  bool get isLoading => _loading;
  ThemeMode get themeMode => _themeMode;
  GradingScale get gradingScale => _gradingScale;
  bool get settingsLoaded => _settingsLoaded;

  List<HistoryEntry> get gpaHistory =>
      _history.where((e) => e.type == HistoryType.gpa).toList();
  List<HistoryEntry> get cgpaHistory =>
      _history.where((e) => e.type == HistoryType.cgpa).toList();
  HistoryEntry? get latestCgpa =>
      cgpaHistory.isNotEmpty ? cgpaHistory.first : null;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    final savedTheme = await LocalStorage.instance.getThemeMode();
    final savedScale = await LocalStorage.instance.getGradingScale();
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedTheme,
      orElse: () => ThemeMode.system,
    );
    if (!_gradingScaleChangedBeforeLoad) {
      _gradingScale = GradingScale.values.firstWhere(
        (scale) => scale.name == savedScale,
        orElse: () => GradingScale.spring2025,
      );
    }
    _settingsLoaded = true;
    notifyListeners();
    await reloadHistory();
  }

  Future<void> reloadHistory() async {
    try {
      _history = await LocalStorage.instance.getHistory();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addHistory(HistoryEntry entry) async {
    await LocalStorage.instance.addEntry(entry);
    await reloadHistory();
  }

  Future<void> updateHistory(HistoryEntry entry) async {
    await LocalStorage.instance.updateEntry(entry);
    await reloadHistory();
  }

  Future<void> deleteHistory(String id) async {
    await LocalStorage.instance.deleteEntry(id);
    await reloadHistory();
  }

  Future<void> restoreHistory(HistoryEntry entry) async {
    await LocalStorage.instance.updateEntry(entry);
    await reloadHistory();
  }

  Future<void> clearHistory() async {
    await LocalStorage.instance.clearHistory();
    await reloadHistory();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await LocalStorage.instance.setThemeMode(mode.name);
  }

  Future<void> setGradingScale(GradingScale scale) async {
    if (!_settingsLoaded) _gradingScaleChangedBeforeLoad = true;
    _gradingScale = scale;
    notifyListeners();
    await LocalStorage.instance.setGradingScale(scale.name);
  }

  Future<void> resetAll() async {
    await LocalStorage.instance.resetAll();
    _themeMode = ThemeMode.system;
    _gradingScale = GradingScale.spring2025;
    _settingsLoaded = true;
    await reloadHistory();
  }
}
