import 'package:flutter/material.dart';

import '../../app/tokens.dart';
import '../../models/product.dart';

class SimilarProductsScreen extends StatelessWidget {
  const SimilarProductsScreen({super.key, required this.baseProduct});

  final Product baseProduct;

  @override
  Widget build(BuildContext context) {
    final alternatives = _buildAlternatives(baseProduct);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        title: const Text('Similar Products'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.qr_code_2)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _CurrentProductCard(product: baseProduct),
          const SizedBox(height: 16),
          _FilterChips(),
          const SizedBox(height: 12),
          for (final product in alternatives)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AlternativeCard(product: product),
            ),
        ],
      ),
    );
  }
}

class _CurrentProductCard extends StatelessWidget {
  const _CurrentProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              product.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 72,
                height: 72,
                color: AppColors.surfaceContainer,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  product.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _ScoreBadge(score: product.score),
        ],
      ),
    );
  }
}

class _FilterChips extends StatefulWidget {
  @override
  State<_FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<_FilterChips> {
  int _selected = 0;
  final List<String> _labels = const [
    'Best Match',
    'Lower Sugar',
    'High Protein',
    'Organic',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final isActive = index == _selected;
          return ChoiceChip(
            label: Text(_labels[index]),
            selected: isActive,
            onSelected: (_) => setState(() => _selected = index),
            selectedColor: AppColors.primaryContainer,
            labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isActive ? AppColors.onPrimary : AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: _labels.length,
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({required this.product});

  final _AlternativeProduct product;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(product.score);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  product.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 70,
                    height: 70,
                    color: AppColors.surfaceContainer,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              Positioned(
                bottom: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    product.score.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  product.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in product.tags) _TagChip(label: tag),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          score.toString(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

Color _scoreColor(int score) {
  if (score >= 80) return AppColors.good;
  if (score >= 60) return AppColors.primary;
  if (score >= 40) return AppColors.moderate;
  return AppColors.error;
}

List<_AlternativeProduct> _buildAlternatives(Product base) {
  return [
    _AlternativeProduct(
      name: 'Sprouted Oat Granola',
      subtitle: 'Low sugar, high fiber',
      score: 92,
      imageUrl: base.imageUrl,
      tags: const ['Organic', 'Nutri-Score A'],
    ),
    _AlternativeProduct(
      name: 'Blueberry Protein Bites',
      subtitle: 'Plant protein boost',
      score: 88,
      imageUrl: base.imageUrl,
      tags: const ['High Protein', 'Low Sodium'],
    ),
    _AlternativeProduct(
      name: 'Honey Almond Clusters',
      subtitle: 'Balanced macros',
      score: 82,
      imageUrl: base.imageUrl,
      tags: const ['Whole Grain', 'No Additives'],
    ),
  ];
}

class _AlternativeProduct {
  const _AlternativeProduct({
    required this.name,
    required this.subtitle,
    required this.score,
    required this.imageUrl,
    required this.tags,
  });

  final String name;
  final String subtitle;
  final int score;
  final String imageUrl;
  final List<String> tags;
}
