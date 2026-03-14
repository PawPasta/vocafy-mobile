import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../network/api_error_utils.dart';
import '../network/api_endpoints.dart';
import '../models/api_response.dart';
import '../models/payment_check_result.dart';
import '../models/payment_subscribe_result.dart';
import '../models/page_response.dart';
import '../models/premium_package.dart';
import '../models/subscription_info.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._();
  static PremiumService get instance => _instance;

  PremiumService._();

  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  Future<List<PremiumPackage>> listPremiumPackages({
    int page = 0,
    int size = 10,
  }) async {
    _lastErrorMessage = null;
    try {
      final response = await api.get(
        Api.premiumPackages,
        params: {'page': page, 'size': size},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return const <PremiumPackage>[];

      final parsed = ApiResponse<PageResponse<PremiumPackage>>.fromJson(data, (
        json,
      ) {
        if (json is! Map<String, dynamic>) {
          return const PageResponse<PremiumPackage>(
            content: <PremiumPackage>[],
            page: 0,
            size: 0,
            totalElements: 0,
            totalPages: 0,
            isFirst: true,
            isLast: true,
          );
        }

        return PageResponse<PremiumPackage>.fromJson(
          json,
          (item) => PremiumPackage.fromJson(item as Map<String, dynamic>),
        );
      });

      return parsed.result?.content ?? const <PremiumPackage>[];
    } catch (e) {
      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) {
        print('❌ listPremiumPackages error: $e');
      }
      return const <PremiumPackage>[];
    }
  }

  Future<PremiumPackage?> getPremiumPackageById(int id) async {
    _lastErrorMessage = null;
    try {
      final response = await api.get('${Api.premiumPackages}/$id');
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['result'] is Map<String, dynamic>) {
        return PremiumPackage.fromJson(data['result'] as Map<String, dynamic>);
      }
    } catch (e) {
      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) {
        print('❌ getPremiumPackageById error: $e');
      }
    }
    return null;
  }

  Future<PaymentSubscribeResult?> subscribePremiumPackage(int packageId) async {
    _lastErrorMessage = null;
    try {
      final response = await api.post('${Api.paymentsSubscribe}/$packageId');
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      final parsed = ApiResponse<PaymentSubscribeResult>.fromJson(
        data,
        (json) => PaymentSubscribeResult.fromJson(json as Map<String, dynamic>),
      );
      return parsed.result;
    } catch (e) {
      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) {
        print('❌ subscribePremiumPackage error: $e');
      }
      return null;
    }
  }

  Future<PaymentCheckResult?> checkPaymentTransaction() async {
    _lastErrorMessage = null;
    try {
      final response = await api.get(Api.paymentsCheckTransaction);
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final parsed = ApiResponse<PaymentCheckResult>.fromJson(
        data,
        (json) => PaymentCheckResult.fromJson(json as Map<String, dynamic>),
      );
      return parsed.result;
    } catch (e) {
      // Fallback for backends that expose this endpoint as POST.
      if (e is DioException && e.response?.statusCode == 405) {
        try {
          final response = await api.post(Api.paymentsCheckTransaction);
          final data = response.data;
          if (data is! Map<String, dynamic>) return null;
          final parsed = ApiResponse<PaymentCheckResult>.fromJson(
            data,
            (json) => PaymentCheckResult.fromJson(json as Map<String, dynamic>),
          );
          return parsed.result;
        } catch (inner) {
          _lastErrorMessage = preferredUserErrorMessage(
            inner,
            suppressFirebaseOrProvider: false,
          );
          if (kDebugMode) {
            print('❌ checkPaymentTransaction fallback error: $inner');
          }
          return null;
        }
      }

      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) {
        print('❌ checkPaymentTransaction error: $e');
      }
      return null;
    }
  }

  Future<SubscriptionInfo> getMySubscription() async {
    _lastErrorMessage = null;
    try {
      final response = await api.get(Api.subscriptionsMe);
      final data = response.data;
      if (data is! Map<String, dynamic>) return SubscriptionInfo.free;

      final parsed = ApiResponse<SubscriptionInfo>.fromJson(
        data,
        (json) => json is Map<String, dynamic>
            ? SubscriptionInfo.fromJson(json)
            : SubscriptionInfo.free,
      );

      return parsed.result ?? SubscriptionInfo.free;
    } catch (e) {
      _lastErrorMessage = preferredUserErrorMessage(
        e,
        suppressFirebaseOrProvider: false,
      );
      if (kDebugMode) {
        print('❌ getMySubscription error: $e');
      }
      return SubscriptionInfo.free;
    }
  }
}

final premiumService = PremiumService.instance;


