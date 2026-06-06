class InternetPlan {
  final int id;
  final String name;
  final String code;
  final double dataLimitGb;
  final double speedLimitMbps;
  final int validityDays;
  final double price;

  InternetPlan({
    required this.id,
    required this.name,
    required this.code,
    required this.dataLimitGb,
    required this.speedLimitMbps,
    required this.validityDays,
    required this.price,
  });

  factory InternetPlan.fromJson(Map<String, dynamic> json) {
    return InternetPlan(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      dataLimitGb: double.tryParse(json['data_limit_gb'].toString()) ?? 0,
      speedLimitMbps: double.tryParse(json['speed_limit_mbps'].toString()) ?? 0,
      validityDays: json['validity_days'] ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0,
    );
  }
}