import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/scan_record.dart';
import 'home_providers.dart';

class ScanHistoryController extends AsyncNotifier<List<ScanRecord>> {
  static const _prefsKey = 'scan_history_products';

  @override
  Future<List<ScanRecord>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_prefsKey) ?? <String>[];

    return rawItems
        .map((item) {
          try {
            final decoded = jsonDecode(item) as Map<String, dynamic>;
            if (decoded.containsKey('product')) {
              return ScanRecord.fromJson(decoded);
            }

            final legacy = Product.fromJson(decoded);
            return ScanRecord(product: legacy, scannedAt: DateTime.now());
          } catch (_) {
            return null;
          }
        })
        .whereType<ScanRecord>()
        .toList();
  }

  Future<void> _persist(List<ScanRecord> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      items.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> addScan(Product product) async {
    final current = state.value ?? <ScanRecord>[];
    final record = ScanRecord(product: product, scannedAt: DateTime.now());
    final updated = [
      record,
      ...current.where((item) => item.product.id != product.id),
    ];
    final capped = updated.take(20).toList();

    state = AsyncValue.data(capped);
    await _persist(capped);
  }

  Future<Product?> addScanByBarcode(String barcode) async {
    final match = await ref
        .read(productRepositoryProvider)
        .fetchProductByBarcode(barcode);
    if (match == null) {
      return null;
    }
    await addScan(match);
    return match;
  }

  Future<void> clear() async {
    state = const AsyncValue.data(<ScanRecord>[]);
    await _persist(const <ScanRecord>[]);
  }

  Future<void> removeById(String id) async {
    final current = state.value ?? <ScanRecord>[];
    final updated = current.where((item) => item.product.id != id).toList();
    state = AsyncValue.data(updated);
    await _persist(updated);
  }
}
