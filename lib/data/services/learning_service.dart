import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/storage/token_storage.dart';
import '../models/learning_card.dart';
import 'enrollment_service.dart';

class LearningService {
  static final LearningService _instance = LearningService._();
  static LearningService get instance => _instance;

  // Prevent multiple concurrent PATCH calls when several learning flows start.
  static Future<void>? _focusUpdateInFlight;
  static int? _focusUpdateTargetSyllabusId;

  LearningService._();

  /// Start learning and get learning cards
  /// Logic:
  /// 1. Kiểm tra storage có focused syllabus ID không
  /// 2. Nếu KHÔNG có (null) → gọi PATCH để set focused enrollment + cập nhật storage
  /// 3. Nếu CÓ nhưng KHÁC syllabus đang học → gọi PATCH để đổi focused + cập nhật storage
  /// 4. Nếu CÓ và TRÙNG syllabus đang học → KHÔNG cần gọi PATCH
  /// 5. Gọi POST /api/learning-sets để lấy cards
  ///
  /// Returns LearningSet with cards if successful, null otherwise
  Future<LearningSet?> startLearning({
    int courseId = 0, // Default to 0, BE doesn't use this anymore
    required int syllabusId,
  }) async {
    try {
      await _ensureFocusedSyllabus(syllabusId);

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

  Future<void> _ensureFocusedSyllabus(int syllabusId) async {
    // Some call sites pass 0 when they don't know the syllabus.
    // Avoid spamming PATCH with invalid ids; server should use current focus.
    if (syllabusId <= 0) {
      if (kDebugMode) {
        print(
          '⚠️ startLearning called with syllabusId=$syllabusId; skip focus PATCH',
        );
      }
      return;
    }

    // If we haven't loaded focused enrollment yet (e.g., fast navigation after login),
    // try to fetch it once to prevent unnecessary PATCH.
    final isLoaded = await tokenStorage.isFocusedSyllabusLoaded();
    if (!isLoaded) {
      try {
        final focused = await enrollmentService.getFocusedEnrollment();
        await tokenStorage.setFocusedSyllabusId(focused?.syllabusId);
        await tokenStorage.setFocusedSyllabusLoaded(true);
      } catch (_) {
        // keep loaded=false so home/login can retry later
      }
    }

    while (true) {
      final focusedSyllabusId = await tokenStorage.getFocusedSyllabusId();
      if (focusedSyllabusId == syllabusId) {
        if (kDebugMode) {
          print('📚 Focused syllabus matches ($syllabusId) → no PATCH');
        }
        return;
      }

      final inFlight = _focusUpdateInFlight;
      if (inFlight != null) {
        // If the in-flight update is already targeting our syllabus, just await it.
        if (_focusUpdateTargetSyllabusId == syllabusId) {
          await inFlight;
          return;
        }

        // Otherwise, wait for current update to finish, then re-check.
        await inFlight;
        continue;
      }

      _focusUpdateTargetSyllabusId = syllabusId;
      _focusUpdateInFlight =
          () async {
            if (kDebugMode) {
              print('📚 PATCH focused enrollment → syllabusId=$syllabusId');
            }

            final success = await enrollmentService.setFocusedEnrollment(
              syllabusId,
            );
            if (success) {
              await tokenStorage.setFocusedSyllabusId(syllabusId);
            }

            if (kDebugMode) {
              print('📚 PATCH focused enrollment result: $success');
            }
          }().whenComplete(() {
            _focusUpdateInFlight = null;
            _focusUpdateTargetSyllabusId = null;
          });

      await _focusUpdateInFlight;
      return;
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
