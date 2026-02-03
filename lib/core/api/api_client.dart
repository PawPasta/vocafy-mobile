import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import '../navigation/app_navigation_service.dart';
import '../storage/token_storage.dart';

class ApiServerException implements Exception {
  final String message;
  final int? statusCode;
  final String method;
  final String path;

  const ApiServerException({
    required this.message,
    required this.method,
    required this.path,
    this.statusCode,
  });

  @override
  String toString() => message;
}

String? _extractServerMessage(dynamic data) {
  if (data is Map) {
    final message = data['message'] ?? data['error'] ?? data['detail'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      // Best-effort: join the first few items.
      final parts = errors.take(3).map((e) => e.toString()).toList();
      final joined = parts.join(' | ').trim();
      if (joined.isNotEmpty) return joined;
    }
  }
  if (data is String && data.trim().isNotEmpty) return data;
  return null;
}

String _describeDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return 'Connection timeout';
    case DioExceptionType.sendTimeout:
      return 'Send timeout';
    case DioExceptionType.receiveTimeout:
      return 'Receive timeout';
    case DioExceptionType.badCertificate:
      return 'Bad TLS certificate';
    case DioExceptionType.connectionError:
      return 'Connection error';
    case DioExceptionType.cancel:
      return 'Request cancelled';
    case DioExceptionType.badResponse:
      return 'Bad response';
    case DioExceptionType.unknown:
      // Often contains SocketException / other info.
      final raw = error.error?.toString().trim();
      return (raw == null || raw.isEmpty) ? 'Unknown error' : raw;
  }
}

String _formatApiErrorLog({
  required String method,
  required String path,
  required int? statusCode,
  required String message,
  required dynamic data,
}) {
  final code = statusCode == null ? 'no-status' : statusCode.toString();
  final msg = message.trim().isEmpty ? 'Unknown error' : message.trim();
  final details = _extractServerMessage(data);

  // Keep log concise but useful.
  // Example: [API ERROR] POST /learning-sets (200) -> Invalid token
  final base = '[API ERROR] $method $path ($code) -> $msg';
  if (details != null && details != msg) {
    return '$base\n  serverMessage: $details';
  }
  return base;
}

/// API Client đơn giản
/// Sử dụng: Api.get('/users'), Api.post('/auth/login', data)
class ApiClient {
  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio _dio;
  late final Dio _refreshDio;

  Future<bool>? _refreshing;
  bool _forceLogoutInProgress = false;

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

    // Convert API envelope {success:false, message:"..."} into a consistent error,
    // and always log a clear server message (even if callers swallow exceptions).
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final serverMessage = _extractServerMessage(response.data);
          final isExplicitFailure =
              response.data is Map &&
              (response.data as Map)['success'] == false;

          if (isExplicitFailure) {
            final ex = ApiServerException(
              message: serverMessage ?? 'Request failed',
              statusCode: response.statusCode,
              method: response.requestOptions.method,
              path: response.requestOptions.path,
            );

            if (kDebugMode) {
              debugPrint(
                _formatApiErrorLog(
                  method: response.requestOptions.method,
                  path: response.requestOptions.path,
                  statusCode: response.statusCode,
                  message: ex.message,
                  data: response.data,
                ),
              );
            }

            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: ex,
              ),
            );
          }

          // Some BE returns success=true but still embeds an error message field.
          // Keep the response as-is, but having serverMessage extracted here is useful
          // for debugging (LogInterceptor already prints bodies in debug).
          return handler.next(response);
        },
        onError: (error, handler) {
          // Ensure we log a clear error reason from server/network.
          if (kDebugMode) {
            final req = error.requestOptions;
            final statusCode = error.response?.statusCode;
            final msg =
                _extractServerMessage(error.response?.data) ??
                _describeDioException(error);
            debugPrint(
              _formatApiErrorLog(
                method: req.method,
                path: req.path,
                statusCode: statusCode,
                message: msg,
                data: error.response?.data,
              ),
            );
          }
          return handler.next(error);
        },
      ),
    );

    // Log trong debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final request = error.requestOptions;

          // If refresh token itself is invalid/expired, immediately force logout.
          final isRefreshCall = request.path.endsWith(Api.refresh);
          if (isRefreshCall && _isAuthInvalidError(error)) {
            await _forceLogoutToLogin();
            return handler.next(error);
          }

          // For non-refresh calls, attempt refresh only once. If refresh fails,
          // default to login as requested.
          if (_isAuthInvalidError(error) && !_shouldAttemptRefresh(request)) {
            // Avoid forcing logout for login endpoint.
            if (!request.path.endsWith(Api.loginGoogle)) {
              await _forceLogoutToLogin();
            }
            return handler.next(error);
          }

          // Some backends return auth errors with 200/400 plus message like
          // "Invalid token". In that case, we still want to attempt refresh.
          final shouldTryRefresh =
              _isAuthInvalidError(error) && _shouldAttemptRefresh(request);
          if (!shouldTryRefresh) {
            return handler.next(error);
          }

          final refreshed = await _refreshAccessToken();
          if (!refreshed) {
            await _forceLogoutToLogin();
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

  bool _isAuthInvalidError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) return true;

    // Best-effort: some backends return 400/200 with message like "token expired".
    final data = error.response?.data;
    if (data is Map) {
      final msg = (data['message'] ?? data['error'] ?? '')
          .toString()
          .toLowerCase();
      if (msg.contains('token') &&
          (msg.contains('expired') || msg.contains('invalid'))) {
        return true;
      }
    }

    return false;
  }

  Future<void> _forceLogoutToLogin() async {
    if (_forceLogoutInProgress) return;
    _forceLogoutInProgress = true;

    try {
      clearToken();
      await tokenStorage.clearAuthTokens();
    } catch (_) {
      // Best effort.
    }

    appNavigationService.goToLogin();
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

  /// PATCH request
  /// Ví dụ: Api.patch('/products/1', {'name': 'iPhone 15'})
  Future<Response> patch(String endpoint, [dynamic data]) {
    return _dio.patch(endpoint, data: data);
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
