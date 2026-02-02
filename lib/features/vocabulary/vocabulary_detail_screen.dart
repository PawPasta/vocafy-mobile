import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/services/vocabulary_service.dart';
import '../../data/models/vocabulary.dart';

class VocabularyDetailScreen extends StatefulWidget {
  final int vocabularyId;

  const VocabularyDetailScreen({Key? key, required this.vocabularyId})
    : super(key: key);

  @override
  State<VocabularyDetailScreen> createState() => _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState extends State<VocabularyDetailScreen> {
  late final Future<Vocabulary?> _vocabFuture;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  String? _currentSpeakingText;

  static const _primaryBlue = Color(0xFF4F6CFF);

  @override
  void initState() {
    super.initState();
    _vocabFuture = vocabularyService.getVocabularyById(widget.vocabularyId);
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _currentSpeakingText = null;
      });
    });

    _flutterTts.setCancelHandler(() {
      setState(() {
        _isSpeaking = false;
        _currentSpeakingText = null;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
        _currentSpeakingText = null;
      });
    });
  }

  Future<void> _speak(
    String text,
    String languageCode,
    String scriptType,
  ) async {
    if (_isSpeaking && _currentSpeakingText == text) {
      await _flutterTts.stop();
      return;
    }

    // Xác định ngôn ngữ TTS dựa trên languageCode và scriptType
    String ttsLanguage = _getTtsLanguage(languageCode, scriptType);

    // Kiểm tra xem ngôn ngữ có được hỗ trợ không
    bool isLanguageAvailable = await _flutterTts.isLanguageAvailable(
      ttsLanguage,
    );

    if (!isLanguageAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ngôn ngữ ${_getLanguageName(ttsLanguage)} chưa được cài đặt trên thiết bị. '
              'Vui lòng vào Cài đặt > Ngôn ngữ & Nhập liệu > Text-to-Speech để tải thêm.',
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
      return;
    }

    await _flutterTts.setLanguage(ttsLanguage);

    setState(() {
      _currentSpeakingText = text;
    });

    await _flutterTts.speak(text);
  }

  String _getLanguageName(String langCode) {
    switch (langCode) {
      case 'ja-JP':
        return 'Tiếng Nhật';
      case 'en-US':
        return 'Tiếng Anh';
      case 'vi-VN':
        return 'Tiếng Việt';
      default:
        return langCode;
    }
  }

  String _getTtsLanguage(String languageCode, String scriptType) {
    // Xử lý tiếng Nhật
    if (languageCode.toLowerCase().contains('ja') ||
        languageCode.toLowerCase().contains('jp') ||
        scriptType == 'KANJI' ||
        scriptType == 'KANA' ||
        scriptType == 'ROMAJI') {
      return 'ja-JP';
    }

    // Xử lý tiếng Anh
    if (languageCode.toLowerCase().contains('en')) {
      return 'en-US';
    }

    // Xử lý tiếng Việt
    if (languageCode.toLowerCase().contains('vi')) {
      return 'vi-VN';
    }

    // Mặc định là tiếng Anh
    return 'en-US';
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Vocabulary?>(
          future: _vocabFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text('Không thể tải từ vựng'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              );
            }

            final vocab = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    decoration: const BoxDecoration(
                      color: _primaryBlue,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Back button
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Từ vựng',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Main term
                        Text(
                          vocab.mainTerm,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Reading
                        if (vocab.reading.isNotEmpty &&
                            vocab.reading != vocab.mainTerm) ...[
                          const SizedBox(height: 8),
                          Text(
                            vocab.reading,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Image section
                  if (vocab.imageUrl != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          vocab.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Terms section
                  if (vocab.terms.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cách viết',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: vocab.terms.map((term) {
                              final isCurrentlySpeaking =
                                  _isSpeaking &&
                                  _currentSpeakingText == term.textValue;
                              return GestureDetector(
                                onTap: () => _speak(
                                  term.textValue,
                                  term.languageCode,
                                  term.scriptType,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrentlySpeaking
                                        ? const Color(0xFFE0E7FF)
                                        : const Color(0xFFF0F4FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCurrentlySpeaking
                                          ? _primaryBlue
                                          : const Color(0xFFE0E7FF),
                                      width: isCurrentlySpeaking ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            term.textValue,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_getScriptTypeName(term.scriptType)} • ${term.languageCode}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isCurrentlySpeaking
                                            ? Icons.stop_circle_outlined
                                            : Icons.volume_up_outlined,
                                        color: isCurrentlySpeaking
                                            ? _primaryBlue
                                            : Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Meanings section
                  if (vocab.meanings.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nghĩa',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...vocab.meanings.asMap().entries.map((entry) {
                            final index = entry.key;
                            final meaning = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE0E7FF),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primaryBlue,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          _getPartOfSpeechName(
                                            meaning.partOfSpeech,
                                          ),
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    meaning.meaningText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (meaning.exampleSentence != null &&
                                      meaning.exampleSentence!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F7FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.format_quote,
                                                size: 16,
                                                color: _primaryBlue,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Ví dụ',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            meaning.exampleSentence!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          if (meaning.exampleTranslation !=
                                                  null &&
                                              meaning
                                                  .exampleTranslation!
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              meaning.exampleTranslation!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  // Audio section
                  if (vocab.medias.any(
                    (m) => m.mediaType.startsWith('AUDIO'),
                  )) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phát âm',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            children: vocab.medias
                                .where((m) => m.mediaType.startsWith('AUDIO'))
                                .map((media) {
                                  return ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Play audio
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Phát âm: ${media.mediaType}',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.volume_up),
                                    label: Text(
                                      media.mediaType == 'AUDIO_EN'
                                          ? 'English'
                                          : 'Japanese',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Note section
                  if (vocab.note.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.amber.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ghi chú',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(vocab.note),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getScriptTypeName(String scriptType) {
    switch (scriptType) {
      case 'KANJI':
        return 'Kanji';
      case 'KANA':
        return 'Kana';
      case 'ROMAJI':
        return 'Romaji';
      case 'LATIN':
        return 'Latin';
      case 'IPA':
        return 'IPA';
      case 'PINYIN':
        return 'Pinyin';
      default:
        return scriptType;
    }
  }

  String _getPartOfSpeechName(String pos) {
    switch (pos) {
      case 'NOUN':
        return 'Danh từ';
      case 'VERB':
        return 'Động từ';
      case 'ADJ':
        return 'Tính từ';
      case 'ADV':
        return 'Trạng từ';
      case 'PRON':
        return 'Đại từ';
      case 'PREP':
        return 'Giới từ';
      case 'CONJ':
        return 'Liên từ';
      case 'INTERJ':
        return 'Thán từ';
      default:
        return pos;
    }
  }
}
