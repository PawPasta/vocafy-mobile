class PremiumPackage {
  final int id;
  final String name;
  final String description;
  final int price;
  final int durationDays;
  final bool active;
  final DateTime? createdAt;

  const PremiumPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.active,
    this.createdAt,
  });

  factory PremiumPackage.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    DateTime? asDateTime(Object? v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return PremiumPackage(
      id: asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: asInt(json['price']),
      durationDays: asInt(json['duration_days'] ?? json['durationDays']),
      active: json['active'] == true,
      createdAt: asDateTime(json['created_at'] ?? json['createdAt']),
    );
  }
}
