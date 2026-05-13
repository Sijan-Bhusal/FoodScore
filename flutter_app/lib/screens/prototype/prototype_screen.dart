import 'package:flutter/material.dart';

import '../../app/tokens.dart';
import '../../models/nutrition_facts.dart';
import '../../models/product.dart';
import '../contribution/contribute_barcode_upload_screen.dart';
import '../history/history_recommendations_screen.dart';
import '../product/product_detail_screen.dart';
import '../product/similar_products_screen.dart';
import '../profile/profile_setup_screen.dart';
import '../scanner/scanner_screen.dart';

class PrototypeScreen extends StatelessWidget {
  const PrototypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleProduct = _sampleProduct();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Prototype Flow')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              'Quick navigation to all screens',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Use this hub to preview the implemented UI screens.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _NavCard(
              title: 'Scanner',
              subtitle: 'Barcode scanning flow',
              onTap: () => _open(context, const ScannerScreen()),
            ),
            _NavCard(
              title: 'Product Detail - Yuka Style',
              subtitle: 'Health score and nutrition breakdown',
              onTap: () =>
                  _open(context, ProductDetailScreen(product: sampleProduct)),
            ),
            _NavCard(
              title: 'Similar Products',
              subtitle: 'Alternative product list',
              onTap: () => _open(
                context,
                SimilarProductsScreen(baseProduct: sampleProduct),
              ),
            ),
            _NavCard(
              title: 'Scan History Recommendations',
              subtitle: 'Suggested swaps and stats',
              onTap: () => _open(context, const HistoryRecommendationsScreen()),
            ),
            _NavCard(
              title: 'Contribute Product - Barcode Upload',
              subtitle: 'Step 1 of contribution flow',
              onTap: () =>
                  _open(context, const ContributeBarcodeUploadScreen()),
            ),
            _NavCard(
              title: 'Profile Setup - Refined',
              subtitle: 'Personalization details',
              onTap: () => _open(context, const ProfileSetupScreen()),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Product _sampleProduct() {
    return Product(
      id: 'sample-1',
      name: 'Almond Milk Unsweetened',
      subtitle: 'Oatly',
      imageUrl:
          'https://images.unsplash.com/photo-1512149544339-96b1a4a0a45b?auto=format&fit=crop&w=800&q=80',
      score: 88,
      nutriScore: 'A',
      novaGroup: 2,
      ecoScore: 'B',
      insights: const [
        'Low sugar, good fiber balance.',
        'Minimal processing and clean ingredients.',
      ],
      barcode: '000000000001',
      nutrition: const NutritionFacts(
        energyKcal: 42,
        sugarG: 2,
        fiberG: 3,
        fatG: 2,
      ),
      category: 'Plant-based beverages',
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusMedium),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_forward, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
