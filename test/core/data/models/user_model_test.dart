import 'package:flutter_test/flutter_test.dart';
import 'package:vocafy_mobile/core/data/models/user_model.dart';

void main() {
  group('ProfileModel.fromJson', () {
    test('parses profile fields', () {
      final profile = ProfileModel.fromJson({
        'user_id': 12,
        'display_name': 'Alex',
        'avatar_url': 'https://cdn/avatar.png',
        'locale': 'vi-VN',
        'timezone': 'Asia/Ho_Chi_Minh',
      });

      expect(profile.userId, '12');
      expect(profile.displayName, 'Alex');
      expect(profile.avatarUrl, 'https://cdn/avatar.png');
      expect(profile.locale, 'vi-VN');
      expect(profile.timezone, 'Asia/Ho_Chi_Minh');
    });

    test('returns empty model for null json', () {
      final profile = ProfileModel.fromJson(null);
      expect(profile.userId, isNull);
      expect(profile.displayName, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.locale, isNull);
      expect(profile.timezone, isNull);
    });
  });

  group('UserModel.fromJson', () {
    test('parses valid payload', () {
      final user = UserModel.fromJson({
        'id': 1,
        'email': 'user@example.com',
        'role': 'learner',
        'status': 'active',
        'last_login_at': '2026-04-01T10:20:30Z',
        'last_active_at': '2026-04-02T10:20:30Z',
        'streak_count': 7,
        'streak_last_date': '2026-04-02',
        'profile': {
          'user_id': '1',
          'display_name': 'User One',
        },
      });

      expect(user.id, '1');
      expect(user.email, 'user@example.com');
      expect(user.role, 'learner');
      expect(user.status, 'active');
      expect(user.lastLoginAt, DateTime.parse('2026-04-01T10:20:30Z'));
      expect(user.lastActiveAt, DateTime.parse('2026-04-02T10:20:30Z'));
      expect(user.streakCount, 7);
      expect(user.streakLastDate, '2026-04-02');
      expect(user.profile?.displayName, 'User One');
    });

    test('handles invalid dates and string streak count', () {
      final user = UserModel.fromJson({
        'last_login_at': 'invalid-date',
        'last_active_at': null,
        'streak_count': '15',
      });

      expect(user.lastLoginAt, isNull);
      expect(user.lastActiveAt, isNull);
      expect(user.streakCount, 15);
    });

    test('returns empty model for null input', () {
      final user = UserModel.fromJson(null);
      expect(user.id, isNull);
      expect(user.email, isNull);
      expect(user.profile?.userId, isNull);
      expect(user.streakCount, isNull);
    });
  });
}

