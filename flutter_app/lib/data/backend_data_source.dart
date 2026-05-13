import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/app_config.dart';
import '../models/additive_flag.dart';
import '../models/nutrition_facts.dart';
import '../models/product.dart';

class BackendDataSource {
  BackendDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Product?> fetchProductByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/products/scan/$barcode');
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (payload['product_id'] == null) {
        return null;
      }

      return _mapBackendProduct(payload);
    } catch (_) {
      return null;
    }
  }

  Future<List<Product>> searchProducts(String query, {int limit = 12}) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/search',
      ).replace(queryParameters: <String, String>{'q': query});

      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return <Product>[];
      }

      final items = jsonDecode(response.body) as List<dynamic>;
      if (items.isEmpty) {
        return <Product>[];
      }

      final results = <Product>[];
      for (final item in items) {
        final productId =
            (item as Map<String, dynamic>)['product_id'] as String?;
        if (productId == null) {
          continue;
        }
        final detail = await _fetchProductById(productId);
        if (detail != null) {
          results.add(detail);
          if (results.length >= limit) {
            break;
          }
        }
      }

      return results;
    } catch (_) {
      return <Product>[];
    }
  }

  Future<Product?> _fetchProductById(String productId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/products/$productId');
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return _mapBackendProduct(payload);
    } catch (_) {
      return null;
    }
  }

  Product _mapBackendProduct(Map<String, dynamic> json) {
    final nutriments =
        json['nutriments'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    final nutrition = NutritionFacts(
      energyKcal: _numToInt(
        nutriments['energy-kcal_100g'] ?? nutriments['energy_kcal_100g'],
      ),
      sugarG: _numToInt(nutriments['sugars_100g']),
      fiberG: _numToInt(nutriments['fiber_100g']),
      fatG: _numToInt(nutriments['fat_100g']),
    );

    final flagsRaw =
        json['flagged_ingredients'] as List<dynamic>? ?? const <dynamic>[];
    final flags = flagsRaw
        .whereType<Map<String, dynamic>>()
        .map(AdditiveFlag.fromJson)
        .toList();

    return Product(
      id: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Product',
      subtitle: json['brand'] as String? ?? 'Unknown Brand',
      imageUrl:
          json['image_url'] as String? ??
          'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=800&q=80',
      score: (json['health_score'] as num?)?.toInt() ?? 0,
      nutriScore: (json['nutri_score'] as String? ?? 'C').toUpperCase(),
      novaGroup: (json['nova_group'] as num?)?.toInt() ?? 3,
      ecoScore: 'C',
      insights: _buildInsights(json['suggestion'] as String?, flags, nutrition),
      barcode: json['barcode'] as String? ?? '',
      nutrition: nutrition,
      category: json['category'] as String?,
      additives: _stringList(json['additives']),
      flaggedIngredients: flags,
      isHarmful: json['is_harmful'] as bool? ?? false,
      trafficLabel:
          (json['traffic_light'] as Map<String, dynamic>?)?['label'] as String?,
      source: json['source'] as String?,
    );
  }

  List<String> _stringList(dynamic input) {
    if (input is List) {
      return input.map((item) => item.toString()).toList();
    }
    return <String>[];
  }

  int _numToInt(dynamic value) {
    if (value is num) {
      return value.round();
    }
    return 0;
  }

  List<String> _buildInsights(
    String? suggestion,
    List<AdditiveFlag> flags,
    NutritionFacts nutrition,
  ) {
    final insights = <String>[];

    if (suggestion != null && suggestion.trim().isNotEmpty) {
      insights.add(suggestion.trim());
    }

    if (flags.isNotEmpty) {
      final highRisk = flags.where((flag) => flag.riskTier != 'low').length;
      insights.add(
        'Detected $highRisk additives with elevated risk tiers to review.',
      );
    }

    if (nutrition.sugarG >= 20) {
      insights.add(
        'High sugar density per 100g, moderate serving recommended.',
      );
    } else if (nutrition.sugarG <= 5) {
      insights.add('Low sugar content for this product category.');
    }

    if (nutrition.fiberG >= 5) {
      insights.add('Fiber content supports satiety and digestive health.');
    }

    if (insights.isEmpty) {
      insights.add(
        'Score reflects overall nutritional balance and processing.',
      );
    }

    return insights.take(3).toList();
  }
}
