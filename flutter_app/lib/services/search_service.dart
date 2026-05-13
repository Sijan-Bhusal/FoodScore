import '../data/backend_data_source.dart';
import '../data/open_food_facts_data_source.dart';
import '../data/product_repository.dart';
import '../models/product.dart';

class SearchService {
  SearchService({ProductRepository? repository})
    : _repository =
          repository ??
          ProductRepository(BackendDataSource(), OpenFoodFactsDataSource());

  final ProductRepository _repository;

  Future<List<Product>> searchProducts(String query, {int limit = 12}) async {
    if (query.trim().isEmpty) {
      return <Product>[];
    }

    try {
      return await _repository.searchProducts(query.trim(), limit: limit);
    } catch (_) {
      return <Product>[];
    }
  }
}
