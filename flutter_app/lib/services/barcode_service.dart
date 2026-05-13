import '../data/backend_data_source.dart';
import '../data/open_food_facts_data_source.dart';
import '../data/product_repository.dart';
import '../models/product.dart';

class BarcodeService {
  BarcodeService({ProductRepository? repository})
    : _repository =
          repository ??
          ProductRepository(BackendDataSource(), OpenFoodFactsDataSource());

  final ProductRepository _repository;

  Future<Product?> fetchProductByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) {
      return null;
    }

    try {
      return await _repository.fetchProductByBarcode(barcode.trim());
    } catch (_) {
      return null;
    }
  }
}
