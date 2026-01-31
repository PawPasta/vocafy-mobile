import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/course.dart';

class CourseService {
  static final CourseService _instance = CourseService._();
  static CourseService get instance => _instance;

  CourseService._();

  /// Get course by ID
  Future<Course?> getCourseById(int id) async {
    try {
      final response = await api.get('${Api.courses}/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['result'] is Map<String, dynamic>) {
        return Course.fromJson(data['result'] as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) print('❌ getCourseById error: $e');
    }
    return null;
  }

  /// List courses by topic ID
  Future<List<Course>> listCoursesByTopic(int topicId, {int page = 0, int size = 20}) async {
    try {
      final response = await api.get(
        '${Api.coursesByTopic}/$topicId',
        params: {'page': page, 'size': size},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['result'] is Map<String, dynamic>) {
        final result = data['result'] as Map<String, dynamic>;
        final content = result['content'];
        if (content is List) {
          return content
              .whereType<Map<String, dynamic>>()
              .map((json) => Course.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ listCoursesByTopic error: $e');
    }
    return const <Course>[];
  }
}

final courseService = CourseService.instance;
