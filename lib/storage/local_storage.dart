import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

const _kHistoryKey = 'arid_calc_history_v1';
const _kThemeKey = 'arid_calc_theme_v1';

class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();

  Future<List<HistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistoryKey) ?? [];
    final list = raw
        .map((e) => HistoryEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> addEntry(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistoryKey) ?? [];
    raw.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_kHistoryKey, raw);
  }

  /// Replaces the entry with a matching id, or appends it if not found.
  /// Used when a saved calculation is reopened, edited, and re-saved.
  Future<void> updateEntry(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistoryKey) ?? [];
    var found = false;
    final updated = raw.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      if (map['id'] == entry.id) {
        found = true;
        return jsonEncode(entry.toJson());
      }
      return e;
    }).toList();
    if (!found) updated.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_kHistoryKey, updated);
  }

  Future<void> deleteEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistoryKey) ?? [];
    final filtered = raw.where((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['id'] != id;
    }).toList();
    await prefs.setStringList(_kHistoryKey, filtered);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeKey);
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
