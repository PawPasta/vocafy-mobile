import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/api_response.dart';
import '../models/page_response.dart';
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
      if (data is Map<String, dynamic> &&
          data['result'] is Map<String, dynamic>) {
        return Vocabulary.fromJson(data['result'] as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) print('❌ getVocabularyById error: $e');
    }
    return null;
  }

  /// List vocabularies by course ID
  Future<List<Vocabulary>> listVocabulariesByCourse(
    int courseId, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await api.get(
        '${Api.vocabulariesByCourse}/$courseId',
        params: {'page': page, 'size': size},
      );
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['result'] is Map<String, dynamic>) {
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

  /// List vocabularies saved by current user (from extension)
  /// GET /api/vocabularies/me?page=0&size=10
  Future<PageResponse<Vocabulary>> listMyVocabularies({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await api.get(
        '${Api.vocabularies}/me',
        params: {'page': page, 'size': size},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return const PageResponse<Vocabulary>(
          content: <Vocabulary>[],
          page: 0,
          size: 0,
          totalElements: 0,
          totalPages: 0,
          isFirst: true,
          isLast: true,
        );
      }

      final parsed = ApiResponse<PageResponse<Vocabulary>>.fromJson(data, (
        json,
      ) {
        if (json is! Map<String, dynamic>) {
          return const PageResponse<Vocabulary>(
            content: <Vocabulary>[],
            page: 0,
            size: 0,
            totalElements: 0,
            totalPages: 0,
            isFirst: true,
            isLast: true,
          );
        }
        return PageResponse<Vocabulary>.fromJson(
          json,
          (item) => Vocabulary.fromJson(item as Map<String, dynamic>),
        );
      });

      return parsed.result ??
          const PageResponse<Vocabulary>(
            content: <Vocabulary>[],
            page: 0,
            size: 0,
            totalElements: 0,
            totalPages: 0,
            isFirst: true,
            isLast: true,
          );
    } catch (e) {
      if (kDebugMode) {
        print('❌ listMyVocabularies error: $e');
      }
      return const PageResponse<Vocabulary>(
        content: <Vocabulary>[],
        page: 0,
        size: 0,
        totalElements: 0,
        totalPages: 0,
        isFirst: true,
        isLast: true,
      );
    }
  }
}

final vocabularyService = VocabularyService.instance;
