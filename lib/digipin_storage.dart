import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'digipin_entry.dart';

class DigipinStorage {
  static const _key = 'digipin_list';

  static Future<List<DigipinEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => DigipinEntry.fromJson(json.decode(e))).toList();
  }

  static Future<void> save(List<DigipinEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final list = entries.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_key, list);
  }

  static Future<void> add(DigipinEntry entry) async {
    final entries = await load();
    // Avoid duplicates
    if (!entries.any((e) => e.digipin == entry.digipin)) {
      entries.add(entry);
      await save(entries);
    }
  }
}
