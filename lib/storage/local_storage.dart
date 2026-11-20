import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

const _kHistoryKey = 'iuic_calc_history_v1';
const _kThemeKey = 'iuic_calc_theme_v1';
const _kGradingScaleKey = 'iuic_calc_grading_scale_v1';
const _kLegacyHistoryKey = 'arid_calc_history_v1';
const _kLegacyThemeKey = 'arid_calc_theme_v1';

class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();

  Future<List<HistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyKeys(prefs);
    final raw = prefs.getStringList(_kHistoryKey) ?? [];
    final list = <HistoryEntry>[];
    final validRaw = <String>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        list.add(HistoryEntry.fromJson(decoded));
        validRaw.add(entry);
      } on FormatException catch (error) {
        debugPrint('Skipping corrupt saved calculation: $error');
      } on TypeError catch (error) {
        debugPrint('Skipping invalid saved calculation: $error');
      } on ArgumentError catch (error) {
        debugPrint('Skipping invalid saved calculation: $error');
      }
    }
    if (validRaw.length != raw.length) {
      await prefs.setStringList(_kHistoryKey, validRaw);
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> addEntry(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getHistory();
    if (entry.type == HistoryType.cgpa) {
      final duplicateIndex = entries.indexWhere(
        (saved) =>
            saved.type == HistoryType.cgpa &&
            saved.gradingScale == entry.gradingScale &&
            saved.value == entry.value &&
            jsonEncode(saved.rawData) == jsonEncode(entry.rawData),
      );
      if (duplicateIndex != -1) {
        entries[duplicateIndex] = entry.copyWith(
          title: entries[duplicateIndex].title,
          date: entry.date,
        );
        await _writeHistory(prefs, entries);
        return;
      }
    }
    entries.add(entry);
    await _writeHistory(prefs, entries);
  }

  /// Replaces the entry with a matching id, or appends it if not found.
  /// Used when a saved calculation is reopened, edited, and re-saved.
  Future<void> updateEntry(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getHistory();
    final index = entries.indexWhere((saved) => saved.id == entry.id);
    if (index == -1) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
    await _writeHistory(prefs, entries);
  }

  Future<void> deleteEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getHistory();
    entries.removeWhere((entry) => entry.id == id);
    await _writeHistory(prefs, entries);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyKeys(prefs);
    await prefs.setString(_kThemeKey, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyKeys(prefs);
    return prefs.getString(_kThemeKey);
  }

  Future<String?> getGradingScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kGradingScaleKey);
  }

  Future<void> setGradingScale(String scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGradingScaleKey, scale);
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> _migrateLegacyKeys(SharedPreferences prefs) async {
    if (!prefs.containsKey(_kHistoryKey) &&
        prefs.containsKey(_kLegacyHistoryKey)) {
      final legacyHistory = prefs.getStringList(_kLegacyHistoryKey);
      if (legacyHistory != null) {
        await prefs.setStringList(_kHistoryKey, legacyHistory);
      }
      await prefs.remove(_kLegacyHistoryKey);
    }
    if (!prefs.containsKey(_kThemeKey) && prefs.containsKey(_kLegacyThemeKey)) {
      final legacyTheme = prefs.getString(_kLegacyThemeKey);
      if (legacyTheme != null) await prefs.setString(_kThemeKey, legacyTheme);
      await prefs.remove(_kLegacyThemeKey);
    }
  }

  Future<void> _writeHistory(
    SharedPreferences prefs,
    List<HistoryEntry> entries,
  ) async {
    await prefs.setStringList(
      _kHistoryKey,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }
}
