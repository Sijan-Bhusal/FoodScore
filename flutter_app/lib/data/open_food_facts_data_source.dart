import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nutrition_facts.dart';
import '../models/product.dart';

class OpenFoodFactsDataSource {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const _searchUrl = 'https://world.openfoodfacts.org/cgi/search.pl';

  final http.Client _client;

  OpenFoodFactsDataSource({http.Client? client})
    : _client = client ?? http.Client();

  Future<Product?> fetchProductByBarcode(String barcode) async {
    final uri = Uri.parse('$_baseUrl/$barcode.json');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (body['status'] as num?)?.toInt() ?? 0;
    if (status != 1) {
      return null;
    }

    final productJson = body['product'] as Map<String, dynamic>?;
    if (productJson == null) {
      return null;
    }

    return _mapOpenFoodFactsProduct(productJson, fallbackBarcode: barcode);
  }

  Future<List<Product>> searchProducts(String query, {int limit = 12}) async {
    final uri = Uri.parse(_searchUrl).replace(
      queryParameters: <String, String>{
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '$limit',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return <Product>[];
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final productsJson = body['products'] as List<dynamic>? ?? <dynamic>[];

    return productsJson
        .whereType<Map<String, dynamic>>()
        .map((item) => _mapOpenFoodFactsProduct(item))
        .whereType<Product>()
        .toList();
  }

  Product? _mapOpenFoodFactsProduct(
    Map<String, dynamic> productJson, {
    String? fallbackBarcode,
  }) {
    final barcode = (productJson['code'] as String?)?.trim().isNotEmpty == true
        ? (productJson['code'] as String).trim()
        : (fallbackBarcode ?? '').trim();

    final productName =
        (productJson['product_name'] as String?)?.trim().isNotEmpty == true
        ? (productJson['product_name'] as String).trim()
        : 'Unknown Product';

    final brands = (productJson['brands'] as String?)?.trim().isNotEmpty == true
        ? (productJson['brands'] as String).trim()
        : 'OpenFoodFacts';

    final imageUrl =
        (productJson['image_front_small_url'] as String?)?.trim().isNotEmpty ==
            true
        ? (productJson['image_front_small_url'] as String).trim()
        : ((productJson['image_front_url'] as String?)?.trim().isNotEmpty ==
                  true
              ? (productJson['image_front_url'] as String).trim()
              : 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=800&q=80');

    final category = (productJson['categories'] as String?)
        ?.split(',')
        .first
        .trim();

    final additives =
        (productJson['additives_tags'] as List<dynamic>? ?? <dynamic>[])
            .map((item) => item.toString().replaceAll('en:', '').toUpperCase())
            .toList();

    final nutriments =
        productJson['nutriments'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    final nutrition = NutritionFacts(
      energyKcal: _numToInt(nutriments['energy-kcal_100g']),
      sugarG: _numToInt(nutriments['sugars_100g']),
      fiberG: _numToInt(nutriments['fiber_100g']),
      fatG: _numToInt(nutriments['fat_100g']),
    );

    final nutriScore = ((productJson['nutriscore_grade'] as String?) ?? 'c')
        .toUpperCase();
    final novaGroup = _numToInt(productJson['nova_group']).clamp(1, 4);
    final ecoScore = ((productJson['ecoscore_grade'] as String?) ?? 'c')
        .toUpperCase();

    final score = _calculateCompositeScore(
      nutriScore: nutriScore,
      novaGroup: novaGroup,
      nutrition: nutrition,
    );

    final id = barcode.isNotEmpty
        ? barcode
        : '${productName}_$brands'.replaceAll(' ', '_').toLowerCase();

    return Product(
      id: id,
      name: productName,
      subtitle: brands,
      imageUrl: imageUrl,
      score: score,
      nutriScore: nutriScore,
      novaGroup: novaGroup,
      ecoScore: ecoScore,
      insights: _buildInsights(
        nutriScore: nutriScore,
        novaGroup: novaGroup,
        nutrition: nutrition,
      ),
      barcode: barcode,
      nutrition: nutrition,
      category: category?.isEmpty == true ? null : category,
      additives: additives,
      trafficLabel: _trafficLabel(score),
      source: 'openfoodfacts',
    );
  }

  int _numToInt(dynamic value) {
    if (value is num) {
      return value.round();
    }
    return 0;
  }

  int _calculateCompositeScore({
    required String nutriScore,
    required int novaGroup,
    required NutritionFacts nutrition,
  }) {
    final nutriBase = switch (nutriScore) {
      'A' => 92,
      'B' => 78,
      'C' => 60,
      'D' => 42,
      'E' => 26,
      _ => 55,
    };

    final novaPenalty = switch (novaGroup) {
      1 => 0,
      2 => 6,
      3 => 12,
      _ => 18,
    };

    var score = nutriBase - novaPenalty;
    if (nutrition.sugarG >= 20) {
      score -= 8;
    }
    if (nutrition.fiberG >= 5) {
      score += 6;
    }

    if (score < 0) {
      return 0;
    }
    if (score > 100) {
      return 100;
    }
    return score;
  }

  List<String> _buildInsights({
    required String nutriScore,
    required int novaGroup,
    required NutritionFacts nutrition,
  }) {
    final insights = <String>[
      'Nutri-Score $nutriScore and NOVA $novaGroup reflect overall quality and processing level.',
    ];

    if (nutrition.sugarG >= 20) {
      insights.add(
        'High sugar density per 100g, moderate serving size is recommended.',
      );
    } else if (nutrition.sugarG <= 5) {
      insights.add('Low sugar content for this product category.');
    }

    if (nutrition.fiberG >= 5) {
      insights.add(
        'Fiber content is supportive for satiety and digestive health.',
      );
    } else {
      insights.add(
        'Fiber content is limited, pair with whole foods for balance.',
      );
    }

    if (nutrition.fatG >= 17) {
      insights.add('Energy-dense fat profile, keep portions intentional.');
    }

    return insights.take(3).toList();
  }

  String _trafficLabel(int score) {
    if (score == 0) {
      return 'Harmful — avoid';
    }
    if (score <= 40) {
      return 'Poor';
    }
    if (score <= 70) {
      return 'Moderate';
    }
    return 'Good';
  }
}
