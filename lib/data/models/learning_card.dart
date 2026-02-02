/// Learning Card model for flashcard learning
class LearningCard {
  final int orderIndex;
  final int vocabId;
  final String cardType;
  final LearningVocab vocab;

  const LearningCard({
    required this.orderIndex,
    required this.vocabId,
    required this.cardType,
    required this.vocab,
  });

  factory LearningCard.fromJson(Map<String, dynamic> json) {
    return LearningCard(
      orderIndex: _asInt(json['order_index']),
      vocabId: _asInt(json['vocab_id']),
      cardType: _asString(json['card_type']),
      vocab: LearningVocab.fromJson(
        json['vocab'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// Vocabulary data in learning card
class LearningVocab {
  final int id;
  final int courseId;
  final List<VocabTerm> terms;
  final List<VocabMeaning> meanings;
  final List<VocabMedia> medias;

  const LearningVocab({
    required this.id,
    required this.courseId,
    required this.terms,
    required this.meanings,
    required this.medias,
  });

  factory LearningVocab.fromJson(Map<String, dynamic> json) {
    final termsJson = json['terms'] as List<dynamic>? ?? [];
    final meaningsJson = json['meanings'] as List<dynamic>? ?? [];
    final mediasJson = json['medias'] as List<dynamic>? ?? [];

    return LearningVocab(
      id: _asInt(json['id']),
      courseId: _asInt(json['course_id']),
      terms: termsJson
          .whereType<Map<String, dynamic>>()
          .map((t) => VocabTerm.fromJson(t))
          .toList(),
      meanings: meaningsJson
          .whereType<Map<String, dynamic>>()
          .map((m) => VocabMeaning.fromJson(m))
          .toList(),
      medias: mediasJson
          .whereType<Map<String, dynamic>>()
          .map((m) => VocabMedia.fromJson(m))
          .toList(),
    );
  }

  /// Get the main term (KANJI or first term)
  String get mainTerm {
    final kanjiTerm = terms.firstWhere(
      (t) => t.scriptType == 'KANJI',
      orElse: () => terms.isNotEmpty ? terms.first : VocabTerm.empty(),
    );
    return kanjiTerm.textValue;
  }

  /// Get the kana reading
  String get kanaReading {
    final kanaTerm = terms.firstWhere(
      (t) => t.scriptType == 'KANA',
      orElse: () => VocabTerm.empty(),
    );
    return kanaTerm.textValue;
  }

  /// Get the main meaning
  String get mainMeaning {
    return meanings.isNotEmpty ? meanings.first.meaningText : '';
  }

  /// Get the first image URL
  String? get imageUrl {
    final imageMedia = medias.firstWhere(
      (m) => m.mediaType == 'IMAGE' && m.url.isNotEmpty,
      orElse: () => VocabMedia.empty(),
    );
    return imageMedia.url.isNotEmpty ? imageMedia.url : null;
  }
}

/// Term in vocabulary
class VocabTerm {
  final int id;
  final String languageCode;
  final String scriptType;
  final String textValue;

  const VocabTerm({
    required this.id,
    required this.languageCode,
    required this.scriptType,
    required this.textValue,
  });

  factory VocabTerm.empty() =>
      const VocabTerm(id: 0, languageCode: '', scriptType: '', textValue: '');

  factory VocabTerm.fromJson(Map<String, dynamic> json) {
    return VocabTerm(
      id: _asInt(json['id']),
      languageCode: _asString(json['language_code']),
      scriptType: _asString(json['script_type']),
      textValue: _asString(json['text_value']),
    );
  }
}

/// Meaning in vocabulary
class VocabMeaning {
  final int id;
  final String languageCode;
  final String meaningText;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String partOfSpeech;

  const VocabMeaning({
    required this.id,
    required this.languageCode,
    required this.meaningText,
    this.exampleSentence,
    this.exampleTranslation,
    required this.partOfSpeech,
  });

  factory VocabMeaning.fromJson(Map<String, dynamic> json) {
    return VocabMeaning(
      id: _asInt(json['id']),
      languageCode: _asString(json['language_code']),
      meaningText: _asString(json['meaning_text']),
      exampleSentence: json['example_sentence']?.toString(),
      exampleTranslation: json['example_translation']?.toString(),
      partOfSpeech: _asString(json['part_of_speech']),
    );
  }
}

/// Media in vocabulary
class VocabMedia {
  final int id;
  final String mediaType;
  final String url;

  const VocabMedia({
    required this.id,
    required this.mediaType,
    required this.url,
  });

  factory VocabMedia.empty() => const VocabMedia(id: 0, mediaType: '', url: '');

  factory VocabMedia.fromJson(Map<String, dynamic> json) {
    return VocabMedia(
      id: _asInt(json['id']),
      mediaType: _asString(json['media_type']),
      url: _asString(json['url']),
    );
  }
}

/// Learning Set response
class LearningSet {
  final bool available;
  final List<LearningCard> cards;

  const LearningSet({required this.available, required this.cards});

  factory LearningSet.empty() => const LearningSet(available: false, cards: []);

  factory LearningSet.fromJson(Map<String, dynamic> json) {
    final cardsJson = json['cards'] as List<dynamic>? ?? [];
    return LearningSet(
      available: json['available'] == true,
      cards: cardsJson
          .whereType<Map<String, dynamic>>()
          .map((c) => LearningCard.fromJson(c))
          .toList(),
    );
  }
}

// Helper functions
int _asInt(Object? v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

String _asString(Object? v) => (v ?? '').toString();
