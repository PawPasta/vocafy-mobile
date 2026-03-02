import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/api_response.dart';
import '../models/page_response.dart';
import '../models/enrollment.dart';

class EnrollmentService {
  static final EnrollmentService _instance = EnrollmentService._();
  static EnrollmentService get instance => _instance;

  EnrollmentService._();

  static const List<String> supportedTargetLanguages = <String>[
    'EN',
    'VI',
    'JA',
  ];

  /// Enroll in a syllabus
  /// POST /api/enrollments with
  /// { "syllabus_id": syllabusId, "preferred_target_language": "EN|VI|JA" }
  Future<bool> enrollSyllabus(
    int syllabusId, {
    String preferredTargetLanguage = 'EN',
  }) async {
    try {
      final response = await api.post(Api.enrollments, {
        'syllabus_id': syllabusId,
        'preferred_target_language': _normalizeTargetLanguage(
          preferredTargetLanguage,
        ),
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Check for success response
        return response.statusCode == 200 || response.statusCode == 201;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ enrollSyllabus error: $e');
      }
      return false;
    }
  }

  /// Update preferred target language for an enrolled syllabus
  /// PATCH /api/enrollments/preferred-target-language with
  /// { "syllabus_id": syllabusId, "preferred_target_language": "EN|VI|JA" }
  Future<bool> updatePreferredTargetLanguage({
    required int syllabusId,
    required String preferredTargetLanguage,
  }) async {
    try {
      final response = await api.patch(Api.enrollmentsPreferredTargetLanguage, {
        'syllabus_id': syllabusId,
        'preferred_target_language': _normalizeTargetLanguage(
          preferredTargetLanguage,
        ),
      });

      return (response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300;
    } catch (e) {
      if (kDebugMode) {
        print('❌ updatePreferredTargetLanguage error: $e');
      }
      return false;
    }
  }

  /// Get list of enrollments
  /// GET /api/enrollments?page=0&size=10
  Future<List<Enrollment>> listEnrollments({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await api.get(
        Api.enrollments,
        params: {'page': page, 'size': size},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return const <Enrollment>[];

      final parsed = ApiResponse<PageResponse<Enrollment>>.fromJson(data, (
        json,
      ) {
        if (json is! Map<String, dynamic>) {
          return const PageResponse<Enrollment>(
            content: <Enrollment>[],
            page: 0,
            size: 0,
            totalElements: 0,
            totalPages: 0,
            isFirst: true,
            isLast: true,
          );
        }
        return PageResponse<Enrollment>.fromJson(
          json,
          (item) => Enrollment.fromJson(item as Map<String, dynamic>),
        );
      });

      return parsed.result?.content ?? const <Enrollment>[];
    } catch (e) {
      if (kDebugMode) {
        print('❌ listEnrollments error: $e');
      }
      return const <Enrollment>[];
    }
  }

  /// Get focused enrollment
  /// GET /api/enrollments/focused
  Future<Enrollment?> getFocusedEnrollment() async {
    try {
      final response = await api.get('${Api.enrollments}/focused');

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['result'] is Map<String, dynamic>) {
        return Enrollment.fromJson(data['result'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ getFocusedEnrollment error: $e');
      }
      return null;
    }
  }

  String _normalizeTargetLanguage(String languageCode) {
    final normalized = languageCode.trim().toUpperCase();
    if (supportedTargetLanguages.contains(normalized)) {
      return normalized;
    }
    return 'EN';
  }
}

final enrollmentService = EnrollmentService.instance;
