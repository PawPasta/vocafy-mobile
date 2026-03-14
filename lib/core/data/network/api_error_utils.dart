import 'package:dio/dio.dart';

import 'api_client.dart';

String? extractApiMessageFromData(dynamic data) {
  if (data is Map) {
    final message = data['message'] ?? data['error'] ?? data['detail'];
    final normalized = message?.toString().trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;

    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final joined = errors
          .take(3)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .join(' | ')
          .trim();
      if (joined.isNotEmpty) return joined;
    }
  }

  if (data is String) {
    final normalized = data.trim();
    if (normalized.isNotEmpty) return normalized;
  }

  return null;
}

String? extractApiErrorMessage(Object error) {
  if (error is ApiServerException) {
    final msg = error.message.trim();
    return msg.isEmpty ? null : msg;
  }

  if (error is DioException) {
    final fromResponse = extractApiMessageFromData(error.response?.data);
    if (fromResponse != null) return fromResponse;

    final wrapped = error.error;
    if (wrapped is ApiServerException) {
      final msg = wrapped.message.trim();
      if (msg.isNotEmpty) return msg;
    }

    final dioMessage = (error.message ?? '').trim();
    if (dioMessage.isNotEmpty && !isLikelyDebugNoise(dioMessage)) {
      return dioMessage;
    }

    final raw = wrapped?.toString().trim() ?? '';
    if (raw.isNotEmpty && !isLikelyDebugNoise(raw)) {
      return raw;
    }
  }

  return null;
}

String normalizeExceptionMessage(Object error) {
  return error.toString().replaceFirst('Exception: ', '').trim();
}

bool isFirebaseOrProviderError(Object error) {
  final msg = error.toString().toLowerCase();
  return msg.contains('firebase') ||
      msg.contains('google_sign_in') ||
      msg.contains('google sign in') ||
      msg.contains('platformexception(sign_in') ||
      msg.contains('com.google.android.gms');
}

bool isLikelyDebugNoise(String value) {
  final msg = value.toLowerCase();
  return msg.contains('stacktrace') ||
      msg.contains('debug') ||
      msg.contains('dioexception') ||
      msg.contains('instance of');
}

String? preferredUserErrorMessage(
  Object error, {
  bool suppressFirebaseOrProvider = true,
  bool suppressDebugNoise = true,
  String? fallback,
}) {
  final apiMessage = extractApiErrorMessage(error);
  if (apiMessage != null && apiMessage.isNotEmpty) return apiMessage;

  if (suppressFirebaseOrProvider && isFirebaseOrProviderError(error)) {
    return null;
  }

  final raw = normalizeExceptionMessage(error);
  if (raw.isEmpty) return fallback;

  if (suppressDebugNoise && isLikelyDebugNoise(raw)) {
    return null;
  }

  return raw;
}
