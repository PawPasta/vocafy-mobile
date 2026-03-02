class PaymentCheckResult {
  final bool isRegistrationSuccessful;
  final String paymentStatus;
  final String subscriptionPlan;
  final String subscriptionEndAt;
  final String latestTransactionStatus;
  final int latestTransactionAmount;

  const PaymentCheckResult({
    required this.isRegistrationSuccessful,
    required this.paymentStatus,
    required this.subscriptionPlan,
    required this.subscriptionEndAt,
    required this.latestTransactionStatus,
    required this.latestTransactionAmount,
  });

  bool get isVipPlan => subscriptionPlan.toUpperCase() == 'VIP';

  factory PaymentCheckResult.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return PaymentCheckResult(
      isRegistrationSuccessful: json['is_registration_successful'] == true,
      paymentStatus: (json['payment_status'] ?? '').toString(),
      subscriptionPlan: (json['subscription_plan'] ?? '').toString(),
      subscriptionEndAt: (json['subscription_end_at'] ?? '').toString(),
      latestTransactionStatus: (json['latest_transaction_status'] ?? '')
          .toString(),
      latestTransactionAmount: asInt(json['latest_transaction_amount']),
    );
  }
}
