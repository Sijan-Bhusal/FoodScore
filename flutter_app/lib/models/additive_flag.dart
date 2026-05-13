class AdditiveFlag {
  const AdditiveFlag({
    required this.name,
    required this.eNumber,
    required this.riskTier,
    required this.penalty,
  });

  final String name;
  final String eNumber;
  final String riskTier;
  final int penalty;

  factory AdditiveFlag.fromJson(Map<String, dynamic> json) {
    return AdditiveFlag(
      name:
          (json['name'] as String?) ??
          (json['ingredient'] as String?) ??
          'Unknown',
      eNumber: (json['e_number'] as String?) ?? 'N/A',
      riskTier: (json['risk'] as String?) ?? 'low',
      penalty: (json['penalty'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'e_number': eNumber,
      'risk': riskTier,
      'penalty': penalty,
    };
  }
}
