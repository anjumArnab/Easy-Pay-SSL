class Transaction {
  final String transactionId;
  final double amount;
  final String status;
  final String customerName;
  final String customerEmail;
  final String createdAt;
  final String? completedAt;

  Transaction({
    required this.transactionId,
    required this.amount,
    required this.status,
    required this.customerName,
    required this.customerEmail,
    required this.createdAt,
    this.completedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transactionId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'unknown',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      createdAt: json['createdAt'] ?? '',
      completedAt: json['completedAt'],
    );
  }
}
