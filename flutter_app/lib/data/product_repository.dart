import '../models/product.dart';
import 'backend_data_source.dart';
import 'open_food_facts_data_source.dart';

class ProductRepository {
  ProductRepository(this._backend, this._openFoodFacts);

  final BackendDataSource _backend;
  final OpenFoodFactsDataSource _openFoodFacts;

  Future<Product?> fetchProductByBarcode(String barcode) {
    return _fetchWithFallback(
      () => _backend.fetchProductByBarcode(barcode),
      () => _openFoodFacts.fetchProductByBarcode(barcode),
    );
  }

  Future<List<Product>> searchProducts(String query, {int limit = 12}) {
    return _searchWithFallback(
      () => _backend.searchProducts(query, limit: limit),
      () => _openFoodFacts.searchProducts(query, limit: limit),
    );
  }

  Future<Product?> _fetchWithFallback(
    Future<Product?> Function() primary,
    Future<Product?> Function() fallback,
  ) async {
    final backend = await primary();
    if (backend != null) {
      return backend;
    }
    return fallback();
  }

  Future<List<Product>> _searchWithFallback(
    Future<List<Product>> Function() primary,
    Future<List<Product>> Function() fallback,
  ) async {
    final backend = await primary();
    if (backend.isNotEmpty) {
      return backend;
    }
    return fallback();
  }
}
