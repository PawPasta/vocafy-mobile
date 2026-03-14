class AppCategory {
  final int id;
  final String name;
  final String description;

  const AppCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    String asString(Object? v) => (v ?? '').toString();

    return AppCategory(
      id: asInt(json['id']),
      name: asString(json['name']),
      description: asString(json['description']),
    );
  }
}
