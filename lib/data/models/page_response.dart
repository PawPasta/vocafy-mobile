class PageResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool isFirst;
  final bool isLast;

  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isFirst,
    required this.isLast,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final rawContent = json['content'];
    final items = <T>[];
    if (rawContent is List) {
      for (final item in rawContent) {
        items.add(fromJsonT(item));
      }
    }

    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    bool asBool(Object? v) => v == true;

    return PageResponse<T>(
      content: items,
      page: asInt(json['page']),
      size: asInt(json['size']),
      totalElements: asInt(json['total_elements'] ?? json['totalElements']),
      totalPages: asInt(json['total_pages'] ?? json['totalPages']),
      isFirst: asBool(json['is_first'] ?? json['isFirst']),
      isLast: asBool(json['is_last'] ?? json['isLast']),
    );
  }
}
