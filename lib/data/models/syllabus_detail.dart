class SyllabusCourse {
  final int id;
  final String title;
  final String description;

  SyllabusCourse({required this.id, required this.title, required this.description});

  factory SyllabusCourse.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }
    String asString(Object? v) => (v ?? '').toString();

    return SyllabusCourse(
      id: asInt(json['id']),
      title: asString(json['title']),
      description: asString(json['description']),
    );
  }
}

class SyllabusTopic {
  final int id;
  final String title;
  final String description;
  final int totalDays;
  final int sortOrder;
  final List<SyllabusCourse> courses;

  SyllabusTopic({required this.id, required this.title, required this.description, required this.totalDays, required this.sortOrder, required this.courses});

  factory SyllabusTopic.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }
    String asString(Object? v) => (v ?? '').toString();

    final coursesJson = (json['courses'] is List) ? List.from(json['courses'] as List) : <dynamic>[];
    final courses = coursesJson
        .whereType<Map<String, dynamic>>()
        .map((c) => SyllabusCourse.fromJson(c))
        .toList();

    return SyllabusTopic(
      id: asInt(json['id']),
      title: asString(json['title']),
      description: asString(json['description']),
      totalDays: asInt(json['total_days']),
      sortOrder: asInt(json['sort_order']),
      courses: courses,
    );
  }
}

class SyllabusDetail {
  final int id;
  final String title;
  final String description;
  final String imageBackground;
  final String imageIcon;
  final int totalDays;
  final String languageSet;
  final String categoryName;
  final List<SyllabusTopic> topics;

  SyllabusDetail({required this.id, required this.title, required this.description, required this.imageBackground, required this.imageIcon, required this.totalDays, required this.languageSet, required this.categoryName, required this.topics});

  factory SyllabusDetail.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }
    String asString(Object? v) => (v ?? '').toString();

    final topicsJson = (json['topics'] is List) ? List.from(json['topics'] as List) : <dynamic>[];
    final topics = topicsJson
        .whereType<Map<String, dynamic>>()
        .map((t) => SyllabusTopic.fromJson(t))
        .toList();

    return SyllabusDetail(
      id: asInt(json['id']),
      title: asString(json['title']),
      description: asString(json['description']),
      imageBackground: asString(json['image_background'] ?? json['imageBackground']),
      imageIcon: asString(json['image_icon'] ?? json['imageIcon']),
      totalDays: asInt(json['total_days'] ?? json['totalDays']),
      languageSet: asString(json['language_set'] ?? json['languageSet']),
      categoryName: asString(json['category_name'] ?? json['categoryName']),
      topics: topics,
    );
  }
}
