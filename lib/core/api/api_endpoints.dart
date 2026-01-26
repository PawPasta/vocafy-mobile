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

  // ==================== Syllabus Endpoints ====================
  static const String syllabus = '/syllabus';

  // ==================== Topic Endpoints ====================
  static const String topics = '/topics';

  /// Dùng: '${Api.topicsBySyllabus}/$syllabusId'
  static const String topicsBySyllabus = '/topics/by-syllabus';

  // ==================== Course Endpoints ====================
  static const String courses = '/courses';

  /// Dùng: '${Api.coursesByTopic}/$topicId'
  static const String coursesByTopic = '/courses/by-topic';

  // ==================== Category Endpoints ====================
  static const String categories = '/categories';

  // ==================== Lesson Endpoints ====================
  static const String lessons = '/lessons';
}
