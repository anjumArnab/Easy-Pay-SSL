class PaymentRequest {
  final double amount;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String? productName;

  PaymentRequest({
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.productName,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'productName': productName ?? 'Product',
    };
  }
}
