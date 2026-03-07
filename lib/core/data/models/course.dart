/// Full Course model from API
class Course {
  final int id;
  final int? topicId;
  final String title;
  final String description;
  final int sortOrder;
  final bool isActive;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Course({
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

  factory Course.fromJson(Map<String, dynamic> json) {
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

    return Course(
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
