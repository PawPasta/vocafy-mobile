import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/models/quiz_question.dart';
import '../../data/services/quiz_service.dart';
import 'pronunciation_challenge_dialog.dart';

class QuizScreen extends StatefulWidget {
  final int? syllabusId;
  final String? syllabusTitle;

  const QuizScreen({Key? key, this.syllabusId, this.syllabusTitle})
    : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  List<QuizQuestion> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _hasAnswered = false;
  int _correctAnswers = 0;

  // Stage tracking (4 stages)
  int _currentStage = 1;
  List<int> _stageEndIndices = []; // End indices for each stage
  int _stageCorrectAnswers = 0; // Correct answers in current stage

  // Pronunciation challenge tracking
  List<String> _stageTermsForPronunciation =
      []; // Terms from LOOK_TERM_SELECT_MEANING in current stage

  // Streak tracking
  int _currentCorrectStreak = 0;
  int _currentWrongStreak = 0;
  int _maxCorrectStreak = 0;
  int _maxWrongStreak = 0;
  AnswerResult? _lastResult;

  // Input-answer (no options shown) for certain question types
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  String? _inputError;
  int _inputMismatchAttempts = 0;

  final FlutterTts _tts = FlutterTts();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _streakController;
  late Animation<double> _streakAnimation;

  static const _primaryBlue = Color(0xFF4F6CFF);
  static const _correctGreen = Color(0xFF4CAF50);
  static const _wrongRed = Color(0xFFE53935);
  static const _optionBg = Color(0xFFF5F7FF);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _streakAnimation = CurvedAnimation(
      parent: _streakController,
      curve: Curves.elasticOut,
    );
    _tts.setLanguage('ja-JP');
    _loadQuestions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _streakController.dispose();
    _answerController.dispose();
    _answerFocusNode.dispose();
    _tts.stop();
    super.dispose();
  }

  String _normalizeAnswer(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final questions = await quizService.getLearnedQuestions().timeout(
        const Duration(seconds: 12),
      );
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Chưa có câu hỏi nào. Hãy học thêm từ vựng trước!';
        });
      } else {
        // Calculate stage end indices
        final stageIndices = _calculateStageIndices(questions.length);
        setState(() {
          _questions = questions;
          _stageEndIndices = stageIndices;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không thể tải câu hỏi. Vui lòng thử lại.';
      });
    }
  }

  /// Calculate stage end indices (0-based, inclusive)
  /// Stage 1 minimum 3 questions, stages are distributed so that:
  /// Stage 1 <= Stage 2 <= Stage 3 <= Stage 4
  List<int> _calculateStageIndices(int totalQuestions) {
    if (totalQuestions < 3) {
      // Not enough for staging, just one stage
      return [totalQuestions - 1];
    }

    // Minimum 3 questions for stage 1
    const minStage1 = 3;

    if (totalQuestions <= 6) {
      // If 3-6 questions, use 2 stages
      final stage1 = minStage1;
      return [stage1 - 1, totalQuestions - 1];
    }

    if (totalQuestions <= 10) {
      // If 7-10 questions, use 3 stages
      final stage1 = minStage1;
      final remaining = totalQuestions - stage1;
      final stage2 = stage1 + (remaining ~/ 2);
      return [stage1 - 1, stage2 - 1, totalQuestions - 1];
    }

    // For 11+ questions, use 4 stages
    // Distribute so that stage1 <= stage2 <= stage3 <= stage4
    // Use a formula to gradually increase stage sizes
    final remaining = totalQuestions - minStage1;

    // Calculate proportions: 1:1.5:2:2.5 = 1:1.5:2:2.5 = total 7 parts for remaining
    // But we need stage1 <= stage2 <= stage3 <= stage4
    // Let's use equal distribution of remaining, then adjust

    final baseSize =
        remaining ~/ 3; // Divide remaining into ~3 parts for stages 2,3,4

    int stage1Count = minStage1;
    int stage2Count = baseSize;
    int stage3Count = baseSize;
    int stage4Count = remaining - stage2Count - stage3Count;

    // Ensure stage1 <= stage2 <= stage3 <= stage4
    // Redistribute if needed
    if (stage2Count < stage1Count) stage2Count = stage1Count;
    if (stage3Count < stage2Count) stage3Count = stage2Count;
    if (stage4Count < stage3Count) {
      // Recalculate with adjustment
      stage4Count = totalQuestions - stage1Count - stage2Count - stage3Count;
    }

    final end1 = stage1Count - 1;
    final end2 = end1 + stage2Count;
    final end3 = end2 + stage3Count;
    final end4 = totalQuestions - 1;

    return [end1, end2, end3, end4];
  }

  /// Get current stage end index
  int get _currentStageEndIndex {
    if (_stageEndIndices.isEmpty) return _questions.length - 1;
    if (_currentStage > _stageEndIndices.length) return _questions.length - 1;
    return _stageEndIndices[_currentStage - 1];
  }

  /// Get current stage start index
  int get _currentStageStartIndex {
    if (_currentStage <= 1) return 0;
    if (_stageEndIndices.isEmpty) return 0;
    return _stageEndIndices[_currentStage - 2] + 1;
  }

  /// Get questions count for current stage
  int get _currentStageQuestionsCount {
    return _currentStageEndIndex - _currentStageStartIndex + 1;
  }

  /// Check if current question is the last in current stage
  bool get _isLastQuestionInStage {
    return _currentIndex >= _currentStageEndIndex;
  }

  /// Check if this is the final stage
  bool get _isFinalStage {
    return _currentStage >= _stageEndIndices.length;
  }

  Future<void> _speakText(String text) async {
    await _tts.setLanguage('ja-JP');
    await _tts.speak(text);
  }

  Future<void> _selectOption(int index) async {
    if (_hasAnswered || _isSubmitting) return;

    setState(() {
      _selectedOptionIndex = index;
      _isSubmitting = true;
    });

    final question = _questions[_currentIndex];
    final selectedOption = question.options[index];

    await _submitAnswer(
      question: question,
      answer: selectedOption,
      optionIndex: index,
    );
  }

  Future<void> _submitTypedAnswer() async {
    if (_hasAnswered || _isSubmitting) return;

    final question = _questions[_currentIndex];
    final typed = _normalizeAnswer(_answerController.text);
    if (typed.isEmpty) {
      setState(() {
        _inputError = 'Vui lòng nhập câu trả lời';
      });
      return;
    }

    final matched = question.options.firstWhere(
      (o) => _normalizeAnswer(o.text ?? '') == typed,
      orElse: () => const QuestionRef(type: '', id: 0, text: null, url: null),
    );

    if (matched.id == 0) {
      final nextAttempts = _inputMismatchAttempts + 1;
      setState(() {
        _inputMismatchAttempts = nextAttempts;
        _inputError = nextAttempts >= 2
            ? 'Sai 2 lần rồi. Tự động bỏ qua câu này.'
            : 'Không khớp đáp án nào. Hãy kiểm tra chính tả. ($nextAttempts/2)';
      });
      if (nextAttempts >= 2) {
        _skipCurrentQuestion();
      }
      return;
    }

    setState(() {
      _inputMismatchAttempts = 0;
    });
    await _submitAnswer(question: question, answer: matched, optionIndex: null);
  }

  void _skipCurrentQuestion() {
    final question = _questions[_currentIndex];

    // Still track term types for pronunciation challenge.
    if (question.questionType == 'LOOK_TERM_SELECT_MEANING') {
      final termText = question.questionRef?.text;
      if (termText != null && termText.isNotEmpty) {
        _stageTermsForPronunciation.add(termText);
      }
    }

    setState(() {
      _hasAnswered = true;
      _isSubmitting = false;
      _selectedOptionIndex = null;
      _lastResult = null;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  Future<void> _submitAnswer({
    required QuizQuestion question,
    required QuestionRef answer,
    required int? optionIndex,
  }) async {
    setState(() {
      _selectedOptionIndex = optionIndex;
      _isSubmitting = true;
      _inputError = null;
    });

    AnswerResult? result;
    try {
      result = await quizService
          .submitAnswer(
            questionType: question.questionType,
            refType: question.questionRef?.type ?? '',
            refId: question.questionRef?.id ?? 0,
            answerId: answer.id,
          )
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      result = null;
    }

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _isSubmitting = false;
        _selectedOptionIndex = null;
        _inputError = question.questionType == 'LOOK_TERM_SELECT_MEANING'
            ? 'Mạng chậm hoặc lỗi hệ thống. Thử lại nhé.'
            : null;
      });
      return;
    }

    final AnswerResult nonNullResult = result;

    setState(() {
      _hasAnswered = true;
      _isSubmitting = false;
      _lastResult = nonNullResult;

      _currentCorrectStreak = nonNullResult.correctStreak;
      _currentWrongStreak = nonNullResult.wrongStreak;

      if (nonNullResult.isCorrect) {
        _correctAnswers++;
        _stageCorrectAnswers++;
        if (nonNullResult.correctStreak > _maxCorrectStreak) {
          _maxCorrectStreak = nonNullResult.correctStreak;
        }
      } else {
        if (nonNullResult.wrongStreak > _maxWrongStreak) {
          _maxWrongStreak = nonNullResult.wrongStreak;
        }
      }

      // Track terms from LOOK_TERM_SELECT_MEANING for pronunciation challenge
      if (question.questionType == 'LOOK_TERM_SELECT_MEANING') {
        final termText = question.questionRef?.text;
        if (termText != null && termText.isNotEmpty) {
          _stageTermsForPronunciation.add(termText);
        }
      }
    });

    // Animate streak
    _streakController.forward(from: 0);

    // Auto move to next after delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    // Check if this was the last question in current stage
    if (_isLastQuestionInStage) {
      if (_isFinalStage) {
        // Final stage completed - check for pronunciation challenge first
        if (_stageTermsForPronunciation.isNotEmpty) {
          _showPronunciationChallenge(isFinal: true);
        } else {
          _showResults();
        }
      } else {
        // Stage completed - check for pronunciation challenge first
        if (_stageTermsForPronunciation.isNotEmpty) {
          _showPronunciationChallenge(isFinal: false);
        } else {
          _showStageCompleteDialog();
        }
      }
      return;
    }

    // Move to next question
    if (_currentIndex < _questions.length - 1) {
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex++;
          _selectedOptionIndex = null;
          _hasAnswered = false;
          _lastResult = null;
          _inputError = null;
          _inputMismatchAttempts = 0;
          _answerController.clear();
        });
        _fadeController.forward();
      });
    } else {
      _showResults();
    }
  }

  /// Show pronunciation challenge dialog
  void _showPronunciationChallenge({required bool isFinal}) {
    // Pick a random term from the collected terms
    final termText = _stageTermsForPronunciation.isNotEmpty
        ? _stageTermsForPronunciation[DateTime.now().millisecondsSinceEpoch %
              _stageTermsForPronunciation.length]
        : '';

    if (termText.isEmpty) {
      // No term to challenge, skip to next stage or results
      if (isFinal) {
        _showResults();
      } else {
        _showStageCompleteDialog();
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PronunciationChallengeDialog(
        termText: termText,
        isFinalStage: isFinal,
        currentStage: _currentStage,
        onComplete: () {
          Navigator.pop(context);
          // Clear pronunciation terms for next stage
          _stageTermsForPronunciation.clear();
          if (isFinal) {
            _showResults();
          } else {
            _showStageCompleteDialog();
          }
        },
      ),
    );
  }

  void _showStageCompleteDialog() {
    final stageQuestions = _currentStageQuestionsCount;
    final stagePercentage = stageQuestions > 0
        ? (_stageCorrectAnswers / stageQuestions * 100).round()
        : 0;
    final isPassed = stagePercentage >= 70;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              // Stage badge
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPassed
                        ? [_correctGreen, _correctGreen.withValues(alpha: 0.7)]
                        : [Colors.orange, Colors.orange.withValues(alpha: 0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isPassed ? _correctGreen : Colors.orange)
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_currentStage',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Giai đoạn',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hoàn thành Giai đoạn $_currentStage! 🎉',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn đã trả lời đúng $_stageCorrectAnswers/$stageQuestions câu hỏi',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                '$stagePercentage%',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isPassed ? _correctGreen : Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              // Progress indicator showing stages
              _buildStageProgressIndicator(),
              const SizedBox(height: 32),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: _primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Dừng lại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startNextStage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tiếp tục Giai đoạn ${_currentStage + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageProgressIndicator() {
    final totalStages = _stageEndIndices.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Tiến độ kiểm tra',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(totalStages, (index) {
              final stageNum = index + 1;
              final isCompleted = stageNum <= _currentStage;
              final isCurrent = stageNum == _currentStage;

              return Expanded(
                child: Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: isCompleted ? _correctGreen : Colors.grey[300],
                        ),
                      ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? _correctGreen
                            : isCurrent
                            ? _primaryBlue
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(color: _primaryBlue, width: 3)
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                '$stageNum',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                      ),
                    ),
                    if (index < totalStages - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: stageNum < _currentStage
                              ? _correctGreen
                              : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _startNextStage() {
    setState(() {
      _currentStage++;
      _stageCorrectAnswers = 0;
      _stageTermsForPronunciation.clear(); // Clear for new stage
      _currentIndex++;
      _selectedOptionIndex = null;
      _hasAnswered = false;
      _lastResult = null;
    });
    _fadeController.forward(from: 0);
  }

  void _showResults() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultSheet(),
    );
  }

  Widget _buildResultSheet() {
    final percentage = (_correctAnswers / _questions.length * 100).round();
    final isPassed = percentage >= 70;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isPassed
                    ? _correctGreen.withValues(alpha: 0.1)
                    : _wrongRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPassed ? Icons.emoji_events : Icons.refresh,
                size: 50,
                color: isPassed ? _correctGreen : _wrongRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPassed ? 'Xuất sắc! 🎉' : 'Cố gắng thêm nhé!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn đã trả lời đúng $_correctAnswers/${_questions.length} câu hỏi',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: isPassed ? _correctGreen : _wrongRed,
              ),
            ),
            const SizedBox(height: 24),
            // Streak summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStreakSummaryItem(
                    icon: Icons.local_fire_department,
                    value: _maxCorrectStreak,
                    label: 'Chuỗi đúng cao nhất',
                    color: _correctGreen,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildStreakSummaryItem(
                    icon: Icons.heart_broken,
                    value: _maxWrongStreak,
                    label: 'Chuỗi sai cao nhất',
                    color: _wrongRed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: _primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Thoát',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentIndex = 0;
                        _currentStage = 1;
                        _stageCorrectAnswers = 0;
                        _selectedOptionIndex = null;
                        _hasAnswered = false;
                        _correctAnswers = 0;
                        _currentCorrectStreak = 0;
                        _currentWrongStreak = 0;
                        _maxCorrectStreak = 0;
                        _maxWrongStreak = 0;
                        _lastResult = null;
                      });
                      _loadQuestions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Làm lại',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakSummaryItem({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _error != null
            ? _buildError()
            : _buildQuiz(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryBlue),
          SizedBox(height: 16),
          Text(
            'Đang tải câu hỏi...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Quay lại',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final question = _questions[_currentIndex];
    final stageProgress = _currentStageQuestionsCount > 0
        ? (_currentIndex - _currentStageStartIndex + 1) /
              _currentStageQuestionsCount
        : 0.0;

    return Column(
      children: [
        // Header with streak bar
        _buildHeader(stageProgress),
        // Streak indicator
        if (_hasAnswered && _lastResult != null) _buildStreakIndicator(),
        // Question content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuestionCard(question),
                  const SizedBox(height: 32),
                  if (question.questionType == 'LOOK_TERM_SELECT_MEANING')
                    _buildInputAnswer(question)
                  else
                    _buildOptions(question),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputAnswer(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Nhập đáp án:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _answerController,
          focusNode: _answerFocusNode,
          enabled: !_hasAnswered && !_isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitTypedAnswer(),
          decoration: InputDecoration(
            hintText: 'Nhập nghĩa (không phân biệt hoa/thường)',
            errorText: _inputError,
            filled: true,
            fillColor: _optionBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: (_hasAnswered || _isSubmitting)
                ? null
                : _submitTypedAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Gửi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        if (_hasAnswered && _lastResult != null) ...[
          const SizedBox(height: 12),
          Text(
            _lastResult!.isCorrect ? 'Đúng rồi!' : 'Chưa đúng!',
            style: TextStyle(
              color: _lastResult!.isCorrect ? _correctGreen : _wrongRed,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildStreakIndicator() {
    final result = _lastResult!;
    final isCorrect = result.isCorrect;
    final streak = isCorrect ? result.correctStreak : result.wrongStreak;

    return ScaleTransition(
      scale: _streakAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCorrect
              ? _correctGreen.withValues(alpha: 0.1)
              : _wrongRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCorrect ? _correctGreen : _wrongRed,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Streak icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCorrect ? _correctGreen : _wrongRed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCorrect ? Icons.local_fire_department : Icons.heart_broken,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Streak info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Chính xác! 🎯' : 'Sai rồi! 😅',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? _correctGreen : _wrongRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCorrect ? 'Chuỗi đúng: $streak' : 'Chuỗi sai: $streak',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            // Streak bar
            SizedBox(width: 80, child: _buildStreakBar(streak, isCorrect)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBar(int streak, bool isCorrect) {
    const maxStreak = 10;
    final progress = (streak / maxStreak).clamp(0.0, 1.0);
    final color = isCorrect ? _correctGreen : _wrongRed;

    return Column(
      children: [
        Text(
          '$streak',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(double progress) {
    final stageQuestionIndex = _currentIndex - _currentStageStartIndex + 1;
    final stageTotal = _currentStageQuestionsCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _showExitDialog(),
                icon: const Icon(Icons.close, size: 24),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.syllabusTitle ?? 'Kiểm tra',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Giai đoạn $_currentStage/${_stageEndIndices.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Current streak display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _currentCorrectStreak > 0
                      ? _correctGreen.withValues(alpha: 0.1)
                      : _currentWrongStreak > 0
                      ? _wrongRed.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentCorrectStreak > 0
                          ? Icons.local_fire_department
                          : _currentWrongStreak > 0
                          ? Icons.heart_broken
                          : Icons.remove,
                      size: 16,
                      color: _currentCorrectStreak > 0
                          ? _correctGreen
                          : _currentWrongStreak > 0
                          ? _wrongRed
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentCorrectStreak > 0
                          ? '$_currentCorrectStreak'
                          : _currentWrongStreak > 0
                          ? '$_currentWrongStreak'
                          : '0',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _currentCorrectStreak > 0
                            ? _correctGreen
                            : _currentWrongStreak > 0
                            ? _wrongRed
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '$stageQuestionIndex',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryBlue,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: _optionBg,
                        valueColor: const AlwaysStoppedAnimation(_primaryBlue),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ),
                Text(
                  '$stageTotal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    final questionType = question.questionType;
    final isImageQuestion =
        questionType == 'LOOK_IMAGE_SELECT_TERM' ||
        questionType == 'LOOK_IMAGE_SELECT_MEANING';
    final imageUrl = question.questionRef?.url;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    final refText = question.questionRef?.text;
    final showSpeaker = question.questionRef?.type == 'TERM' && refText != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryBlue, _primaryBlue.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getQuestionTypeLabel(questionType),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showSpeaker)
                GestureDetector(
                  onTap: () => _speakText(refText),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Image if available
          if (isImageQuestion && hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 150,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.1),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            color: Colors.white70,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Không thể tải hình',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Term/Meaning reference text
          if (refText != null && refText.isNotEmpty && !isImageQuestion) ...[
            Text(
              refText,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          // Question text
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: refText != null && !isImageQuestion ? 16 : 20,
              color: Colors.white.withValues(
                alpha: refText != null && !isImageQuestion ? 0.9 : 1,
              ),
              fontWeight: refText != null && !isImageQuestion
                  ? FontWeight.w400
                  : FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          // Difficulty stars
          if (question.difficultyLevel > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Icon(
                  i < question.difficultyLevel ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Chọn đáp án đúng:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          question.options.length,
          (index) => _buildOptionItem(question, index),
        ),
      ],
    );
  }

  Widget _buildOptionItem(QuizQuestion question, int index) {
    final option = question.options[index];
    final isSelected = _selectedOptionIndex == index;

    // Determine correct answer highlighting
    bool showAsCorrect = false;
    bool showAsWrong = false;

    if (_hasAnswered && _lastResult != null) {
      if (isSelected && _lastResult!.isCorrect) {
        showAsCorrect = true;
      } else if (isSelected && !_lastResult!.isCorrect) {
        showAsWrong = true;
        // Also show the correct answer
      }
      // For SELECT type questions, show the correct option
      if (!_lastResult!.isCorrect && question.questionRef != null) {
        if (option.id == question.questionRef!.id) {
          showAsCorrect = true;
        }
      }
    }

    // Determine the state color
    Color bgColor = _optionBg;
    Color borderColor = Colors.transparent;
    Color textColor = Colors.black87;

    if (_hasAnswered) {
      if (showAsCorrect) {
        bgColor = _correctGreen.withValues(alpha: 0.1);
        borderColor = _correctGreen;
        textColor = _correctGreen;
      } else if (showAsWrong) {
        bgColor = _wrongRed.withValues(alpha: 0.1);
        borderColor = _wrongRed;
        textColor = _wrongRed;
      }
    } else if (isSelected) {
      bgColor = _primaryBlue.withValues(alpha: 0.1);
      borderColor = _primaryBlue;
      textColor = _primaryBlue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSubmitting ? null : () => _selectOption(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _hasAnswered
                          ? (showAsCorrect
                                ? _correctGreen
                                : (showAsWrong ? _wrongRed : Colors.grey[300]))
                          : (isSelected ? _primaryBlue : Colors.grey[300]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _hasAnswered
                          ? Icon(
                              showAsCorrect
                                  ? Icons.check
                                  : (showAsWrong ? Icons.close : null),
                              color: Colors.white,
                              size: 20,
                            )
                          : _isSubmitting && isSelected
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option.text ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'LOOK_TERM_SELECT_MEANING':
        return 'Nhìn từ → Chọn nghĩa';
      case 'LOOK_MEANING_SELECT_TERM':
        return 'Nhìn nghĩa → Chọn từ';
      case 'LOOK_MEANING_INPUT_TERM':
        return 'Nhìn nghĩa → Chọn từ';
      case 'LOOK_IMAGE_SELECT_TERM':
        return 'Nhìn hình → Chọn từ';
      case 'LOOK_IMAGE_SELECT_MEANING':
        return 'Nhìn hình → Chọn nghĩa';
      case 'LISTEN_SELECT_TERM':
        return 'Nghe → Chọn từ';
      case 'LISTEN_SELECT_MEANING':
        return 'Nghe → Chọn nghĩa';
      default:
        return 'Trắc nghiệm';
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thoát kiểm tra?'),
        content: const Text(
          'Tiến trình làm bài sẽ không được lưu. Bạn có chắc muốn thoát?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tiếp tục'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Thoát', style: TextStyle(color: _wrongRed)),
          ),
        ],
      ),
    );
  }
}
