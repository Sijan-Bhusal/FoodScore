import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../models/product.dart';
import '../../models/scan_record.dart';
import '../../providers/scan_history_provider.dart';
import '../contribution/contribute_barcode_upload_screen.dart';
import '../product/product_detail_screen.dart';
import '../shared/product_history_card.dart';

class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.results,
  });

  final String query;
  final List<Product> results;

  Future<void> _openProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    await ref
        .read(scanHistoryProvider.notifier)
        .addRecord(ScanRecord(product: product, scannedAt: DateTime.now()));
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                _IconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                Text(
                  'Search Results',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '"$query" • ${results.length} found',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (results.isEmpty)
              _EmptyResultsCard(
                onContribute: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ContributeBarcodeUploadScreen(),
                    ),
                  );
                },
              )
            else
              Column(
                children: [
                  for (final product in results)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ProductHistoryCard(
                        product: product,
                        onTap: () => _openProduct(context, ref, product),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.onSurface),
      ),
    );
  }
}

class _EmptyResultsCard extends StatelessWidget {
  const _EmptyResultsCard({required this.onContribute});

  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No products found',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Help grow the database by contributing photos of this product.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onContribute,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Contribute Product'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
