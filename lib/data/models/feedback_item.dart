class AppFeedback {
  final int id;
  final String userId;
  final String userDisplayName;
  final String userEmail;
  final int rating;
  final String title;
  final String content;
  final String adminReply;
  final String repliedByUserId;
  final String repliedByEmail;
  final DateTime? repliedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppFeedback({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.userEmail,
    required this.rating,
    required this.title,
    required this.content,
    required this.adminReply,
    required this.repliedByUserId,
    required this.repliedByEmail,
    required this.repliedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasAdminReply => adminReply.trim().isNotEmpty;

  factory AppFeedback.fromJson(Map<String, dynamic> json) {
    final ratingValue = _asInt(json['rating'], fallback: 5);
    return AppFeedback(
      id: _asInt(json['id']),
      userId: _asString(json['user_id'] ?? json['userId']),
      userDisplayName: _asString(
        json['user_display_name'] ?? json['userDisplayName'],
      ),
      userEmail: _asString(json['user_email'] ?? json['userEmail']),
      rating: ratingValue.clamp(1, 5).toInt(),
      title: _asString(json['title']),
      content: _asString(json['content']),
      adminReply: _asString(json['admin_reply'] ?? json['adminReply']),
      repliedByUserId: _asString(
        json['replied_by_user_id'] ?? json['repliedByUserId'],
      ),
      repliedByEmail: _asString(
        json['replied_by_email'] ?? json['repliedByEmail'],
      ),
      repliedAt: _asDate(json['replied_at'] ?? json['repliedAt']),
      createdAt: _asDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _asDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _asString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static DateTime? _asDate(Object? value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
