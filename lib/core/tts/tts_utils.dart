import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsUtils {
  static const String jaJP = 'ja-JP';
  static const String enUS = 'en-US';
  static const String viVN = 'vi-VN';
  static const String zhCN = 'zh-CN';

  static String resolveLocale({
    String? languageCode,
    String? scriptType,
    String? text,
  }) {
    final lang = (languageCode ?? '').toLowerCase().trim();
    final script = (scriptType ?? '').toUpperCase().trim();
    final sample = (text ?? '').trim();

    if (_containsKana(sample)) return jaJP;
    if (_containsVietnameseDiacritics(sample)) return viVN;
    if (_containsCjk(sample)) return zhCN;

    final isJapanese =
        lang.contains('ja') ||
        lang.contains('jp') ||
        script.startsWith('KANJI') ||
        script.startsWith('KANA') ||
        script.startsWith('ROMAJI');
    if (isJapanese) return jaJP;

    if (lang.contains('en')) return enUS;
    if (lang.contains('vi')) return viVN;
    if (lang.contains('zh') || script == 'PINYIN') return zhCN;

    return enUS;
  }

  static String displayName(String locale) {
    switch (locale) {
      case jaJP:
        return 'Japanese';
      case enUS:
        return 'English';
      case viVN:
        return 'Vietnamese';
      case zhCN:
        return 'Chinese';
      default:
        return locale;
    }
  }

  static Future<bool> prepareLanguage({
    required FlutterTts tts,
    required BuildContext context,
    required String locale,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    bool available = false;
    try {
      available = await tts.isLanguageAvailable(locale);
    } catch (_) {
      available = false;
    }

    if (!available) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            'The ${displayName(locale)} voice is not installed. '
            'Please install it in system Text-to-Speech settings.',
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
      return false;
    }

    await tts.setLanguage(locale);
    final voiceSelected = await _setPreferredVoice(tts, locale, messenger);
    if (_normalizeLocale(locale) == _normalizeLocale(jaJP) &&
        voiceSelected == false) {
      return false;
    }
    return true;
  }

  static Future<bool> _setPreferredVoice(
    FlutterTts tts,
    String locale,
    ScaffoldMessengerState? messenger,
  ) async {
    try {
      final voices = await tts.getVoices;
      if (voices is! List) return true;

      final target = _normalizeLocale(locale);
      Map<String, String>? match;

      for (final v in voices) {
        if (v is! Map) continue;
        final rawLocale = v['locale']?.toString() ?? '';
        final rawName =
            v['name']?.toString() ?? v['identifier']?.toString() ?? '';
        final normalized = _normalizeLocale(rawLocale);
        final normalizedName = _normalizeLocale(rawName);
        final matchesLocale =
            normalized == target || normalized.startsWith('$target-');
        final matchesName = normalizedName.contains(target);
        if (!matchesLocale && !matchesName) continue;
        match = v.map(
          (k, val) => MapEntry(k.toString(), val?.toString() ?? ''),
        );
        break;
      }

      if (match != null) {
        await tts.setVoice(match);
        return true;
      }

      if (_normalizeLocale(locale) == _normalizeLocale(jaJP)) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text(
              'Japanese voice not found. Please install a Japanese TTS voice.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
        return false;
      }
    } catch (_) {
      // Ignore voice selection errors; language availability is checked already.
    }
    return true;
  }

  static String _normalizeLocale(String value) =>
      value.replaceAll('_', '-').toLowerCase();

  static bool _containsKana(String text) =>
      RegExp(r'[\u3040-\u30FF]').hasMatch(text);

  static bool _containsVietnameseDiacritics(String text) => RegExp(
    r'[ăâđêôơưĂÂĐÊÔƠƯáàảãạấầẩẫậắằẳẵặéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
  ).hasMatch(text);

  static bool _containsCjk(String text) =>
      RegExp(r'[\u4E00-\u9FFF]').hasMatch(text);
}
