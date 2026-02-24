import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flip_card/flip_card.dart';
import '../../data/models/learning_card.dart';
import '../../data/services/learning_service.dart';
import '../../config/routes/route_names.dart';
import '../../core/tts/tts_utils.dart';

class FlashcardScreen extends StatefulWidget {
  final LearningSet learningSet;
  final String courseTitle;
  final int? syllabusId;

  const FlashcardScreen({
    Key? key,
    required this.learningSet,
    required this.courseTitle,
    this.syllabusId,
  }) : super(key: key);

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late final List<LearningCard> _cards;
  late final List<int> _learnedVocabIds;
  late final List<GlobalKey<FlipCardState>> _cardKeys;
  int _currentIndex = 0;
  final Set<int> _seenBackIndexes = <int>{};
  bool _isCompleting = false;
  final FlutterTts _tts = FlutterTts();

  static const _blue = Color(0xFF4F6CFF);

  @override
  void initState() {
    super.initState();
    _cards = widget.learningSet.cards;
    _learnedVocabIds = [];
    _cardKeys = List.generate(_cards.length, (_) => GlobalKey<FlipCardState>());
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakTerm(LearningVocab vocab) async {
    final term = _primaryTerm(vocab);
    final locale = TtsUtils.resolveLocale(
      languageCode: term?.languageCode,
      scriptType: term?.scriptType,
    );
    final ready = await TtsUtils.prepareLanguage(
      tts: _tts,
      context: context,
      locale: locale,
    );
    if (!ready) return;
    await _tts.speak(vocab.mainTerm);
  }

  Future<void> _speakMeaning(LearningVocab vocab) async {
    final langCode = vocab.meanings.isNotEmpty
        ? vocab.meanings.first.languageCode
        : 'en';
    final locale = TtsUtils.resolveLocale(languageCode: langCode);
    final ready = await TtsUtils.prepareLanguage(
      tts: _tts,
      context: context,
      locale: locale,
    );
    if (!ready) return;
    await _tts.speak(vocab.mainMeaning);
  }

  VocabTerm? _primaryTerm(LearningVocab vocab) {
    if (vocab.terms.isEmpty) return null;
    for (final term in vocab.terms) {
      if (term.textValue == vocab.mainTerm) return term;
    }
    return vocab.terms.first;
  }

  void _onFlip(bool isFront) {
    // Set _isFlipped = true khi flip sang mặt sau (nghĩa tiếng Anh)
    // Giữ nguyên _isFlipped = true khi flip lại để không cần flip 2 lần
    if (!isFront) {
      setState(() => _seenBackIndexes.add(_currentIndex));
      final id = _cards[_currentIndex].vocabId;
      if (!_learnedVocabIds.contains(id)) _learnedVocabIds.add(id);
    }
  }

  bool get _canNavigateFromCurrent => _seenBackIndexes.contains(_currentIndex);

  void _showFlipFirstSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please flip the card first!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _next() {
    if (_isCompleting) return;
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _prev() {
    if (_isCompleting) return;
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _complete() async {
    await _submitLearnedVocabIds(showDoneOnSuccess: true);
  }

  Future<bool> _submitLearnedVocabIds({required bool showDoneOnSuccess}) async {
    if (_isCompleting) return false;
    if (_learnedVocabIds.isEmpty) return true;

    setState(() => _isCompleting = true);
    final ok = await learningService.completeLearning(_learnedVocabIds);

    if (!mounted) return ok;
    setState(() => _isCompleting = false);

    if (ok) {
      if (showDoneOnSuccess) _showDone();
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connection error'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  Future<void> _saveProgressAndExit() async {
    if (_learnedVocabIds.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final ok = await _submitLearnedVocabIds(showDoneOnSuccess: false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${_learnedVocabIds.length} learned words',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showDone() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Congratulations!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You have finished ${_learnedVocabIds.length} words!',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Luôn navigate về homepage
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
            },
            child: const Text('Go to home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcard')),
        body: const Center(child: Text('No vocabulary available')),
      );
    }

    final card = _cards[_currentIndex];
    final vocab = card.vocab;
    final isLast = _currentIndex == _cards.length - 1;
    final h = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        _confirmExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              _progress(),
              const Spacer(),
              // Card with 40% height
              SizedBox(
                height: h * 0.48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FlipCard(
                    key: _cardKeys[_currentIndex],
                    direction: FlipDirection.HORIZONTAL,
                    onFlip: () => _onFlip(
                      _cardKeys[_currentIndex].currentState?.isFront ?? true,
                    ),
                    front: _front(vocab),
                    back: _back(vocab),
                  ),
                ),
              ),
              const Spacer(),
              _navButtons(isLast),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: _blue,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
    ),
    child: Row(
      children: [
        _iconBtn(Icons.close, () => _confirmExit()),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            widget.courseTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_currentIndex + 1}/${_cards.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white),
    ),
  );

  Widget _progress() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: (_currentIndex + 1) / _cards.length,
        backgroundColor: Colors.grey.shade300,
        valueColor: const AlwaysStoppedAnimation(_blue),
        minHeight: 8,
      ),
    ),
  );

  Widget _front(LearningVocab v) => _cardBox(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _badge(_scriptLabel(v.terms)),
        const SizedBox(height: 16),
        Text(
          v.mainTerm,
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (v.kanaReading.isNotEmpty && v.kanaReading != v.mainTerm) ...[
          const SizedBox(height: 6),
          Text(
            v.kanaReading,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => _speakTerm(v),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volume_up, color: _blue, size: 28),
          ),
        ),
        const Spacer(),
        Text(
          'Tap to flip',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );

  Widget _back(LearningVocab v) => _cardBox(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (v.imageUrl != null && v.imageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              v.imageUrl!,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_outlined,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          v.mainMeaning,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _speakMeaning(v),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.volume_up,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
        ),
        if (v.meanings.isNotEmpty &&
            v.meanings.first.partOfSpeech.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              v.meanings.first.partOfSpeech,
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          'Tap to flip back',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );

  Widget _cardBox({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(
      color: _blue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: _blue,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );

  String _scriptLabel(List<VocabTerm> terms) {
    final s = terms.map((t) => t.scriptType).toSet();
    if (s.contains('KANJI')) return 'Kanji';
    if (s.contains('KANA')) return 'Kana';
    if (s.contains('ROMAJI')) return 'Romaji';
    return 'Japanese';
  }

  Widget _navButtons(bool isLast) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: [
        Expanded(
          child: _navBtn(
            'Previous',
            Icons.arrow_back,
            _currentIndex > 0 && !_isCompleting,
            _prev,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _navBtn(
            isLast ? 'Finish' : 'Next',
            isLast ? Icons.check : Icons.arrow_forward,
            _canNavigateFromCurrent && !_isCompleting,
            () {
              if (!_canNavigateFromCurrent) return _showFlipFirstSnack();
              isLast ? _complete() : _next();
            },
            primary: true,
            isComplete: isLast,
            loading: _isCompleting,
          ),
        ),
      ],
    ),
  );

  Widget _navBtn(
    String label,
    IconData icon,
    bool enabled,
    VoidCallback onTap, {
    bool primary = false,
    bool isComplete = false,
    bool loading = false,
  }) {
    final bg = !enabled
        ? Colors.grey.shade200
        : primary
        ? (isComplete ? Colors.green : _blue)
        : Colors.grey.shade200;
    final fg = !enabled
        ? Colors.grey.shade400
        : primary
        ? Colors.white
        : Colors.grey.shade700;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!primary) Icon(icon, color: fg, size: 20),
                  if (!primary) const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                  ),
                  if (primary) const SizedBox(width: 6),
                  if (primary) Icon(icon, color: fg, size: 20),
                ],
              ),
      ),
    );
  }

  void _confirmExit() {
    if (_isCompleting) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Stop learning?'),
        content: Text(
          _learnedVocabIds.isEmpty
              ? 'You have not learned any words yet. Exit now?'
              : 'You learned ${_learnedVocabIds.length} words. Save progress before exiting?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
          if (_learnedVocabIds.isNotEmpty)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _saveProgressAndExit();
              },
              child: const Text('Save & exit'),
            ),
        ],
      ),
    );
  }
}
