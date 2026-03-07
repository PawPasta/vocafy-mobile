class PaymentSubscribeResult {
  final String url;
  final int amount;
  final String ref1;

  const PaymentSubscribeResult({
    required this.url,
    required this.amount,
    required this.ref1,
  });

  factory PaymentSubscribeResult.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return PaymentSubscribeResult(
      url: (json['url'] ?? '').toString(),
      amount: asInt(json['amount']),
      ref1: (json['ref1'] ?? '').toString(),
    );
  }
}
