import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import '../storage/token_storage.dart';

/// API Client đơn giản
/// Sử dụng: Api.get('/users'), Api.post('/auth/login', data)
class ApiClient {
  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio _dio;
  late final Dio _refreshDio;

  Future<bool>? _refreshing;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Api.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _refreshDio = Dio(
      BaseOptions(
        baseUrl: Api.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Log trong debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final request = error.requestOptions;

          final shouldTryRefresh =
              statusCode == 401 && _shouldAttemptRefresh(request);
          if (!shouldTryRefresh) {
            return handler.next(error);
          }

          final refreshed = await _refreshAccessToken();
          if (!refreshed) {
            return handler.next(error);
          }

          final newAccessToken = await tokenStorage.getAccessToken();
          if (newAccessToken == null || newAccessToken.isEmpty) {
            return handler.next(error);
          }

          request.headers['Authorization'] = 'Bearer $newAccessToken';
          request.extra['__retried__'] = true;

          try {
            final response = await _dio.fetch(request);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        },
      ),
    );
  }

  /// Set token vào header
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Xóa token
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  bool _shouldAttemptRefresh(RequestOptions request) {
    if (request.extra['__retried__'] == true) return false;

    // Avoid infinite loop for auth endpoints.
    final path = request.path;
    if (path.endsWith(Api.loginGoogle) || path.endsWith(Api.refresh)) {
      return false;
    }
    return true;
  }

  Future<bool> _refreshAccessToken() async {
    _refreshing ??= () async {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      try {
        final response = await _refreshDio.post(
          Api.refresh,
          data: {'refresh_token': refreshToken},
        );

        final result = response.data is Map ? response.data['result'] : null;
        if (result is! Map) return false;

        final accessToken = (result['accessToken'] ?? result['access_token'])
            ?.toString();
        final newRefreshToken =
            (result['refreshToken'] ?? result['refresh_token'])?.toString();

        if (accessToken == null || accessToken.isEmpty) return false;

        await tokenStorage.setAccessToken(accessToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await tokenStorage.setRefreshToken(newRefreshToken);
        }

        setToken(accessToken);
        return true;
      } catch (_) {
        return false;
      }
    }();

    final refreshed = await _refreshing!;
    _refreshing = null;
    return refreshed;
  }

  // ==================== 4 Phương thức chính ====================

  /// GET request
  /// Ví dụ: Api.get('/users') hoặc Api.get('/users/1')
  Future<Response> get(String endpoint, {Map<String, dynamic>? params}) {
    return _dio.get(endpoint, queryParameters: params);
  }

  /// POST request
  /// Ví dụ: Api.post('/products', {'name': 'iPhone', 'price': 999})
  Future<Response> post(String endpoint, [dynamic data]) {
    return _dio.post(endpoint, data: data);
  }

  /// PUT request
  /// Ví dụ: Api.put('/products/1', {'name': 'iPhone 15'})
  Future<Response> put(String endpoint, [dynamic data]) {
    return _dio.put(endpoint, data: data);
  }

  /// DELETE request
  /// Ví dụ: Api.delete('/products/1')
  Future<Response> delete(String endpoint, [dynamic data]) {
    return _dio.delete(endpoint, data: data);
  }
}

/// Shortcut để dùng nhanh
/// Ví dụ: api.post('/auth/google', {'idToken': token})
final api = ApiClient.instance;
