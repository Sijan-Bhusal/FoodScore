import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_record.dart';

final scanHistoryProvider =
    NotifierProvider<ScanHistoryNotifier, List<ScanRecord>>(
      ScanHistoryNotifier.new,
    );

class ScanHistoryNotifier extends Notifier<List<ScanRecord>> {
  static const _historyKey = 'scan_history';

  @override
  List<ScanRecord> build() {
    _loadHistory();
    return [];
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    state = historyJson
        .map((item) => ScanRecord.fromJson(jsonDecode(item)))
        .toList();
  }

  Future<void> addRecord(ScanRecord record) async {
    state = [record, ...state];
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = state.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_historyKey, historyJson);
  }
}
