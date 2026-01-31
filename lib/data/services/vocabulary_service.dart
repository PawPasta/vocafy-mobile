import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/vocabulary.dart';

class VocabularyService {
  static final VocabularyService _instance = VocabularyService._();
  static VocabularyService get instance => _instance;

  VocabularyService._();

  /// Get vocabulary by ID
  Future<Vocabulary?> getVocabularyById(int id) async {
    try {
      final response = await api.get('${Api.vocabularies}/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['result'] is Map<String, dynamic>) {
        return Vocabulary.fromJson(data['result'] as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) print('❌ getVocabularyById error: $e');
    }
    return null;
  }

  /// List vocabularies by course ID
  Future<List<Vocabulary>> listVocabulariesByCourse(int courseId, {int page = 0, int size = 50}) async {
    try {
      final response = await api.get(
        '${Api.vocabulariesByCourse}/$courseId',
        params: {'page': page, 'size': size},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['result'] is Map<String, dynamic>) {
        final result = data['result'] as Map<String, dynamic>;
        final content = result['content'];
        if (content is List) {
          return content
              .whereType<Map<String, dynamic>>()
              .map((json) => Vocabulary.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ listVocabulariesByCourse error: $e');
    }
    return const <Vocabulary>[];
  }
}

final vocabularyService = VocabularyService.instance;
