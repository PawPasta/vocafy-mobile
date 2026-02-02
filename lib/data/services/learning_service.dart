import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/storage/token_storage.dart';
import '../models/learning_card.dart';
import 'enrollment_service.dart';

class LearningService {
  static final LearningService _instance = LearningService._();
  static LearningService get instance => _instance;

  LearningService._();

  /// Start learning and get learning cards
  /// 1. Check if the syllabus is the focused one
  /// 2. If not, update the focused enrollment
  /// 3. Call POST /api/learning-sets with { "course_id": 0 } (BE doesn't use courseId anymore)
  ///
  /// Returns LearningSet with cards if successful, null otherwise
  Future<LearningSet?> startLearning({
    int courseId = 0, // Default to 0, BE doesn't use this anymore
    required int syllabusId,
  }) async {
    try {
      // Check current focused syllabus ID from storage
      final focusedSyllabusId = await tokenStorage.getFocusedSyllabusId();

      // If the course's syllabus is not the focused one, update it
      if (focusedSyllabusId != syllabusId) {
        final success = await enrollmentService.setFocusedEnrollment(
          syllabusId,
        );
        if (success) {
          // Update local storage
          await tokenStorage.setFocusedSyllabusId(syllabusId);
        }
        if (kDebugMode) {
          print('📚 Updated focused syllabus to $syllabusId: $success');
        }
      }

      // Call learning-sets API
      final response = await api.post(Api.learningSets, {
        'course_id': courseId,
      });

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['result'] is Map<String, dynamic>) {
        final result = data['result'] as Map<String, dynamic>;
        final learningSet = LearningSet.fromJson(result);

        if (kDebugMode) {
          print(
            '📚 Got ${learningSet.cards.length} cards for course $courseId',
          );
        }

        return learningSet;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ startLearning error: $e');
      }
      return null;
    }
  }

  /// Complete learning for a list of vocabulary IDs
  /// POST /api/learning-sets/complete with { "vocab_ids": [...] }
  Future<bool> completeLearning(List<int> vocabIds) async {
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
      if (kDebugMode) {
        print('❌ completeLearning error: $e');
      }
      return false;
    }
  }
}

final learningService = LearningService.instance;
