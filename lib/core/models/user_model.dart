class ProfileModel {
  final String? userId;
  final String? displayName;
  final String? avatarUrl;
  final String? locale;
  final String? timezone;

  ProfileModel({
    this.userId,
    this.displayName,
    this.avatarUrl,
    this.locale,
    this.timezone,
  });

  factory ProfileModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ProfileModel();
    return ProfileModel(
      userId: json['user_id']?.toString(),
      displayName: json['display_name']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      locale: json['locale']?.toString(),
      timezone: json['timezone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'locale': locale,
        'timezone': timezone,
      };
}

class UserModel {
  final String? id;
  final String? email;
  final String? role;
  final String? status;
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;
  final ProfileModel? profile;
  final int? streakCount;
  final String? streakLastDate;

  UserModel({
    this.id,
    this.email,
    this.role,
    this.status,
    this.lastLoginAt,
    this.lastActiveAt,
    this.profile,
    this.streakCount,
    this.streakLastDate,
  });

  factory UserModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserModel();
    DateTime? parseDate(Object? v) {
      try {
        if (v == null) return null;
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return UserModel(
      id: json['id']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      lastLoginAt: parseDate(json['last_login_at']),
      lastActiveAt: parseDate(json['last_active_at']),
      profile: ProfileModel.fromJson(json['profile'] as Map<String, dynamic>?),
      streakCount: json['streak_count'] is int ? json['streak_count'] : int.tryParse('${json['streak_count'] ?? ''}'),
      streakLastDate: json['streak_last_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'status': status,
        'last_login_at': lastLoginAt?.toIso8601String(),
        'last_active_at': lastActiveAt?.toIso8601String(),
        'profile': profile?.toJson(),
        'streak_count': streakCount,
        'streak_last_date': streakLastDate,
      };
}
