class Syllabus {
  final int id;
  final String title;
  final String description;
  final int totalDays;
  final String languageSet;
  final String visibility;
  final String sourceType;

  const Syllabus({
    required this.id,
    required this.title,
    required this.description,
    required this.totalDays,
    required this.languageSet,
    required this.visibility,
    required this.sourceType,
  });

  factory Syllabus.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    String asString(Object? v) => (v ?? '').toString();

    return Syllabus(
      id: asInt(json['id']),
      title: asString(json['title']),
      description: asString(json['description']),
      totalDays: asInt(json['total_days'] ?? json['totalDays']),
      languageSet: asString(json['language_set'] ?? json['languageSet']),
      visibility: asString(json['visibility']),
      sourceType: asString(json['source_type'] ?? json['sourceType']),
    );
  }
}
