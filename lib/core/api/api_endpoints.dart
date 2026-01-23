/// API Configuration
/// Cấu hình đơn giản cho API
class Api {
  Api._();

  // ==================== Base URL ====================
  /// Base URL - Thay đổi domain ở đây
  static const String baseUrl = 'https://vocafy.milize-lena.space/api';

  // ==================== Auth Endpoints ====================
  static const String loginGoogle = '/auth/firebase';
  static const String logout = '/auth/logout';
  static const String profile = '/profiles/me';

  // ==================== User Endpoints ====================
  static const String users = '/users';

  // ==================== Vocabulary Endpoints ====================
  static const String vocabularies = '/vocabularies';

  // ==================== Lesson Endpoints ====================
  static const String lessons = '/lessons';
}
