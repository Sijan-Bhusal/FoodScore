import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backend_data_source.dart';
import '../data/open_food_facts_data_source.dart';
import '../data/product_repository.dart';
import '../models/scan_record.dart';
import 'scan_history_controller.dart';

final openFoodFactsDataSourceProvider = Provider<OpenFoodFactsDataSource>((
  ref,
) {
  return OpenFoodFactsDataSource();
});

final backendDataSourceProvider = Provider<BackendDataSource>((ref) {
  return BackendDataSource();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    ref.read(backendDataSourceProvider),
    ref.read(openFoodFactsDataSourceProvider),
  );
});

final scanHistoryProvider =
    AsyncNotifierProvider<ScanHistoryController, List<ScanRecord>>(
      ScanHistoryController.new,
    );
