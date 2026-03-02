import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/tts/tts_utils.dart';

/// Dialog for pronunciation challenge after completing a stage
/// with LOOK_TERM_SELECT_MEANING questions
class PronunciationChallengeDialog extends StatefulWidget {
  /// The term text to pronounce (Japanese word)
  final String termText;

  /// Whether this is the final stage
  final bool isFinalStage;

  /// Callback when challenge is completed
  final VoidCallback onComplete;

  /// Current stage number
  final int currentStage;

  const PronunciationChallengeDialog({
    super.key,
    required this.termText,
    required this.isFinalStage,
    required this.onComplete,
    required this.currentStage,
  });

  @override
  State<PronunciationChallengeDialog> createState() =>
      _PronunciationChallengeDialogState();
}

class _PronunciationChallengeDialogState
    extends State<PronunciationChallengeDialog>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  bool _speechEnabled = false;
  bool _isListening = false;
  bool _hasResult = false;
  bool _isCorrect = false;
  String _spokenText = '';
  String _statusMessage = 'Tap the mic to start speaking';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _resultController;
  late Animation<double> _resultAnimation;

  static const _primaryBlue = Color(0xFF4F6CFF);
  static const _correctGreen = Color(0xFF4CAF50);
  static const _wrongRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultAnimation = CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    );
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultController.dispose();
    _speechToText.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _initSpeech() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Microphone permission is required';
        _speechEnabled = false;
      });
      return;
    }

    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _statusMessage = 'Recognition error. Please try again.';
          });
          _pulseController.stop();
        },
      );

      if (!mounted) return;
      setState(() {
        if (!_speechEnabled) {
          _statusMessage = 'Speech recognition could not be initialized';
        }
      });
    } catch (e) {
      debugPrint('Speech init error: $e');
      if (!mounted) return;
      setState(() {
        _speechEnabled = false;
        _statusMessage = 'Initialization error. Check microphone permission.';
      });
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      _pulseController.stop();
    }
  }

  Future<void> _speakTerm() async {
    final ready = await TtsUtils.prepareLanguage(
      tts: _tts,
      context: context,
      locale: TtsUtils.jaJP,
    );
    if (!ready) return;
    await _tts.speak(widget.termText);
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) return;
    }

    setState(() {
      _isListening = true;
      _hasResult = false;
      _spokenText = '';
      _statusMessage = 'Listening...';
    });

    _pulseController.repeat(reverse: true);

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'ja-JP', // Japanese
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      ),
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    _pulseController.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _spokenText = result.recognizedWords;
    });

    if (result.finalResult) {
      _checkPronunciation();
    }
  }

  void _checkPronunciation() {
    final spoken = _normalizeText(_spokenText);
    final expected = _normalizeText(widget.termText);

    setState(() {
      _hasResult = true;
      _isCorrect = _isMatchingPronunciation(spoken, expected);
      _statusMessage = _isCorrect
          ? 'Correct! Great job! 🎉'
          : "Not quite. You'll get it next time! 💪";
    });

    _resultController.forward(from: 0);

    // Auto continue after delay
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  String _normalizeText(String text) {
    // Remove spaces, convert to lowercase, normalize Japanese characters
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('　', ''); // Full-width space
  }

  bool _isMatchingPronunciation(String spoken, String expected) {
    if (spoken.isEmpty) return false;

    // Exact match
    if (spoken == expected) return true;

    // Check if spoken contains expected or vice versa (for partial matches)
    if (spoken.contains(expected) || expected.contains(spoken)) return true;

    // Calculate similarity ratio
    final similarity = _calculateSimilarity(spoken, expected);
    return similarity >= 0.7; // 70% similarity threshold
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;

    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;

    final longerLength = longer.length;
    if (longerLength == 0) return 1.0;

    return (longerLength - _editDistance(longer, shorter)) / longerLength;
  }

  int _editDistance(String s1, String s2) {
    final List<List<int>> dp = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1, // deletion
          dp[i][j - 1] + 1, // insertion
          dp[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[s1.length][s2.length];
  }

  @override
  Widget build(BuildContext context) {
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
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: _primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pronunciation Challenge',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Term to pronounce
            Container(
              width: double.infinity,
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
                  const Text(
                    'Pronounce this word:',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.termText,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // TTS button
                      GestureDetector(
                        onTap: _speakTerm,
                        child: Container(
                          padding: const EdgeInsets.all(10),
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
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Microphone button
            if (!_hasResult) ...[
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: _isListening ? _stopListening : _startListening,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isListening
                                ? [_wrongRed, _wrongRed.withValues(alpha: 0.8)]
                                : [
                                    _primaryBlue,
                                    _primaryBlue.withValues(alpha: 0.8),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? _wrongRed : _primaryBlue)
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (_spokenText.isNotEmpty && !_hasResult) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Listening: "$_spokenText"',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],

            // Result display
            if (_hasResult) ...[
              ScaleTransition(
                scale: _resultAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: (_isCorrect ? _correctGreen : _wrongRed).withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isCorrect ? Icons.check_circle : Icons.sentiment_satisfied,
                    size: 60,
                    color: _isCorrect ? _correctGreen : _wrongRed,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isCorrect ? _correctGreen : _wrongRed,
                ),
                textAlign: TextAlign.center,
              ),
              if (_spokenText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'You said: "$_spokenText"',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                widget.isFinalStage
                    ? 'Returning...'
                    : 'Continue to Stage ${widget.currentStage + 1}...',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],

            const SizedBox(height: 24),

            // Skip button
            if (!_hasResult)
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasResult = true;
                    _isCorrect = false;
                    _statusMessage = "Skipped. Let's keep going! 💪";
                  });
                  _resultController.forward(from: 0);
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (mounted) {
                      widget.onComplete();
                    }
                  });
                },
                child: Text(
                  'Skip',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
