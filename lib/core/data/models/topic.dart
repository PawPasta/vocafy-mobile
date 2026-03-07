/// Full Topic model from API
class Topic {
  final int id;
  final int? syllabusId;
  final String title;
  final String description;
  final int totalDays;
  final int sortOrder;
  final bool isActive;
  final bool isDeleted;
  final List<TopicCourse> courses;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Topic({
    required this.id,
    this.syllabusId,
    required this.title,
    required this.description,
    required this.totalDays,
    required this.sortOrder,
    required this.isActive,
    required this.isDeleted,
    required this.courses,
    this.createdAt,
    this.updatedAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    String asString(Object? v) => (v ?? '').toString();

    bool asBool(Object? v, {bool fallback = false}) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return fallback;
    }

    DateTime? asDateTime(Object? v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    final coursesJson = (json['courses'] is List) ? List.from(json['courses'] as List) : <dynamic>[];
    final courses = coursesJson
        .whereType<Map<String, dynamic>>()
        .map((c) => TopicCourse.fromJson(c))
        .toList();

    return Topic(
      id: asInt(json['id']),
      syllabusId: json['syllabus_id'] != null ? asInt(json['syllabus_id']) : null,
      title: asString(json['title']),
      description: asString(json['description']),
      totalDays: asInt(json['total_days']),
      sortOrder: asInt(json['sort_order']),
      isActive: asBool(json['is_active'], fallback: true),
      isDeleted: asBool(json['is_deleted'], fallback: false),
      courses: courses,
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}

/// Course nested in Topic
class TopicCourse {
  final int id;
  final int? topicId;
  final String title;
  final String description;
  final int sortOrder;
  final bool isActive;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TopicCourse({
    required this.id,
    this.topicId,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.isActive,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory TopicCourse.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    String asString(Object? v) => (v ?? '').toString();

    bool asBool(Object? v, {bool fallback = false}) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return fallback;
    }

    DateTime? asDateTime(Object? v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return TopicCourse(
      id: asInt(json['id']),
      topicId: json['topic_id'] != null ? asInt(json['topic_id']) : null,
      title: asString(json['title']),
      description: asString(json['description']),
      sortOrder: asInt(json['sort_order']),
      isActive: asBool(json['is_active'], fallback: true),
      isDeleted: asBool(json['is_deleted'], fallback: false),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}
