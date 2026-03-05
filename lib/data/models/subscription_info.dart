class SubscriptionInfo {
  final String plan;
  final String? startAt;
  final String? endAt;
  final String updatedAt;

  const SubscriptionInfo({
    required this.plan,
    required this.startAt,
    required this.endAt,
    required this.updatedAt,
  });

  static const SubscriptionInfo free = SubscriptionInfo(
    plan: 'FREE',
    startAt: null,
    endAt: null,
    updatedAt: '',
  );

  bool get isVip => plan.toUpperCase() == 'VIP';

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    String? asNullableString(Object? v) {
      final value = v?.toString().trim() ?? '';
      return value.isEmpty ? null : value;
    }

    return SubscriptionInfo(
      plan: (json['plan'] ?? 'FREE').toString().trim().toUpperCase(),
      startAt: asNullableString(json['start_at']),
      endAt: asNullableString(json['end_at']),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }
}
