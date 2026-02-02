class Enrollment {
  final int id;
  final int syllabusId;
  final String syllabusTitle;
  final String syllabusDescription;
  final String imageBackground;
  final String imageIcon;
  final int totalDays;
  final String languageSet;
  final String categoryName;
  final String status;
  final int progress;
  final DateTime? enrolledAt;

  const Enrollment({
    required this.id,
    required this.syllabusId,
    required this.syllabusTitle,
    required this.syllabusDescription,
    required this.imageBackground,
    required this.imageIcon,
    required this.totalDays,
    required this.languageSet,
    required this.categoryName,
    required this.status,
    required this.progress,
    this.enrolledAt,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    String asString(Object? v) => (v ?? '').toString();

    DateTime? parseDate(Object? v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      final str = v.toString();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str);
    }

    // Handle nested syllabus object if present
    final syllabusData = json['syllabus'] as Map<String, dynamic>?;

    return Enrollment(
      id: asInt(json['id']),
      syllabusId: asInt(
        syllabusData?['id'] ?? json['syllabus_id'] ?? json['syllabusId'],
      ),
      syllabusTitle: asString(
        syllabusData?['title'] ??
            json['syllabus_title'] ??
            json['syllabusTitle'],
      ),
      syllabusDescription: asString(
        syllabusData?['description'] ??
            json['syllabus_description'] ??
            json['syllabusDescription'],
      ),
      imageBackground: asString(
        syllabusData?['image_background'] ??
            syllabusData?['imageBackground'] ??
            json['image_background'] ??
            json['imageBackground'],
      ),
      imageIcon: asString(
        syllabusData?['image_icon'] ??
            syllabusData?['imageIcon'] ??
            json['image_icon'] ??
            json['imageIcon'],
      ),
      totalDays: asInt(
        syllabusData?['total_days'] ??
            syllabusData?['totalDays'] ??
            json['total_days'] ??
            json['totalDays'],
      ),
      languageSet: asString(
        syllabusData?['language_set'] ??
            syllabusData?['languageSet'] ??
            json['language_set'] ??
            json['languageSet'],
      ),
      categoryName: asString(
        syllabusData?['category_name'] ??
            syllabusData?['categoryName'] ??
            json['category_name'] ??
            json['categoryName'],
      ),
      status: asString(json['status']),
      progress: asInt(json['progress']),
      enrolledAt: parseDate(
        json['enrolled_at'] ??
            json['enrolledAt'] ??
            json['created_at'] ??
            json['createdAt'],
      ),
    );
  }
}
