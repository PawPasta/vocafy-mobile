import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/api_response.dart';
import '../models/page_response.dart';
import '../models/syllabus.dart';

class SyllabusService {
  static final SyllabusService _instance = SyllabusService._();
  static SyllabusService get instance => _instance;

  SyllabusService._();

  Future<List<Syllabus>> listSyllabi({int page = 0, int size = 5}) async {
    try {
      final response = await api.get(Api.syllabus, params: {
        'page': page,
        'size': size,
      });

      final data = response.data;
      if (data is! Map<String, dynamic>) return const <Syllabus>[];

      final parsed = ApiResponse<PageResponse<Syllabus>>.fromJson(
        data,
        (json) {
          if (json is! Map<String, dynamic>) {
            return const PageResponse<Syllabus>(
              content: <Syllabus>[],
              page: 0,
              size: 0,
              totalElements: 0,
              totalPages: 0,
              isFirst: true,
              isLast: true,
            );
          }
          return PageResponse<Syllabus>.fromJson(
            json,
            (item) => Syllabus.fromJson(item as Map<String, dynamic>),
          );
        },
      );

      return parsed.result?.content ?? const <Syllabus>[];
    } catch (e) {
      if (kDebugMode) {
        print('❌ listSyllabi error: $e');
      }
      return const <Syllabus>[];
    }
  }

  Future<Map<String, dynamic>?> getSyllabusById(int id) async {
    try {
      final response = await api.get('${Api.syllabus}/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['result'] is Map<String, dynamic>) {
        return data['result'] as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print('❌ getSyllabusById error: $e');
    }
    return null;
  }
}

final syllabusService = SyllabusService.instance;
