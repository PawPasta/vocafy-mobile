/// Full Vocabulary model from API with terms, meanings, and medias
class Vocabulary {
  final int id;
  final int? courseId;
  final String note;
  final int sortOrder;
  final bool isActive;
  final bool isDeleted;
  final List<VocabularyTerm> terms;
  final List<VocabularyMeaning> meanings;
  final List<VocabularyMedia> medias;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vocabulary({
    required this.id,
    this.courseId,
    required this.note,
    required this.sortOrder,
    required this.isActive,
    required this.isDeleted,
    required this.terms,
    required this.meanings,
    required this.medias,
    this.createdAt,
    this.updatedAt,
  });

  /// Get main term text (prefer KANJI > KANA > LATIN)
  String get mainTerm {
    final kanji = terms.where((t) => t.scriptType == 'KANJI').toList();
    if (kanji.isNotEmpty) return kanji.first.textValue;
    
    final kana = terms.where((t) => t.scriptType == 'KANA').toList();
    if (kana.isNotEmpty) return kana.first.textValue;
    
    final latin = terms.where((t) => t.scriptType == 'LATIN').toList();
    if (latin.isNotEmpty) return latin.first.textValue;
    
    return terms.isNotEmpty ? terms.first.textValue : '';
  }

  /// Get reading (kana/romaji)
  String get reading {
    final kana = terms.where((t) => t.scriptType == 'KANA').toList();
    if (kana.isNotEmpty) return kana.first.textValue;
    
    final romaji = terms.where((t) => t.scriptType == 'ROMAJI').toList();
    if (romaji.isNotEmpty) return romaji.first.textValue;
    
    return '';
  }

  /// Get main meaning text
  String get mainMeaning {
    if (meanings.isEmpty) return '';
    return meanings.first.meaningText;
  }

  /// Get image URL if exists
  String? get imageUrl {
    final images = medias.where((m) => m.mediaType == 'IMAGE').toList();
    return images.isNotEmpty ? images.first.url : null;
  }

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    String asString(Object? v) => (v ?? '').toString();

    bool asBool(Object? v, {bool fallback = false}) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return fallback;
    }

    DateTime? asDateTime(Object? v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    final termsJson = (json['terms'] is List) ? List.from(json['terms'] as List) : <dynamic>[];
    final terms = termsJson
        .whereType<Map<String, dynamic>>()
        .map((t) => VocabularyTerm.fromJson(t))
        .toList();

    final meaningsJson = (json['meanings'] is List) ? List.from(json['meanings'] as List) : <dynamic>[];
    final meanings = meaningsJson
        .whereType<Map<String, dynamic>>()
        .map((m) => VocabularyMeaning.fromJson(m))
        .toList();

    final mediasJson = (json['medias'] is List) ? List.from(json['medias'] as List) : <dynamic>[];
    final medias = mediasJson
        .whereType<Map<String, dynamic>>()
        .map((m) => VocabularyMedia.fromJson(m))
        .toList();

    return Vocabulary(
      id: asInt(json['id']),
      courseId: json['course_id'] != null ? asInt(json['course_id']) : null,
      note: asString(json['note']),
      sortOrder: asInt(json['sort_order']),
      isActive: asBool(json['is_active'], fallback: true),
      isDeleted: asBool(json['is_deleted'], fallback: false),
      terms: terms,
      meanings: meanings,
      medias: medias,
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}

/// Vocabulary Term (word forms in different scripts)
class VocabularyTerm {
  final int id;
  final String languageCode; // EN, JA, VI, ZH
  final String scriptType; // LATIN, KANJI, KANA, ROMAJI, IPA, PINYIN
  final String textValue;
  final String? extraMeta;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VocabularyTerm({
    required this.id,
    required this.languageCode,
    required this.scriptType,
    required this.textValue,
    this.extraMeta,
    this.createdAt,
    this.updatedAt,
  });

  factory VocabularyTerm.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    String asString(Object? v) => (v ?? '').toString();

    DateTime? asDateTime(Object? v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return VocabularyTerm(
      id: asInt(json['id']),
      languageCode: asString(json['language_code']),
      scriptType: asString(json['script_type']),
      textValue: asString(json['text_value']),
      extraMeta: json['extra_meta']?.toString(),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}

/// Vocabulary Meaning (definitions with examples)
class VocabularyMeaning {
  final int id;
  final String languageCode;
  final String meaningText;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String partOfSpeech; // NOUN, VERB, ADJ, ADV, etc.
  final int? senseOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VocabularyMeaning({
    required this.id,
    required this.languageCode,
    required this.meaningText,
    this.exampleSentence,
    this.exampleTranslation,
    required this.partOfSpeech,
    this.senseOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory VocabularyMeaning.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    String asString(Object? v) => (v ?? '').toString();

    DateTime? asDateTime(Object? v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return VocabularyMeaning(
      id: asInt(json['id']),
      languageCode: asString(json['language_code']),
      meaningText: asString(json['meaning_text']),
      exampleSentence: json['example_sentence']?.toString(),
      exampleTranslation: json['example_translation']?.toString(),
      partOfSpeech: asString(json['part_of_speech']),
      senseOrder: json['sense_order'] != null ? asInt(json['sense_order']) : null,
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}

/// Vocabulary Media (images, audio)
class VocabularyMedia {
  final int id;
  final String mediaType; // IMAGE, AUDIO_EN, AUDIO_JP
  final String url;
  final String? meta;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VocabularyMedia({
    required this.id,
    required this.mediaType,
    required this.url,
    this.meta,
    this.createdAt,
    this.updatedAt,
  });

  factory VocabularyMedia.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    String asString(Object? v) => (v ?? '').toString();

    DateTime? asDateTime(Object? v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return VocabularyMedia(
      id: asInt(json['id']),
      mediaType: asString(json['media_type']),
      url: asString(json['url']),
      meta: json['meta']?.toString(),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}
