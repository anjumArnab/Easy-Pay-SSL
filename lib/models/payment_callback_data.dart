enum PaymentResult { success, failed, cancelled, error, pending }

class PaymentCallbackData {
  final PaymentResult result;
  final String? transactionId;
  final String? amount;
  final String? reason;

  PaymentCallbackData({
    required this.result,
    this.transactionId,
    this.amount,
    this.reason,
  });

  factory PaymentCallbackData.fromUri(Uri uri) {
    final status = uri.queryParameters['status'];
    final transactionId = uri.queryParameters['tran_id'];
    final amount = uri.queryParameters['amount'];
    final reason = uri.queryParameters['reason'];

    PaymentResult result;
    switch (status) {
      case 'success':
        result = PaymentResult.success;
        break;
      case 'failed':
        result = PaymentResult.failed;
        break;
      case 'cancelled':
        result = PaymentResult.cancelled;
        break;
      case 'error':
        result = PaymentResult.error;
        break;
      default:
        result = PaymentResult.pending;
    }

    return PaymentCallbackData(
      result: result,
      transactionId: transactionId,
      amount: amount,
      reason: reason,
    );
  }
}
