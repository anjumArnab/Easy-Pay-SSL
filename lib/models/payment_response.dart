class PaymentResponse {
  final String status;
  final String? gatewayUrl;
  final String? transactionId;
  final String? sessionKey;
  final String? message;
  final dynamic details;

  PaymentResponse({
    required this.status,
    this.gatewayUrl,
    this.transactionId,
    this.sessionKey,
    this.message,
    this.details,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      status: json['status'] ?? 'error',
      gatewayUrl: json['gatewayUrl'],
      transactionId: json['transactionId'],
      sessionKey: json['sessionKey'],
      message: json['message'],
      details: json['details'],
    );
  }

  bool get isSuccess => status == 'success';
}
