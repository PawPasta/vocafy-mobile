import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_error_utils.dart';
import '../network/api_endpoints.dart';
import '../models/topic.dart';

class TopicService {
  static final TopicService _instance = TopicService._();
  static TopicService get instance => _instance;

  TopicService._();

  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Get topic by ID
  Future<Topic?> getTopicById(int id) async {
    _lastErrorMessage = null;
    try {
      final response = await api.get('${Api.topics}/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['result'] is Map<String, dynamic>) {
        return Topic.fromJson(data['result'] as Map<String, dynamic>);
      }
    } catch (e) {
      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) print('❌ getTopicById error: $e');
    }
    return null;
  }

  /// List topics by syllabus ID
  Future<List<Topic>> listTopicsBySyllabus(int syllabusId, {int page = 0, int size = 20}) async {
    _lastErrorMessage = null;
    try {
      final response = await api.get(
        '${Api.topicsBySyllabus}/$syllabusId',
        params: {'page': page, 'size': size},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['result'] is Map<String, dynamic>) {
        final result = data['result'] as Map<String, dynamic>;
        final content = result['content'];
        if (content is List) {
          return content
              .whereType<Map<String, dynamic>>()
              .map((json) => Topic.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) print('❌ listTopicsBySyllabus error: $e');
    }
    return const <Topic>[];
  }
}

final topicService = TopicService.instance;


