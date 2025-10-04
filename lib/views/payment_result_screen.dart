import 'package:flutter/material.dart';
import '../models/payment_callback_data.dart';
import '../widgets/app_button.dart';

class PaymentResultScreen extends StatelessWidget {
  final PaymentCallbackData callbackData;

  const PaymentResultScreen({super.key, required this.callbackData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Result'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(),
              const SizedBox(height: 32),
              Text(
                _getTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _getMessage(),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildDetails(),
              const SizedBox(height: 48),

              AppButton(
                label: 'Done',
                loadingLabel: 'Processing...',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                backgroundColor: _getButtonColor(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (callbackData.result) {
      case PaymentResult.success:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case PaymentResult.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case PaymentResult.cancelled:
        icon = Icons.cancel;
        color = Colors.orange;
        break;
      case PaymentResult.error:
        icon = Icons.warning;
        color = Colors.red;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Icon(icon, size: 100, color: color);
  }

  String _getTitle() {
    switch (callbackData.result) {
      case PaymentResult.success:
        return 'Payment Successful!';
      case PaymentResult.failed:
        return 'Payment Failed';
      case PaymentResult.cancelled:
        return 'Payment Cancelled';
      case PaymentResult.error:
        return 'An Error Occurred';
      default:
        return 'Payment Status Unknown';
    }
  }

  String _getMessage() {
    switch (callbackData.result) {
      case PaymentResult.success:
        return 'Your payment has been processed successfully.';
      case PaymentResult.failed:
        return callbackData.reason ?? 'The payment could not be completed.';
      case PaymentResult.cancelled:
        return 'You have cancelled the payment process.';
      case PaymentResult.error:
        return callbackData.reason ?? 'Something went wrong during payment.';
      default:
        return 'Unable to determine payment status.';
    }
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (callbackData.transactionId != null) ...[
            _buildDetailRow('Transaction ID', callbackData.transactionId!),
            const SizedBox(height: 8),
          ],
          if (callbackData.amount != null) ...[
            _buildDetailRow('Amount', '৳${callbackData.amount}'),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getButtonColor() {
    switch (callbackData.result) {
      case PaymentResult.success:
        return Colors.green;
      case PaymentResult.failed:
      case PaymentResult.error:
        return Colors.red;
      case PaymentResult.cancelled:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
