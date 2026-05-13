import 'package:flutter/material.dart';

import '../../app/tokens.dart';
import '../../models/product.dart';

class ProductHistoryCard extends StatelessWidget {
  const ProductHistoryCard({
    super.key,
    required this.product,
    this.onTap,
    this.showInsightPreview = true,
  });

  final Product product;
  final VoidCallback? onTap;
  final bool showInsightPreview;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppColors.radiusMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                child: Image.network(
                  product.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.subtitle} • Score ${product.score}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _ScoreBadge(
                          label: 'NUTRI ${product.nutriScore}',
                          background: _nutriColor(product.nutriScore),
                          foreground: Colors.white,
                        ),
                        _ScoreBadge(
                          label: 'NOVA ${product.novaGroup}',
                          background: _novaColor(product.novaGroup),
                          foreground: Colors.white,
                        ),
                        _ScoreBadge(
                          label: 'ECO ${product.ecoScore}',
                          background: _ecoBackground(product.ecoScore),
                          foreground: _ecoForeground(product.ecoScore),
                        ),
                      ],
                    ),
                    if (showInsightPreview && product.insights.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        product.insights.first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ScorePill(score: product.score),
            ],
          ),
        ),
      ),
    );
  }

  Color _nutriColor(String value) {
    switch (value.toUpperCase()) {
      case 'A':
        return AppColors.success;
      case 'B':
        return AppColors.good;
      case 'C':
        return AppColors.moderate;
      case 'D':
        return AppColors.fair;
      default:
        return AppColors.poor;
    }
  }

  Color _novaColor(int value) {
    switch (value) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.good;
      case 3:
        return AppColors.moderate;
      default:
        return AppColors.poor;
    }
  }

  Color _ecoBackground(String value) {
    switch (value.toUpperCase()) {
      case 'A':
      case 'B':
        return const Color(0xFFD8F0DE);
      case 'C':
        return const Color(0xFFF8E0A8);
      case 'D':
      case 'E':
        return const Color(0xFFFFE3D8);
      default:
        return AppColors.surfaceContainer;
    }
  }

  Color _ecoForeground(String value) {
    switch (value.toUpperCase()) {
      case 'A':
      case 'B':
        return AppColors.additiveLow;
      case 'C':
        return AppColors.additiveMedium;
      case 'D':
      case 'E':
        return AppColors.additiveHigh;
      default:
        return AppColors.onSurface;
    }
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        score.toString(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _scoreColor(int value) {
    if (value <= 40) {
      return AppColors.fair;
    }
    if (value <= 70) {
      return AppColors.moderate;
    }
    return AppColors.success;
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
