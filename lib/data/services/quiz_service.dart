import '../../core/api/api_client.dart';
import '../models/quiz_question.dart';

class QuizService {
  QuizService._();
  static final QuizService _instance = QuizService._();
  static QuizService get instance => _instance;

  /// Lấy danh sách câu hỏi từ từ vựng đã học
  Future<List<QuizQuestion>> getLearnedQuestions() async {
    try {
      final response = await api.get('/vocabulary-questions/learned');
      final data = response.data;

      if (data is Map && data['success'] == true) {
        final result = data['result'];
        if (result is List) {
          return result.map((e) => QuizQuestion.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Submit câu trả lời và nhận kết quả
  /// Returns AnswerResult nếu thành công, null nếu thất bại
  Future<AnswerResult?> submitAnswer({
    required String questionType,
    required String refType,
    required int refId,
    required int answerId,
  }) async {
    try {
      final response = await api.post('/learning-progress/answer', {
        'question_type': questionType,
        'question_ref': {'type': refType, 'id': refId},
        'answer_id': answerId,
      });

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final result = data['result'];
        if (result is Map<String, dynamic>) {
          return AnswerResult.fromJson(result);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Singleton instance
final quizService = QuizService.instance;
