import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocafy_mobile/core/data/network/api_client.dart';
import 'package:vocafy_mobile/core/data/network/api_error_utils.dart';

void main() {
  group('extractApiMessageFromData', () {
    test('gets message from map and trims it', () {
      final message = extractApiMessageFromData({'message': '  hello  '});
      expect(message, 'hello');
    });

    test('joins errors list when message is missing', () {
      final message = extractApiMessageFromData({
        'errors': [' one ', 'two', '', 'three', 'four'],
      });
      expect(message, 'one | two | three');
    });

    test('returns trimmed string for string input', () {
      final message = extractApiMessageFromData('  failed  ');
      expect(message, 'failed');
    });

    test('returns null for unsupported or empty input', () {
      expect(extractApiMessageFromData({'message': '  '}), isNull);
      expect(extractApiMessageFromData(123), isNull);
    });
  });

  group('extractApiErrorMessage', () {
    test('extracts ApiServerException message', () {
      final message = extractApiErrorMessage(
        const ApiServerException(message: '  boom ', method: 'GET', path: '/x'),
      );
      expect(message, 'boom');
    });

    test('extracts Dio response message first', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          data: {'error': 'Token expired'},
        ),
      );
      expect(extractApiErrorMessage(dioError), 'Token expired');
    });

    test('ignores debug-noise dio message', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/x'),
        message: 'DioException [bad response]',
      );
      expect(extractApiErrorMessage(dioError), isNull);
    });
  });

  group('preferredUserErrorMessage', () {
    test('returns api message when available', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          data: {'message': 'Invalid token'},
        ),
      );
      expect(preferredUserErrorMessage(dioError), 'Invalid token');
    });

    test('suppresses firebase/provider errors by default', () {
      final error = Exception('firebase auth failed');
      expect(preferredUserErrorMessage(error), isNull);
    });

    test('returns fallback for empty message', () {
      final error = Exception('   ');
      expect(
        preferredUserErrorMessage(error, fallback: 'Something went wrong'),
        'Something went wrong',
      );
    });
  });
}

