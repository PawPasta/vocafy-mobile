import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_error_utils.dart';
import '../network/api_endpoints.dart';
import '../models/learning_card.dart';

class LearningService {
  static final LearningService _instance = LearningService._();
  static LearningService get instance => _instance;

  LearningService._();

  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Start learning and get learning cards
  /// Gọi POST /api/learning-sets để lấy cards.
  ///
  /// Note: Server đã loại bỏ API PATCH /api/enrollments/focused nên client
  /// không còn thao tác set focused enrollment hay lưu focused syllabus vào storage.
  ///
  /// Returns LearningSet with cards if successful, null otherwise
  Future<LearningSet?> startLearning({required int syllabusId}) async {
    _lastErrorMessage = null;
    try {
      // Call learning-sets API
      final response = await api.post(Api.learningSets, {
        'syllabus_id': syllabusId,
      });

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['result'] is Map<String, dynamic>) {
        final result = data['result'] as Map<String, dynamic>;
        final learningSet = LearningSet.fromJson(result);

        if (kDebugMode) {
          print(
            '📚 Got ${learningSet.cards.length} cards for syllabus $syllabusId',
          );
        }

        return learningSet;
      }

      return null;
    } catch (e) {
      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) {
        print('❌ startLearning error: $e');
      }
      return null;
    }
  }

  /// Complete learning for a list of vocabulary IDs
  /// POST /api/learning-sets/complete with { "vocab_ids": [...] }
  Future<bool> completeLearning(List<int> vocabIds) async {
    _lastErrorMessage = null;
    try {
      final response = await api.post('${Api.learningSets}/complete', {
        'vocab_ids': vocabIds,
      });

      final statusCode = response.statusCode ?? 0;
      final success = statusCode >= 200 && statusCode < 300;

      if (kDebugMode) {
        print('📚 Complete learning for ${vocabIds.length} vocabs: $success');
      }

      return success;
    } catch (e) {
      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) {
        print('❌ completeLearning error: $e');
      }
      return false;
    }
  }
}

final learningService = LearningService.instance;


