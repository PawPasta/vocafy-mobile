import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';

/// API Client đơn giản
/// Sử dụng: Api.get('/users'), Api.post('/auth/login', data)
class ApiClient {
  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio _dio;

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

    // Log trong debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  /// Set token vào header
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Xóa token
  void clearToken() {
    _dio.options.headers.remove('Authorization');
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
