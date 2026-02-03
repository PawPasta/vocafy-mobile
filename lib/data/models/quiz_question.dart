/// Model for quiz question reference/option
class QuestionRef {
  final String type;
  final int id;
  final String? text;
  final String? url;

  const QuestionRef({
    required this.type,
    required this.id,
    this.text,
    this.url,
  });

  factory QuestionRef.fromJson(Map<String, dynamic> json) {
    return QuestionRef(
      type: json['type'] ?? '',
      id: json['id'] ?? 0,
      text: json['text'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'text': text,
    'url': url,
  };
}

/// Model for quiz question
class QuizQuestion {
  final String questionType;
  final String questionText;
  final QuestionRef? questionRef;
  final List<QuestionRef> options;
  final int difficultyLevel;

  const QuizQuestion({
    required this.questionType,
    required this.questionText,
    this.questionRef,
    required this.options,
    required this.difficultyLevel,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionType: json['question_type'] ?? '',
      questionText: json['question_text'] ?? '',
      questionRef: json['question_ref'] != null
          ? QuestionRef.fromJson(json['question_ref'])
          : null,
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => QuestionRef.fromJson(e))
              .toList() ??
          [],
      difficultyLevel: json['difficulty_level'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'question_type': questionType,
    'question_text': questionText,
    'question_ref': questionRef?.toJson(),
    'options': options.map((e) => e.toJson()).toList(),
    'difficulty_level': difficultyLevel,
  };
}

/// Model for answer submission result
class AnswerResult {
  final int vocabId;
  final bool isCorrect;
  final String prevState;
  final String newState;
  final int correctStreak;
  final int wrongStreak;

  const AnswerResult({
    required this.vocabId,
    required this.isCorrect,
    required this.prevState,
    required this.newState,
    required this.correctStreak,
    required this.wrongStreak,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    return AnswerResult(
      vocabId: json['vocab_id'] ?? 0,
      isCorrect: json['is_correct'] ?? false,
      prevState: json['prev_state'] ?? '',
      newState: json['new_state'] ?? '',
      correctStreak: json['correct_streak'] ?? 0,
      wrongStreak: json['wrong_streak'] ?? 0,
    );
  }
}
