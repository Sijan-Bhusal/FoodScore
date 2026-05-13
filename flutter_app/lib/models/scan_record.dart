import 'product.dart';

class ScanRecord {
  const ScanRecord({required this.product, required this.scannedAt});

  final Product product;
  final DateTime scannedAt;

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    return ScanRecord(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'scannedAt': scannedAt.toIso8601String(),
    };
  }
}
