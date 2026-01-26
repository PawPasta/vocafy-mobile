import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/api_response.dart';
import '../models/category.dart';
import '../models/page_response.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._();
  static CategoryService get instance => _instance;

  CategoryService._();

  Future<List<AppCategory>> listCategories({int page = 0, int size = 10, String? name}) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (name != null && name.trim().isNotEmpty) {
        params['name'] = name.trim();
      }

      final response = await api.get(Api.categories, params: params);

      final data = response.data;
      if (data is! Map<String, dynamic>) return const <AppCategory>[];

      final parsed = ApiResponse<PageResponse<AppCategory>>.fromJson(
        data,
        (json) {
          if (json is! Map<String, dynamic>) {
            return const PageResponse<AppCategory>(
              content: <AppCategory>[],
              page: 0,
              size: 0,
              totalElements: 0,
              totalPages: 0,
              isFirst: true,
              isLast: true,
            );
          }

          return PageResponse<AppCategory>.fromJson(
            json,
            (item) => AppCategory.fromJson(item as Map<String, dynamic>),
          );
        },
      );

      return parsed.result?.content ?? const <AppCategory>[];
    } catch (e) {
      if (kDebugMode) {
        print('❌ listCategories error: $e');
      }
      return const <AppCategory>[];
    }
  }
}

final categoryService = CategoryService.instance;
