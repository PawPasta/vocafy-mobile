import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_error_utils.dart';
import '../network/api_endpoints.dart';
import '../models/api_response.dart';
import '../models/feedback_item.dart';
import '../models/page_response.dart';

class FeedbackCreateResult {
  final bool success;
  final String message;

  const FeedbackCreateResult({required this.success, required this.message});
}

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._();
  static FeedbackService get instance => _instance;

  FeedbackService._();

  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  Future<PageResponse<AppFeedback>> listMyFeedbacks({
    int page = 0,
    int size = 10,
  }) async {
    _lastErrorMessage = null;
    try {
      final response = await api.get(
        '${Api.feedbacks}/me',
        params: {'page': page, 'size': size},
      );
      return _parseFeedbackPage(response.data);
    } catch (e) {
      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) {
        print('❌ listMyFeedbacks error: $e');
      }
      return _emptyPage();
    }
  }

  Future<PageResponse<AppFeedback>> listFeedbacks({
    int page = 0,
    int size = 10,
  }) async {
    _lastErrorMessage = null;
    try {
      final response = await api.get(
        Api.feedbacks,
        params: {'page': page, 'size': size},
      );
      return _parseFeedbackPage(response.data);
    } catch (e) {
      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) {
        print('❌ listFeedbacks error: $e');
      }
      return _emptyPage();
    }
  }

  Future<FeedbackCreateResult> createFeedback({
    required int rating,
    required String title,
    required String content,
  }) async {
    _lastErrorMessage = null;
    try {
      final response = await api.post(Api.feedbacks, {
        'rating': rating.clamp(1, 5).toInt(),
        'title': title.trim(),
        'content': content.trim(),
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        final message = (data['message'] ?? '').toString().trim();
        return FeedbackCreateResult(
          success: success,
          message: message.isEmpty
              ? (success
                    ? 'Feedback submitted successfully.'
                    : 'Unable to submit feedback.')
              : message,
        );
      }

      return const FeedbackCreateResult(
        success: false,
        message: 'Invalid response from server.',
      );
    } catch (e) {
      final message = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
        fallback: 'Unable to submit feedback.',
      );
      _lastErrorMessage = message;
      return FeedbackCreateResult(
        success: false,
        message: message ?? 'Unable to submit feedback.',
      );
    }
  }

  PageResponse<AppFeedback> _parseFeedbackPage(dynamic data) {
    if (data is! Map<String, dynamic>) return _emptyPage();

    final parsed = ApiResponse<PageResponse<AppFeedback>>.fromJson(data, (
      json,
    ) {
      if (json is! Map<String, dynamic>) return _emptyPage();
      return PageResponse<AppFeedback>.fromJson(
        json,
        (item) => AppFeedback.fromJson(item as Map<String, dynamic>),
      );
    });

    return parsed.result ?? _emptyPage();
  }

  PageResponse<AppFeedback> _emptyPage() {
    return const PageResponse<AppFeedback>(
      content: <AppFeedback>[],
      page: 0,
      size: 0,
      totalElements: 0,
      totalPages: 0,
      isFirst: true,
      isLast: true,
    );
  }
}

final feedbackService = FeedbackService.instance;


