import '../models/transaction.dart';

class TransactionStatus {
  final String status;
  final Transaction? transaction;
  final String? message;

  TransactionStatus({required this.status, this.transaction, this.message});

  factory TransactionStatus.fromJson(Map<String, dynamic> json) {
    return TransactionStatus(
      status: json['status'] ?? 'error',
      transaction:
          json['transaction'] != null
              ? Transaction.fromJson(json['transaction'])
              : null,
      message: json['message'],
    );
  }
}
